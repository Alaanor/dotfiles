import QtQuick
import qs

Column {
    id: root
    required property string name
    required property real value
    required property color color
    property bool interactive: false
    property bool disabled: false
    property string valueText: `${Math.round(value)}%`
    signal changed(real value)
    signal nameClicked()

    width: parent.width
    spacing: 5

    Item {
        width: parent.width
        height: nameLabel.height

        Text {
            id: nameLabel
            text: root.name
            color: nameArea.containsMouse ? Theme.fg : Theme.dim
            font.family: Theme.font
            font.pixelSize: 14

            MouseArea {
                id: nameArea
                anchors.fill: parent
                enabled: root.interactive
                hoverEnabled: root.interactive
                cursorShape: Qt.PointingHandCursor
                onClicked: root.nameClicked()
            }
        }

        Text {
            anchors.right: parent.right
            text: root.valueText
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 14
            font.weight: Font.Bold
        }
    }

    Rectangle {
        id: trough
        width: parent.width
        height: 10
        radius: 3
        color: Theme.trough

        Rectangle {
            width: trough.width * Math.max(0, Math.min(1, root.value / 100))
            height: parent.height
            radius: 3
            color: root.disabled ? Theme.dim : root.color
            Behavior on width { NumberAnimation { duration: 80 } }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            enabled: root.interactive
            cursorShape: Qt.PointingHandCursor
            function apply(x) { root.changed(Math.max(0, Math.min(100, 100 * (x - 6) / trough.width))) }
            onPressed: e => apply(e.x)
            onPositionChanged: e => { if (pressed) apply(e.x) }
            onWheel: e => root.changed(Math.max(0, Math.min(100, root.value + (e.angleDelta.y > 0 ? 5 : -5))))
        }
    }
}
