pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs

Singleton {
    id: root

    property string status: "unknown"
    property int at: 0
    property int now: 0
    property real bytes: 0
    property int files: 0

    readonly property int age: at === 0 ? -1 : Math.max(0, now - at)
    readonly property bool stale: age < 0 || age > 900

    readonly property string ago: {
        if (age < 0) return "never";
        if (age < 60) return `${age}s ago`;
        if (age < 3600) return `${Math.floor(age / 60)}m ago`;
        if (age < 86400) return `${Math.floor(age / 3600)}h ago`;
        return `${Math.floor(age / 86400)}d ago`;
    }

    readonly property color tint: status === "error" ? Theme.magenta : stale ? Theme.yellow : Theme.green
    readonly property string sizeText: bytes <= 0 ? "—" : `${(bytes / 1048576).toFixed(1)} MB`
    readonly property string filesText: files <= 0 ? "" : `${files} files`

    readonly property string summary: status === "error" ? `failed ${ago}` : `synced ${ago}`

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.cache/vault-sync/status.json"
        onLoaded: {
            try {
                const j = JSON.parse(text());
                root.status = j.state ?? "unknown";
                root.at = j.at ?? 0;
                root.bytes = j.bytes ?? 0;
                root.files = j.files ?? 0;
            } catch (e) {}
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.now = Math.floor(Date.now() / 1000);
            file.reload();
        }
    }
}
