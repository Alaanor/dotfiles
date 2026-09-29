import QtQuick
import Quickshell
import Quickshell.Widgets
import qs

Rectangle {
    id: root

    required property var modelData
    required property int index
    property bool selected: false
    readonly property bool shell: modelData.kind === "shell"
    readonly property bool running: !shell && modelData.running

    signal picked()
    signal hovered()

    width: ListView.view.width
    height: 42
    radius: 5
    color: selected ? Theme.hover : "transparent"

    function escapeHtml(s: string): string {
        return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    function highlight(text: string, positions: var): string {
        const hits = new Set(positions);
        let out = "", open = false;
        for (let i = 0; i < text.length; i++) {
            if (hits.has(i) !== open) {
                open = !open;
                out += open ? `<font color="${Theme.green}"><b>` : "</b></font>";
            }
            out += escapeHtml(text[i]);
        }
        return open ? out + "</b></font>" : out;
    }

    Rectangle {
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: parent.height - 14
        radius: 1.5
        visible: root.selected
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.accentA }
            GradientStop { position: 1; color: Theme.accentB }
        }
    }

    Item {
        id: iconSlot
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 26
        height: 26

        IconImage {
            width: 26
            height: 26
            visible: !root.shell
            asynchronous: true
            source: root.shell ? "" : Quickshell.iconPath(root.modelData.entry.icon, "application-x-executable")
        }

        Text {
            anchors.centerIn: parent
            visible: root.shell
            text: ""
            color: Theme.green
            font.family: Theme.font
            font.pixelSize: 19
        }
    }

    Text {
        id: title
        anchors.left: iconSlot.right
        anchors.leftMargin: 13
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, parent.width * 0.55)
        elide: Text.ElideRight
        textFormat: Text.StyledText
        color: root.selected ? "#ffffff" : Theme.fg
        font.family: Theme.font
        font.pixelSize: 15
        text: root.shell
            ? `<font color="${Theme.dim}">$</font> ${root.escapeHtml(root.modelData.command)}`
            : root.highlight(root.modelData.name, root.modelData.positions)
    }

    Text {
        anchors.left: title.right
        anchors.leftMargin: 12
        anchors.right: hint.left
        anchors.rightMargin: 12
        anchors.baseline: title.baseline
        elide: Text.ElideRight
        text: root.shell ? "run in a shell" : root.modelData.detail
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: 12
    }

    Text {
        id: hint
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.running ? (root.selected ? "new ⏎  switch ⇧⏎" : "●") : root.selected ? "⏎" : !root.shell && root.modelData.entry.runInTerminal ? "tty" : ""
        color: root.running ? Theme.green : Theme.dim
        font.family: Theme.font
        font.pixelSize: 13
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: root.hovered()
        onClicked: root.picked()
    }
}
