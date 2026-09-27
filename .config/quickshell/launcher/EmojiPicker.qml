import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs
import "emoji.js" as Emoji

Scope {
    id: root

    readonly property int cols: 12
    readonly property int rows: 7
    readonly property int cell: 46
    readonly property string emojiFont: "Noto Color Emoji"
    readonly property var icons: ["😀", "👋", "🐻", "🍔", "✈️", "⚽", "💡", "🔣", "🏁"]
    readonly property var toneHands: ["✋", "✋🏻", "✋🏼", "✋🏽", "✋🏾", "✋🏿"]

    readonly property var entries: load()
    readonly property var byChar: {
        const map = {};
        for (const e of entries) map[e.char] = e;
        return map;
    }
    readonly property var groups: Emoji.groups.map((g, gi) => entries.filter(e => e.group === gi))

    property string query: ""
    property int sel: 0
    property var buffer: []
    property string pending: ""
    readonly property int tone: usage.prefs.tone ?? -1

    readonly property var recent: usage.top(cols * 2).map(c => byChar[c]).filter(e => e !== undefined)
    readonly property var browseView: browse(recent)
    readonly property var cells: query === "" ? browseView.cells : search(query)
    readonly property var tabs: browseView.tabs
    readonly property var current: cells[sel]?.kind === "emoji" ? cells[sel].e : null
    readonly property int scrolledTab: {
        const i = Math.floor((grid.contentY + 8) / cell) * cols;
        return i < cells.length ? cells[i].tab : -1;
    }

    signal shown()

    function close() { overlay.open = false }

    function load(): var {
        const out = [];
        Emoji.groups.forEach((g, gi) => {
            for (const [char, name, keywords, tier, tones] of g.emoji) {
                const words = keywords === "" ? [] : keywords.split(" | ");
                out.push({ char, name, words, tier, tones: tones ?? null, group: gi, order: out.length, text: ` ${name} ${words.join(" ")}` });
            }
        });
        return out;
    }

    function browse(recentList: var): var {
        const cells = [], tabs = [];
        const section = (label, icon, list) => {
            if (list.length === 0) return;
            const tab = tabs.length;
            tabs.push({ icon, label, header: cells.length, first: cells.length + cols });
            cells.push({ kind: "header", label, tab });
            while (cells.length % cols !== 0) cells.push({ kind: "blank", tab });
            for (const e of list) cells.push({ kind: "emoji", e, tab });
            while (cells.length % cols !== 0) cells.push({ kind: "blank", tab });
        };
        section("frequently used", "🕘", recentList);
        groups.forEach((list, gi) => section(Emoji.groups[gi].name, icons[gi], list));
        return { cells, tabs };
    }

    function scoreWord(e: var, w: string): int {
        if (e.name === w) return 130;
        if (e.name.startsWith(w)) return 110;
        if (e.words.includes(w)) return 105;
        if (e.name.includes(" " + w)) return 80;
        if (e.text.includes(" " + w)) return 55;
        if (e.text.includes(w)) return 20;
        return 0;
    }

    function search(raw: string): var {
        const words = raw.trim().toLowerCase().split(/\s+/);
        const hits = [];
        for (const e of entries) {
            let total = 0;
            for (const w of words) {
                const s = scoreWord(e, w);
                if (s === 0) {
                    total = 0;
                    break;
                }
                total += s;
            }
            if (total > 0) hits.push({ e, score: total + 2 * (17 - e.tier) + Math.min(30, 10 * Math.log2(1 + usage.frecency(e.char))) });
        }
        hits.sort((a, b) => b.score - a.score || a.e.order - b.e.order);
        return hits.slice(0, 480).map(h => ({ kind: "emoji", e: h.e, tab: -1 }));
    }

    function glyph(e: var): string {
        return tone >= 0 && e.tones ? e.tones[tone] : e.char;
    }

    function isEmoji(i: int): bool {
        return i >= 0 && i < cells.length && cells[i].kind === "emoji";
    }

    function firstEmoji(): int {
        return query === "" ? tabs[0]?.first ?? 0 : 0;
    }

    function select(i: int) {
        sel = i;
        const above = i - i % cols - cols;
        if (above >= 0 && cells[above].kind === "header") grid.positionViewAtIndex(above, GridView.Contain);
        grid.positionViewAtIndex(i, GridView.Contain);
    }

    function step(dir: int) {
        let i = sel + dir;
        while (i >= 0 && i < cells.length && !isEmoji(i)) i += dir;
        if (isEmoji(i)) select(i);
    }

    function vertical(dir: int) {
        for (let i = sel + dir * cols; i >= 0 && i < cells.length; i += dir * cols) {
            if (isEmoji(i)) return select(i);
            for (let k = i - 1; k >= i - i % cols; k--) if (isEmoji(k)) return select(k);
        }
    }

    function jump(tab: int) {
        if (query !== "") prompt.reset();
        const t = tabs[(tab + tabs.length) % tabs.length];
        sel = t.first;
        grid.positionViewAtIndex(t.header, GridView.Beginning);
    }

    function cycleTone() {
        usage.setPref("tone", tone >= 4 ? -1 : tone + 1);
    }

    function stack(e: var) {
        if (e) buffer = buffer.concat([{ e, glyph: glyph(e) }]);
    }

    function commit(e: var) {
        const picked = e ? buffer.concat([{ e, glyph: glyph(e) }]) : buffer;
        if (picked.length === 0) return;
        for (const p of picked) usage.bump(p.e.char);
        pending = picked.map(p => p.glyph).join("");
        overlay.open = false;
        typer.restart();
    }

    function handleKey(event: var) {
        const ctrl = event.modifiers & Qt.ControlModifier;
        const shift = event.modifiers & Qt.ShiftModifier;
        const searching = query !== "";
        if (event.key === Qt.Key_Escape) overlay.open = false;
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) shift ? stack(current) : commit(current);
        else if (event.key === Qt.Key_Left) step(-1);
        else if (event.key === Qt.Key_Right) step(1);
        else if (event.key === Qt.Key_Up) vertical(-1);
        else if (event.key === Qt.Key_Down) vertical(1);
        else if (event.key === Qt.Key_PageUp) for (let k = 0; k < rows; k++) vertical(-1);
        else if (event.key === Qt.Key_PageDown) for (let k = 0; k < rows; k++) vertical(1);
        else if (event.key === Qt.Key_Tab) searching ? step(1) : jump(cells[sel].tab + 1);
        else if (event.key === Qt.Key_Backtab) searching ? step(-1) : jump(cells[sel].tab - 1);
        else if (ctrl && event.key === Qt.Key_T) cycleTone();
        else if (event.key === Qt.Key_Backspace && prompt.text === "" && buffer.length > 0) buffer = buffer.slice(0, -1);
        else return;
        event.accepted = true;
    }

    Usage {
        id: usage
        name: "emoji"
    }

    Timer {
        id: typer
        interval: 120
        onTriggered: {
            Quickshell.execDetached(["wl-copy", root.pending]);
            Quickshell.execDetached(["wtype", root.pending]);
        }
    }

    IpcHandler {
        target: "emoji"
        function toggle(): void { overlay.toggle() }
        function open(): void { if (!overlay.open) overlay.show() }
        function close(): void { overlay.open = false }
    }

    Overlay {
        id: overlay
        namespace: "qs-emoji"
        frameWidth: root.cols * root.cell + 48
        onShown: {
            prompt.reset();
            root.buffer = [];
            root.sel = root.firstEmoji();
            grid.positionViewAtBeginning();
            root.shown();
        }

        Prompt {
            id: prompt
            width: parent.width
            cmd: "emoji"
            placeholder: "search"
            info: root.query === "" ? `${root.entries.length}` : `${root.cells.length}/${root.entries.length}`
            onTextChanged: {
                root.query = text.trim();
                root.sel = root.firstEmoji();
                grid.positionViewAtBeginning();
            }
            onKeyPressed: event => root.handleKey(event)

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.buffer.length > 0
                text: root.buffer.map(p => p.glyph).join("")
                font.family: root.emojiFont
                font.pixelSize: 18
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
        }

        Item {
            width: parent.width
            height: 34

            Row {
                x: (parent.width - root.cols * root.cell) / 2
                height: parent.height
                spacing: 2

                Repeater {
                    model: root.tabs

                    Item {
                        id: tabItem
                        required property var modelData
                        required property int index
                        readonly property bool active: root.query === "" && root.scrolledTab === index

                        width: 40
                        height: parent.height

                        Text {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: -2
                            text: tabItem.modelData.icon
                            font.family: root.emojiFont
                            font.pixelSize: 19
                            opacity: tabItem.active ? 1 : tabArea.containsMouse ? 0.85 : 0.45
                            layer.enabled: !tabItem.active
                            layer.effect: MultiEffect { saturation: -1 }
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            width: 22
                            height: 2
                            radius: 1
                            visible: tabItem.active
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: Theme.accentA }
                                GradientStop { position: 1; color: Theme.accentB }
                            }
                        }

                        MouseArea {
                            id: tabArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.jump(tabItem.index)
                        }
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: (parent.width - root.cols * root.cell) / 2
                anchors.verticalCenter: parent.verticalCenter
                width: toneRow.implicitWidth + 16
                height: 28
                radius: 6
                color: toneArea.containsMouse ? Theme.hover : "transparent"

                Row {
                    id: toneRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "^t"
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 12
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.toneHands[root.tone + 1]
                        font.family: root.emojiFont
                        font.pixelSize: 17
                    }
                }

                MouseArea {
                    id: toneArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cycleTone()
                }
            }
        }

        GridView {
            id: grid
            x: (parent.width - width) / 2
            width: root.cols * root.cell
            height: root.rows * root.cell
            cellWidth: root.cell
            cellHeight: root.cell
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.cells

            delegate: Item {
                id: slot
                required property var modelData
                required property int index
                readonly property bool isEmoji: modelData.kind === "emoji"
                readonly property bool selected: isEmoji && index === root.sel

                width: root.cell
                height: root.cell

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 7
                    visible: slot.selected
                    color: Qt.alpha(Theme.accentA, 0.12)
                    border.width: 1
                    border.color: Qt.alpha(Theme.accentA, 0.55)
                }

                Text {
                    anchors.centerIn: parent
                    visible: slot.isEmoji
                    text: slot.isEmoji ? root.glyph(slot.modelData.e) : ""
                    font.family: root.emojiFont
                    font.pixelSize: slot.selected ? 31 : 26
                    Behavior on font.pixelSize { NumberAnimation { duration: 90; easing.type: Easing.OutBack } }
                }

                Row {
                    x: 4
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 7
                    spacing: 10
                    visible: slot.modelData.kind === "header"

                    Text {
                        id: headerText
                        textFormat: Text.StyledText
                        text: `<font color="${Theme.green}">#</font> ${slot.modelData.label ?? ""}`
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 12
                    }

                    Rectangle {
                        anchors.verticalCenter: headerText.verticalCenter
                        width: grid.width - headerText.width - 22
                        height: 1
                        color: Theme.border
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: slot.isEmoji
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: root.sel = slot.index
                    onClicked: mouse => mouse.modifiers & Qt.ShiftModifier ? root.stack(slot.modelData.e) : root.commit(slot.modelData.e)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.cells.length === 0
                text: `no emoji matches "${root.query}"`
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 14
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
        }

        Item {
            width: parent.width
            height: 40

            Text {
                id: preview
                x: (parent.width - root.cols * root.cell) / 2 + 4
                anchors.verticalCenter: parent.verticalCenter
                width: 38
                text: root.current ? root.glyph(root.current) : ""
                font.family: root.emojiFont
                font.pixelSize: 30
            }

            Column {
                anchors.left: preview.right
                anchors.leftMargin: 12
                anchors.right: hints.left
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.current?.name ?? ""
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 14
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.current?.words.join(" · ") ?? ""
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 11
                }
            }

            Text {
                id: hints
                anchors.right: parent.right
                anchors.rightMargin: (parent.width - root.cols * root.cell) / 2
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.StyledText
                text: `<font color="${Theme.fg}">⏎</font> insert  <font color="${Theme.fg}">⇧⏎</font> stack  <font color="${Theme.fg}">tab</font> group`
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 12
            }
        }
    }
}
