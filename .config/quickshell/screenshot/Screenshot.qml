import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs
import qs.services

Scope {
    id: root

    property list<string> sessions: []
    property int sessionCount: 0
    readonly property bool busy: sessions.length > 0
    property color color: "#ff5555"

    property list<var> thumbs: []
    readonly property int maxThumbs: 6
    property string shotStamp: ""
    property int shotSeq: 0

    readonly property string outDir: Quickshell.env("HOME") + "/media/screenshot"
    readonly property string recDir: Quickshell.env("HOME") + "/media/screencapture"
    readonly property bool recording: recorder.running
    property string recFile: ""
    property var recScreen: null
    property rect recRegion: Qt.rect(0, 0, 0, 0)
    property int recSeconds: 0

    function start(mode: string) {
        const top = topSession();
        if (top !== null && top.phase === "prepare") return;
        mkdir.exec(["mkdir", "-p", monthDir(), recDir]);
        sessions = sessions.concat([`${mode}:${sessionCount}`]);
        sessionCount++;
    }

    function finish(id: string) { sessions = sessions.filter(s => s !== id) }

    function topSession() {
        const id = sessions.length > 0 ? sessions[sessions.length - 1] : "";
        const list = sessionVariants.instances;
        for (let i = 0; i < list.length; i++) if (list[i].modelData === id) return list[i];
        return null;
    }

    function handleKey(key: int, modifiers: int, text: string): bool {
        const s = topSession();
        return s !== null && s.handleKey(key, modifiers, text);
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

    function pad(n: int): string { return String(n).padStart(2, "0") }

    function monthDir(): string {
        const d = new Date();
        return `${outDir}/${d.getFullYear()}-${pad(d.getMonth() + 1)}`;
    }

    function newFilePath(): string {
        const d = new Date();
        const stamp = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}_${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
        shotSeq = stamp === shotStamp ? shotSeq + 1 : 1;
        shotStamp = stamp;
        return `${monthDir()}/${stamp}${shotSeq > 1 ? "-" + shotSeq : ""}.png`;
    }

    function save(result, screenName: string) {
        const path = newFilePath();
        if (!result.saveToFile(path)) {
            console.error("screenshot: failed to save", path);
            return;
        }
        clip.exec(["sh", "-c", `wl-copy --type image/png < "$1"`, "sh", path]);
        thumbs = thumbs.concat([{ file: path, screen: screenName }]).slice(-maxThumbs);
    }

    IpcHandler {
        target: "screenshot"
        function region(): void { root.start("shot") }
        function delayed(seconds: int): void { delay.interval = seconds * 1000; delay.restart() }
        function record(): void { root.toggleRecording() }
        function cancel(): void {
            const s = root.topSession();
            if (s !== null) s.cancel();
        }
        function select(x: real, y: real, w: real, h: real): void {
            const mon = Hyprland.focusedMonitor;
            const screen = Quickshell.screens.find(s => mon !== null && s.name === mon.name) ?? Quickshell.screens[0];
            if (!root.busy) root.start("shot");
            const s = root.topSession();
            if (s === null) return;
            if (s.phase === "prepare") s.pending = { screen, rect: Qt.rect(x, y, w, h) };
            else s.select(screen, Qt.rect(x, y, w, h));
        }
        function save(): void {
            const s = root.topSession();
            if (s !== null) s.saveRequested();
        }
        function mark(json: string): void {
            const s = root.topSession();
            if (s !== null) s.push(JSON.parse(json));
        }
    }

    Timer { id: delay; onTriggered: root.start("shot") }
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
        id: sessionVariants
        model: root.sessions
        Session { shot: root }
    }

    function dismiss(file: string) { thumbs = thumbs.filter(t => t.file !== file) }

    Variants {
        model: Quickshell.screens
        ThumbnailStack { controller: root }
    }
}
