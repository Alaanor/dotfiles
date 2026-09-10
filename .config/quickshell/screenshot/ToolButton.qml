import QtQuick
import qs

Item {
    id: root
    required property string glyph
    property string tip: ""
    property bool active: false
    property color tint: Theme.fg
    signal clicked()

    width: 38
    height: 38

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: root.active ? Theme.accentA : area.containsMouse ? Qt.alpha(Theme.fg, 0.08) : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        color: root.active ? Theme.bg : root.tint
        font.family: Theme.font
        font.pixelSize: 19
    }

    Rectangle {
        visible: area.containsMouse && root.tip !== ""
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 10
        width: tipText.implicitWidth + 16
        height: tipText.implicitHeight + 8
        radius: 6
        color: Theme.bg1
        border.color: Qt.alpha(Theme.fg, 0.12)
        border.width: 1
        z: 10

        Text {
            id: tipText
            anchors.centerIn: parent
            text: root.tip
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 12
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
