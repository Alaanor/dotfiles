import QtQuick
import Quickshell.Hyprland
import qs

Row {
    id: root
    required property string name
    required property list<int> ids

    spacing: 9

    Text {
        text: root.name
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: 14
    }

    Repeater {
        model: root.ids

        Text {
            required property int modelData
            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === modelData) ?? null
            readonly property bool open: ws !== null
            readonly property bool active: ws?.active ?? false

            text: active || open ? "●" : "○"
            color: active ? Theme.green : open ? Theme.fg : Theme.wsClosed
            font.family: Theme.font
            font.pixelSize: 14

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`workspace ${parent.modelData}`)
            }
        }
    }
}
