pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wraps the `hotspot` script (~/.local/bin/hotspot), which manages a
// NetworkManager shared-mode access point. See that script for config.
Singleton {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.local/bin/hotspot"

    property bool enabled: false
    property string ssid: ""
    property string password: ""
    property string lastError: ""

    readonly property bool busy: actionProc.running || cfgProc.running

    // Emitted after every status check, so UI switches can resync with the
    // real state (e.g. when enabling failed and `enabled` didn't change).
    signal refreshed

    function toggle(): void {
        set(!enabled);
    }

    function set(on: bool): void {
        if (busy)
            return;
        lastError = "";
        actionProc.command = [script, on ? "on" : "off"];
        actionProc.running = true;
    }

    // Changes the hotspot name and/or password in one go (restarting the
    // hotspot once if it's on). An empty argument keeps the current value.
    // Emits settingsResult(ok, error) when done.
    function saveSettings(newSsid: string, newPassword: string): void {
        if (busy)
            return;
        cfgExitCode = -1;
        cfgStderr = null;
        cfgProc.command = [script, "configure", newSsid, newPassword];
        cfgProc.running = true;
    }

    signal settingsResult(bool ok, string error)

    readonly property bool saving: cfgProc.running

    property int cfgExitCode: -1
    property var cfgStderr: null

    // exited and stderr-finished can arrive in either order; finish on the second.
    function finishSettings(): void {
        if (cfgExitCode < 0 || cfgStderr === null)
            return;
        const ok = cfgExitCode === 0;
        settingsResult(ok, ok ? "" : cfgStderr);
        cfgExitCode = -1;
        cfgStderr = null;
        refresh();
    }

    function refresh(): void {
        statusProc.running = true;
        infoProc.running = true;
    }

    Component.onCompleted: refresh()

    // Re-check whenever NetworkManager reports any change.
    Process {
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: refreshTimer.restart()
        }
    }

    Timer {
        id: refreshTimer

        interval: 400
        onTriggered: root.refresh()
    }

    Process {
        id: statusProc

        command: [root.script, "status"]
        onExited: exitCode => {
            root.enabled = exitCode === 0;
            root.refreshed();
        }
    }

    // Used for the SSID/password shown in the UI.
    Process {
        id: infoProc

        command: [root.script, "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.split("\n")) {
                    if (line.startsWith("SSID:"))
                        root.ssid = line.slice(5).trim();
                    else if (line.startsWith("Clave:"))
                        root.password = line.slice(6).trim();
                }
            }
        }
    }

    Process {
        id: cfgProc

        onExited: exitCode => {
            root.cfgExitCode = exitCode;
            root.finishSettings();
        }
        stderr: StdioCollector {
            onStreamFinished: {
                root.cfgStderr = text.trim();
                root.finishSettings();
            }
        }
    }

    Process {
        id: actionProc

        onExited: root.refresh()
        stderr: StdioCollector {
            onStreamFinished: root.lastError = text.trim()
        }
    }
}
