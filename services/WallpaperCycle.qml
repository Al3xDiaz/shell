pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Models
import qs.services
import qs.utils

Singleton {
    id: root

    property string folder
    property int intervalMs: 900000
    property bool enabled: false
    property bool shuffle: false
    property bool recursive: false

    property bool loaded: false

    readonly property string effectiveFolder: folder || Paths.wallsdir
    readonly property list<string> paths: images.entries.map(e => e.path)

    // In-memory back/forward history (not persisted): lets "previous" truly go back
    // to what was shown before, even in shuffle mode, instead of just picking again.
    property list<string> history: []
    property int historyIndex: -1
    readonly property int maxHistory: 100

    // Resets the history to the actual current wallpaper if it's out of sync
    // (first call ever, or the wallpaper was changed some other way - Nexus, CLI, etc.)
    function syncHistory(): void {
        if (historyIndex < 0 || history[historyIndex] !== Wallpapers.actualCurrent) {
            history = [Wallpapers.actualCurrent];
            historyIndex = 0;
        }
    }

    function pickNext(): string {
        const list = root.paths;
        const currentIdx = list.indexOf(Wallpapers.actualCurrent);

        if (root.shuffle) {
            if (list.length === 1)
                return list[0];
            let idx;
            do {
                idx = Math.floor(Math.random() * list.length);
            } while (idx === currentIdx);
            return list[idx];
        }

        return list[(currentIdx + 1 + list.length) % list.length];
    }

    function cycle(): void {
        if (root.paths.length === 0)
            return;
        syncHistory();

        if (historyIndex < history.length - 1) {
            // Already went back before - step forward through history instead of
            // picking a new one, like browser forward.
            historyIndex++;
        } else {
            let h = history.concat([pickNext()]);
            if (h.length > maxHistory)
                h = h.slice(h.length - maxHistory);
            history = h;
            historyIndex = history.length - 1;
        }

        Wallpapers.setWallpaper(history[historyIndex]);
        timer.restart();
    }

    function previous(): void {
        if (root.paths.length === 0)
            return;
        syncHistory();

        if (historyIndex > 0) {
            historyIndex--;
            Wallpapers.setWallpaper(history[historyIndex]);
            timer.restart();
        }
        // else: nothing further back, no-op
    }

    function save(): void {
        storage.setText(JSON.stringify({
                    folder: root.folder,
                    intervalMs: root.intervalMs,
                    enabled: root.enabled,
                    shuffle: root.shuffle,
                    recursive: root.recursive
                }));
    }

    onFolderChanged: if (loaded)
        saveTimer.restart()
    onIntervalMsChanged: if (loaded)
        saveTimer.restart()
    onEnabledChanged: if (loaded)
        saveTimer.restart()
    onShuffleChanged: if (loaded)
        saveTimer.restart()
    onRecursiveChanged: if (loaded)
        saveTimer.restart()

    FileSystemModel {
        id: images

        path: root.effectiveFolder
        filter: FileSystemModel.Images
        recursive: root.recursive
        watchChanges: true
    }

    Timer {
        id: timer

        interval: Math.max(root.intervalMs, 60000)
        running: root.enabled && root.paths.length > 0
        repeat: true
        onTriggered: root.cycle()
    }

    Timer {
        id: saveTimer

        interval: 1000
        onTriggered: root.save()
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.state}/wallpaper-cycle.json`

        onLoaded: {
            const data = JSON.parse(text());
            root.folder = data.folder ?? "";
            root.intervalMs = data.intervalMs ?? 900000;
            root.enabled = data.enabled ?? false;
            root.shuffle = data.shuffle ?? false;
            root.recursive = data.recursive ?? false;
            root.loaded = true;
        }
        onLoadFailed: err => {
            root.loaded = true;
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => root.save());
        }
    }
}
