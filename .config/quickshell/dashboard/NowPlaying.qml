import QtQuick
import Quickshell.Widgets
import qs
import qs.services

Row {
    spacing: 18

    ClippingRectangle {
        width: 170
        height: 170
        radius: 6
        color: "#11141f"
        border.color: Theme.border
        border.width: 1

        Image {
            anchors.fill: parent
            source: Music.cover
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: Music.cover !== "" && status === Image.Ready
        }

        Text {
            anchors.centerIn: parent
            visible: Music.cover === ""
            text: "󰝚"
            font.family: Theme.font
            font.pixelSize: 52
            color: Qt.alpha(Theme.fg, 0.12)
        }
    }

    Column {
        width: parent.width - 170 - 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Text {
            width: parent.width
            text: Music.artist === "" ? "—" : Music.artist
            color: Theme.cyan
            font.family: Theme.font
            font.pixelSize: 14
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
        }

        Text {
            width: parent.width
            text: Music.title
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 18
            font.weight: Font.ExtraBold
            wrapMode: Text.Wrap
        }

        Row {
            topPadding: 8
            spacing: 2
            ControlButton { glyph: "󰒮"; onClicked: Music.previous() }
            ControlButton { glyph: Music.playing ? "󰏤" : "󰐊"; onClicked: Music.toggle() }
            ControlButton { glyph: "󰒭"; onClicked: Music.next() }
        }
    }
}
