import QtQuick
import qs

Rectangle {
    id: root
    required property string glyph
    signal clicked()

    implicitWidth: label.implicitWidth + 22
    implicitHeight: label.implicitHeight + 8
    radius: 6
    color: area.containsMouse ? Theme.hover : "transparent"

    Text {
        id: label
        anchors.centerIn: parent
        text: root.glyph
        color: area.containsMouse ? Theme.green : Theme.fg
        font.family: Theme.font
        font.pixelSize: 18
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
