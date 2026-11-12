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

    readonly property bool busy: actionProc.running || pwProc.running

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

    // Changes the hotspot password (restarting the hotspot if it's on).
    // Emits passwordResult(ok, error) when done.
    function setPassword(newPassword: string): void {
        if (busy)
            return;
        pwExitCode = -1;
        pwStderr = null;
        pwProc.command = [script, "set-password", newPassword];
        pwProc.running = true;
    }

    signal passwordResult(bool ok, string error)

    readonly property bool changingPassword: pwProc.running

    property int pwExitCode: -1
    property var pwStderr: null

    // exited and stderr-finished can arrive in either order; finish on the second.
    function finishPassword(): void {
        if (pwExitCode < 0 || pwStderr === null)
            return;
        const ok = pwExitCode === 0;
        passwordResult(ok, ok ? "" : pwStderr);
        pwExitCode = -1;
        pwStderr = null;
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
        id: pwProc

        onExited: exitCode => {
            root.pwExitCode = exitCode;
            root.finishPassword();
        }
        stderr: StdioCollector {
            onStreamFinished: {
                root.pwStderr = text.trim();
                root.finishPassword();
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
