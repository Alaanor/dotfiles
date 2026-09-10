import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs
import qs.services

Scope {
    id: root

    property string phase: "idle"
    property string mode: "shot"
    property var activeScreen: null
    property rect selection: Qt.rect(0, 0, 0, 0)
    property string tool: "pen"
    property color color: "#ff5555"
    property list<var> items: []

    property list<var> thumbs: []
    readonly property int maxThumbs: 6

    readonly property string outDir: Quickshell.env("HOME") + "/media/screenshot"
    readonly property string recDir: Quickshell.env("HOME") + "/media/screencapture"
    readonly property bool recording: recorder.running
    property string recFile: ""
    property var recScreen: null
    property rect recRegion: Qt.rect(0, 0, 0, 0)
    property int recSeconds: 0
    readonly property list<color> palette: ["#ff5555", "#f1fa8c", "#ffffff"]
    readonly property list<var> tools: [
        { id: "pen", glyph: "󰏫", label: "pen", key: "p" },
        { id: "rect", glyph: "󰹟", label: "rect", key: "r" },
        { id: "arrow", glyph: "󰁔", label: "arrow", key: "a" },
        { id: "text", glyph: "󰊄", label: "text", key: "t" },
        { id: "blur", glyph: "󰂵", label: "pixelate", key: "b" },
        { id: "box", glyph: "󰄮", label: "black box", key: "k" },
        { id: "crop", glyph: "󰆞", label: "reselect", key: "x" }
    ]

    function start(newMode: string) {
        if (phase !== "idle") return;
        mode = newMode;
        items = [];
        selection = Qt.rect(0, 0, 0, 0);
        activeScreen = null;
        tool = "pen";
        mkdir.exec(["mkdir", "-p", monthDir(), recDir]);
        phase = "prepare";
        freezeDelay.restart();
    }

    function cancel() { phase = "idle" }
    function undo() { if (items.length > 0) items = items.slice(0, -1) }
    function push(item) { items = items.concat([item]) }

    function select(screen, r: rect) {
        activeScreen = screen;
        selection = r;
        if (mode === "record") {
            phase = "idle";
            beginRecording(screen, r);
            return;
        }
        phase = "annotate";
    }

    function beginRecording(screen, r: rect) {
        if (recorder.running) return;
        const d = new Date();
        recFile = `${recDir}/recording-${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}-${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}.mp4`;
        recScreen = screen;
        recRegion = r;
        recSeconds = 0;
        const geometry = `${Math.round(r.x + screen.x)},${Math.round(r.y + screen.y)} ${Math.round(r.width)}x${Math.round(r.height)}`;
        const sink = Audio.sink ? Audio.sink.name : "";
        const audio = sink === "" ? ["--audio"] : ["--audio", "--audio-device", sink + ".monitor"];
        recorder.command = ["wl-screenrec", "-g", geometry, "-b", "3 MB", ...audio, "-f", recFile];
        recorder.running = true;
    }

    function stopRecording() {
        if (recorder.running) recorder.signal(2);
    }

    function toggleRecording() {
        if (recorder.running) stopRecording();
        else start("record");
    }

    property var pendingSelect: null
    onPhaseChanged: if (phase === "select") applyPendingSelect()

    function applyPendingSelect() {
        if (pendingSelect === null) return;
        const p = pendingSelect;
        pendingSelect = null;
        select(p.screen, p.rect);
    }

    function pad(n: int): string { return String(n).padStart(2, "0") }

    function monthDir(): string {
        const d = new Date();
        return `${outDir}/${d.getFullYear()}-${pad(d.getMonth() + 1)}`;
    }

    function newFilePath(): string {
        const d = new Date();
        const name = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}_${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}.png`;
        return `${monthDir()}/${name}`;
    }

    function deliver(result) {
        const path = newFilePath();
        if (!result.saveToFile(path)) {
            console.error("screenshot: failed to save", path);
            phase = "idle";
            return;
        }
        clip.exec(["sh", "-c", `wl-copy --type image/png < "$1"`, "sh", path]);
        const screenName = activeScreen.name;
        phase = "idle";
        thumbs = thumbs.concat([{ file: path, screen: screenName }]).slice(-maxThumbs);
    }

    IpcHandler {
        target: "screenshot"
        function region(): void { root.start("shot") }
        function delayed(seconds: int): void { delay.interval = seconds * 1000; delay.restart() }
        function record(): void { root.toggleRecording() }
        function cancel(): void { root.cancel() }
        function select(x: int, y: int, w: int, h: int): void {
            const mon = Hyprland.focusedMonitor;
            const screen = Quickshell.screens.find(s => mon !== null && s.name === mon.name) ?? Quickshell.screens[0];
            if (root.phase === "idle") root.start("shot");
            pendingSelect = { screen, rect: Qt.rect(x, y, w, h) };
            if (root.phase !== "prepare") root.applyPendingSelect();
        }
        function save(): void { root.saveRequested() }
        function mark(json: string): void { root.push(JSON.parse(json)) }
    }
    signal saveRequested()

    Timer { id: delay; onTriggered: root.start("shot") }
    Timer { id: freezeDelay; interval: 80; onTriggered: if (root.phase === "prepare") root.phase = "select" }
    Process { id: mkdir }
    Process { id: clip }

    Process {
        id: recorder
        stderr: StdioCollector { onStreamFinished: if (text.trim() !== "") console.log("wl-screenrec:", text.trim().split("\n").pop()) }
        onExited: (code, status) => {
            const file = root.recFile;
            const screenName = root.recScreen ? root.recScreen.name : Quickshell.screens[0].name;
            root.recFile = "";
            if (code !== 0 && root.recSeconds < 1) {
                console.error("recording failed with code", code);
                return;
            }
            root.thumbs = root.thumbs.concat([{ file, screen: screenName, video: true }]).slice(-root.maxThumbs);
        }
    }

    Timer {
        interval: 1000
        running: root.recording
        repeat: true
        onTriggered: root.recSeconds++
    }

    RecordingPill { controller: root }

    Variants {
        model: root.phase === "select" || root.phase === "annotate" ? Quickshell.screens : []
        FreezeWindow { controller: root }
    }

    function dismiss(file: string) { thumbs = thumbs.filter(t => t.file !== file) }

    Variants {
        model: Quickshell.screens
        ThumbnailStack { controller: root }
    }
}
