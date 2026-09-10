pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpu: 0
    property real ram: 0
    property real disk: 0
    property list<real> cpuHistory: []
    readonly property int historyLength: 30

    property real _prevIdle: 0
    property real _prevTotal: 0

    function parseStat(text: string) {
        const f = text.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        const idle = f[3] + f[4];
        const total = f.reduce((a, b) => a + b, 0);
        const dTotal = total - _prevTotal;
        const dIdle = idle - _prevIdle;
        _prevTotal = total;
        _prevIdle = idle;
        if (dTotal <= 0) return;
        cpu = 100 * (1 - dIdle / dTotal);
        const h = cpuHistory.slice(-(historyLength - 1));
        h.push(cpu);
        cpuHistory = h;
    }

    function parseMem(text: string) {
        const get = k => Number((text.match(new RegExp(k + ":\\s+(\\d+)")) ?? [0, 0])[1]);
        const total = get("MemTotal");
        if (total > 0) ram = 100 * (total - get("MemAvailable")) / total;
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: root.parseStat(text())
    }

    FileView {
        id: mem
        path: "/proc/meminfo"
        onLoaded: root.parseMem(text())
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            stat.reload();
            mem.reload();
        }
    }

    Process {
        id: df
        command: ["df", "--output=pcent", "/"]
        stdout: StdioCollector {
            onStreamFinished: root.disk = parseInt(text.trim().split("\n").pop()) || 0
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: df.running = true
    }
}
