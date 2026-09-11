import QtQuick
import Quickshell

Scope {
    id: session

    required property string modelData
    required property var shot

    readonly property string mode: modelData.split(":")[0]
    readonly property bool top: shot.sessions.length > 0 && shot.sessions[shot.sessions.length - 1] === modelData
    property string phase: "prepare"
    property var activeScreen: null
    property rect selection: Qt.rect(0, 0, 0, 0)
    property string tool: "pen"
    property color color: shot.color
    property list<var> items: []
    property var pending: null

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

    signal saveRequested()

    onColorChanged: shot.color = color

    function cancel() { shot.finish(modelData) }
    function undo() { if (items.length > 0) items = items.slice(0, -1) }
    function push(item) { items = items.concat([item]) }

    /** Whole pixels only: a fractional crop origin makes Qt interpolate every pixel of the capture. */
    function snap(screen, r: rect): rect {
        const cx = v => Math.max(0, Math.min(screen.width, Math.round(v)));
        const cy = v => Math.max(0, Math.min(screen.height, Math.round(v)));
        const x1 = cx(r.x), y1 = cy(r.y);
        return Qt.rect(x1, y1, cx(r.x + r.width) - x1, cy(r.y + r.height) - y1);
    }

    function select(screen, r: rect) {
        const s = snap(screen, r);
        if (s.width < 1 || s.height < 1) return;
        activeScreen = screen;
        selection = s;
        if (mode === "record") {
            shot.beginRecording(screen, s);
            shot.finish(modelData);
            return;
        }
        phase = "annotate";
    }

    function resize(r: rect) {
        const s = snap(activeScreen, r);
        if (s.width >= 1 && s.height >= 1) selection = s;
    }

    function deliver(result) {
        shot.save(result, activeScreen.name);
        shot.finish(modelData);
    }

    function handleKey(key: int, modifiers: int, text: string): bool {
        if (key === Qt.Key_Escape) {
            cancel();
            return true;
        }
        if (phase !== "annotate") return false;
        if (key === Qt.Key_Return || key === Qt.Key_Enter) {
            saveRequested();
            return true;
        }
        if (modifiers & Qt.ControlModifier) {
            if (key === Qt.Key_Z) undo();
            else if (key === Qt.Key_C) saveRequested();
            return true;
        }
        const t = tools.find(t => t.key === text.toLowerCase());
        if (t === undefined) return false;
        tool = t.id;
        return true;
    }

    Timer {
        interval: 80
        running: true
        onTriggered: {
            session.phase = "select";
            if (session.pending !== null) session.select(session.pending.screen, session.pending.rect);
        }
    }

    Variants {
        model: session.phase === "select" || session.phase === "annotate" ? Quickshell.screens : []
        FreezeWindow { controller: session }
    }
}
