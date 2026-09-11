import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs

PanelWindow {
    id: win

    required property var modelData
    required property var controller

    readonly property bool isActive: controller.activeScreen !== null && controller.activeScreen.name === modelData.name
    readonly property bool annotating: controller.phase === "annotate" && isActive
    readonly property bool selecting: controller.phase === "select" || (annotating && controller.tool === "crop")
    readonly property rect sel: isActive ? controller.selection : Qt.rect(0, 0, 0, 0)
    readonly property bool hasSel: sel.width > 0 && sel.height > 0

    property var draft: null
    property point dragStart: Qt.point(0, 0)
    property bool dragging: false
    property rect dragRect: Qt.rect(0, 0, 0, 0)
    property rect hoverRect: Qt.rect(0, 0, 0, 0)

    readonly property list<var> handles: [[0, 0], [0.5, 0], [1, 0], [1, 0.5], [1, 1], [0.5, 1], [0, 1], [0, 0.5]]

    screen: modelData
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-screenshot"
    WlrLayershell.keyboardFocus: controller.top && (controller.phase !== "annotate" || isActive) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
    color: "transparent"
    anchors { left: true; right: true; top: true; bottom: true }

    function norm(a: point, b: point): rect {
        return Qt.rect(Math.min(a.x, b.x), Math.min(a.y, b.y), Math.abs(a.x - b.x), Math.abs(a.y - b.y));
    }

    function windowAt(px: real, py: real): rect {
        const gx = px + modelData.x;
        const gy = py + modelData.y;
        let best = Qt.rect(0, 0, 0, 0);
        for (const t of Hyprland.toplevels.values) {
            const o = t.lastIpcObject;
            if (!o || !o.at || !o.size || o.hidden) continue;
            if (!t.workspace || !t.workspace.active) continue;
            if (!t.monitor || t.monitor.name !== modelData.name) continue;
            const x = o.at[0], y = o.at[1], w = o.size[0], h = o.size[1];
            if (gx < x || gx >= x + w || gy < y || gy >= y + h) continue;
            if (best.width === 0 || w * h < best.width * best.height)
                best = Qt.rect(x - modelData.x, y - modelData.y, w, h);
        }
        return best;
    }

    function capture() {
        if (!hasSel) return;
        textEdit.commit();
        cropSource.scheduleUpdate();
        cropSource.grabToImage(result => controller.deliver(result));
    }

    Connections {
        target: win.controller
        function onSaveRequested() { if (win.isActive) win.capture() }
    }

    Item {
        id: stage
        anchors.fill: parent

        ScreencopyView {
            id: view
            anchors.fill: parent
            captureSource: win.modelData
            paintCursor: false
        }

        Repeater {
            model: win.isActive ? win.controller.items.filter(i => i.type === "blur") : []

            Item {
                required property var modelData
                x: modelData.x
                y: modelData.y
                width: modelData.w
                height: modelData.h

                ShaderEffectSource {
                    anchors.fill: parent
                    sourceItem: view
                    sourceRect: Qt.rect(parent.x, parent.y, parent.width, parent.height)
                    textureSize: Qt.size(Math.max(1, Math.round(parent.width / 14)), Math.max(1, Math.round(parent.height / 14)))
                    smooth: false
                    mipmap: false
                }
            }
        }

        Canvas {
            id: marks
            anchors.fill: parent

            Connections {
                target: win.controller
                function onItemsChanged() { marks.requestPaint() }
            }
            Connections {
                target: win
                function onDraftChanged() { marks.requestPaint() }
            }

            function drawItem(ctx, it) {
                ctx.strokeStyle = it.color;
                ctx.fillStyle = it.color;
                ctx.lineWidth = 3;
                ctx.lineJoin = "round";
                ctx.lineCap = "round";
                if (it.type === "pen") {
                    if (it.points.length < 2) return;
                    ctx.beginPath();
                    ctx.moveTo(it.points[0].x, it.points[0].y);
                    for (let i = 1; i < it.points.length; i++) ctx.lineTo(it.points[i].x, it.points[i].y);
                    ctx.stroke();
                } else if (it.type === "rect") {
                    ctx.strokeRect(it.x, it.y, it.w, it.h);
                } else if (it.type === "box") {
                    ctx.fillStyle = "#000000";
                    ctx.fillRect(it.x, it.y, it.w, it.h);
                } else if (it.type === "arrow") {
                    const dx = it.x2 - it.x1, dy = it.y2 - it.y1;
                    const len = Math.hypot(dx, dy);
                    if (len < 1) return;
                    const ux = dx / len, uy = dy / len;
                    const head = Math.min(18, len / 2);
                    ctx.beginPath();
                    ctx.moveTo(it.x1, it.y1);
                    ctx.lineTo(it.x2 - ux * head * 0.6, it.y2 - uy * head * 0.6);
                    ctx.stroke();
                    ctx.beginPath();
                    ctx.moveTo(it.x2, it.y2);
                    ctx.lineTo(it.x2 - ux * head - uy * head * 0.5, it.y2 - uy * head + ux * head * 0.5);
                    ctx.lineTo(it.x2 - ux * head + uy * head * 0.5, it.y2 - uy * head - ux * head * 0.5);
                    ctx.closePath();
                    ctx.fill();
                } else if (it.type === "text") {
                    ctx.font = `bold 22px "${Theme.font}"`;
                    ctx.textBaseline = "top";
                    ctx.fillText(it.text, it.x, it.y);
                }
            }

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                if (!win.isActive) return;
                for (const it of win.controller.items) if (it.type !== "blur") drawItem(ctx, it);
                if (win.draft !== null) {
                    if (win.draft.type === "blur") {
                        ctx.fillStyle = "#50ffffff";
                        ctx.fillRect(win.draft.x, win.draft.y, win.draft.w, win.draft.h);
                    } else drawItem(ctx, win.draft);
                }
            }
        }
    }

    ShaderEffectSource {
        id: cropSource
        x: 0
        y: 0
        z: -1
        width: Math.max(1, win.sel.width)
        height: Math.max(1, win.sel.height)
        sourceItem: stage
        sourceRect: win.sel
        live: false
    }

    Item {
        id: shade
        anchors.fill: parent
        visible: view.hasContent
        readonly property rect r: win.dragging && win.selecting ? win.dragRect : win.hasSel ? win.sel : win.hoverRect
        readonly property color c: "#7a06070d"

        Rectangle { x: 0; y: 0; width: parent.width; height: shade.r.y; color: shade.c }
        Rectangle { x: 0; y: shade.r.y + shade.r.height; width: parent.width; height: parent.height - y; color: shade.c }
        Rectangle { x: 0; y: shade.r.y; width: shade.r.x; height: shade.r.height; color: shade.c }
        Rectangle { x: shade.r.x + shade.r.width; y: shade.r.y; width: parent.width - x; height: shade.r.height; color: shade.c }

        Rectangle {
            id: outline
            x: shade.r.x - 2
            y: shade.r.y - 2
            width: shade.r.width + 4
            height: shade.r.height + 4
            color: "transparent"
            radius: 3
            border.width: 2
            border.color: win.hasSel || win.dragging ? Theme.accentA : Theme.accentB
            visible: shade.r.width > 0

            Repeater {
                model: win.hasSel ? win.handles : []
                Rectangle {
                    required property var modelData
                    width: 10
                    height: 10
                    radius: 5
                    color: Theme.accentA
                    border.width: 2
                    border.color: Theme.bg
                    x: modelData[0] * outline.width - 5
                    y: modelData[1] * outline.height - 5
                }
            }
        }

        Rectangle {
            visible: shade.r.width > 0 && (win.dragging || win.hasSel)
            x: Math.max(4, Math.min(shade.r.x, win.width - width - 4))
            y: shade.r.y > 34 && !toolbar.above ? shade.r.y - height - 10 : shade.r.y + 8
            width: sizeText.implicitWidth + 16
            height: sizeText.implicitHeight + 8
            radius: 6
            color: Qt.alpha(Theme.bg, 0.92)
            border.width: 1
            border.color: Qt.alpha(Theme.accentA, 0.6)

            Text {
                id: sizeText
                anchors.centerIn: parent
                text: `${Math.round(shade.r.width)} × ${Math.round(shade.r.height)}`
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 12
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: view.hasContent
        cursorShape: win.selecting ? Qt.CrossCursor : win.annotating && win.controller.tool === "text" ? Qt.IBeamCursor : Qt.CrossCursor

        onPositionChanged: e => {
            const p = Qt.point(e.x, e.y);
            if (win.selecting && !win.dragging && !win.hasSel) win.hoverRect = win.windowAt(e.x, e.y);
            if (!win.dragging) return;
            if (win.selecting) {
                win.dragRect = win.controller.snap(win.modelData, win.norm(win.dragStart, p));
                return;
            }
            const d = win.draft;
            if (d === null) return;
            const c = win.controller;
            if (d.type === "pen") {
                win.draft = Object.assign({}, d, { points: d.points.concat([p]) });
            } else if (d.type === "rect" || d.type === "blur" || d.type === "box") {
                const r = win.norm(win.dragStart, p);
                win.draft = Object.assign({}, d, { x: r.x, y: r.y, w: r.width, h: r.height });
            } else if (d.type === "arrow") {
                win.draft = Object.assign({}, d, { x2: p.x, y2: p.y });
            }
        }

        onPressed: e => {
            if (e.button !== Qt.LeftButton) return;
            keys.forceActiveFocus();
            textEdit.commit();
            const p = Qt.point(e.x, e.y);
            const c = win.controller;
            if (win.selecting) {
                if (c.phase === "select" && c.activeScreen !== null && !win.isActive) return;
                win.dragStart = p;
                win.dragRect = Qt.rect(p.x, p.y, 0, 0);
                win.dragging = true;
                return;
            }
            if (!win.annotating) return;
            const color = String(c.color);
            if (c.tool === "text") {
                textEdit.begin(p);
                return;
            }
            win.dragStart = p;
            win.dragging = true;
            if (c.tool === "pen") win.draft = { type: "pen", color, points: [p] };
            else if (c.tool === "rect") win.draft = { type: "rect", color, x: p.x, y: p.y, w: 0, h: 0 };
            else if (c.tool === "blur") win.draft = { type: "blur", x: p.x, y: p.y, w: 0, h: 0 };
            else if (c.tool === "box") win.draft = { type: "box", x: p.x, y: p.y, w: 0, h: 0 };
            else if (c.tool === "arrow") win.draft = { type: "arrow", color, x1: p.x, y1: p.y, x2: p.x, y2: p.y };
        }

        onReleased: e => {
            if (!win.dragging) return;
            win.dragging = false;
            const c = win.controller;
            if (win.selecting) {
                let r = win.dragRect;
                if (r.width < 4 || r.height < 4) r = win.windowAt(e.x, e.y);
                if (r.width < 1) return;
                win.hoverRect = Qt.rect(0, 0, 0, 0);
                c.select(win.modelData, r);
                if (c.tool === "crop") c.tool = "pen";
                return;
            }
            const d = win.draft;
            win.draft = null;
            if (d === null) return;
            const tooSmall = (d.type === "rect" || d.type === "blur" || d.type === "box") && (d.w < 2 || d.h < 2);
            if (!tooSmall) c.push(d);
        }
    }

    Repeater {
        model: win.annotating ? win.handles : []

        MouseArea {
            required property var modelData
            readonly property real ax: modelData[0]
            readonly property real ay: modelData[1]
            readonly property int corner: 24
            readonly property int edge: 12
            property rect origin
            property point from

            x: ax === 0.5 ? win.sel.x + corner / 2 : win.sel.x + ax * win.sel.width - (ay === 0.5 ? edge : corner) / 2
            y: ay === 0.5 ? win.sel.y + corner / 2 : win.sel.y + ay * win.sel.height - (ax === 0.5 ? edge : corner) / 2
            width: ax === 0.5 ? Math.max(0, win.sel.width - corner) : ay === 0.5 ? edge : corner
            height: ay === 0.5 ? Math.max(0, win.sel.height - corner) : ax === 0.5 ? edge : corner
            hoverEnabled: true
            preventStealing: true
            cursorShape: ax === 0.5 ? Qt.SizeVerCursor : ay === 0.5 ? Qt.SizeHorCursor : ax === ay ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor

            onPressed: e => {
                textEdit.commit();
                keys.forceActiveFocus();
                origin = win.sel;
                from = mapToItem(null, e.x, e.y);
            }

            onPositionChanged: e => {
                if (!pressed) return;
                const p = mapToItem(null, e.x, e.y);
                const dx = p.x - from.x, dy = p.y - from.y;
                let x1 = origin.x, y1 = origin.y, x2 = origin.x + origin.width, y2 = origin.y + origin.height;
                if (ax === 0) x1 += dx; else if (ax === 1) x2 += dx;
                if (ay === 0) y1 += dy; else if (ay === 1) y2 += dy;
                win.controller.resize(win.norm(Qt.point(x1, y1), Qt.point(x2, y2)));
            }
        }
    }

    TextInput {
        id: textEdit
        visible: false
        color: win.controller.color
        font.family: Theme.font
        font.pixelSize: 22
        font.bold: true
        selectByMouse: true

        function begin(p: point) {
            x = p.x;
            y = p.y;
            text = "";
            visible = true;
            forceActiveFocus();
        }

        function commit() {
            if (!visible) return;
            const t = text;
            visible = false;
            keys.forceActiveFocus();
            if (t.trim() !== "") win.controller.push({ type: "text", color: String(win.controller.color), x, y, text: t });
        }

        Keys.onEscapePressed: { text = ""; commit() }
        onAccepted: commit()

        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            z: -1
            color: "transparent"
            border.color: Qt.alpha(Theme.fg, 0.4)
            border.width: 1
        }
    }

    Rectangle {
        visible: win.controller.phase === "select" && !win.dragging && win.controller.activeScreen === null
        anchors.horizontalCenter: parent.horizontalCenter
        y: 24
        width: hint.implicitWidth + 28
        height: hint.implicitHeight + 14
        radius: height / 2
        color: Qt.alpha(Theme.bg, 0.92)
        border.width: 1
        border.color: win.controller.mode === "record" ? Qt.alpha("#ff5555", 0.7) : Qt.alpha(Theme.accentA, 0.5)

        Text {
            id: hint
            anchors.centerIn: parent
            text: win.controller.mode === "record" ? "󰑊  drag a region or click a window to record" : "drag a region or click a window"
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 13
        }
    }

    Toolbar {
        id: toolbar
        visible: win.annotating
        controller: win.controller
        x: Math.max(8, Math.min(win.sel.x + win.sel.width / 2 - width / 2, win.width - width - 8))
        readonly property bool above: win.annotating && win.sel.y + win.sel.height + 16 + height >= win.height
        y: above ? Math.max(8, win.sel.y - height - 16) : win.sel.y + win.sel.height + 16
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: e => e.accepted = win.controller.shot.handleKey(e.key, e.modifiers, e.text)
    }
}
