import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

PanelWindow {
    id: win
    required property var controller

    readonly property rect region: controller.recRegion
    readonly property var scr: controller.recScreen ?? Quickshell.screens[0]
    readonly property bool overlapsTopRight: region.x + region.width > scr.width - 260 && region.y < 80
    readonly property bool overlapsTopLeft: region.x < 260 && region.y < 80
    readonly property bool overlapsBottomRight: region.x + region.width > scr.width - 260 && region.y + region.height > scr.height - 80

    visible: controller.recording
    screen: scr
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-screenshot-rec"
    color: "transparent"
    anchors {
        top: !overlapsTopRight || !overlapsTopLeft
        bottom: overlapsTopRight && overlapsTopLeft
        right: !overlapsTopRight || (overlapsTopLeft && !overlapsBottomRight)
        left: overlapsTopRight && (!overlapsTopLeft || overlapsBottomRight)
    }
    margins { top: 16; bottom: 16; left: 16; right: 16 }
    implicitWidth: pill.width
    implicitHeight: pill.height

    function fmt(s: int): string {
        const m = Math.floor(s / 60);
        return `${String(m).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}`;
    }

    Rectangle {
        id: pill
        width: row.implicitWidth + 28
        height: 38
        radius: 19
        color: Qt.alpha(Theme.bg, 0.96)
        border.width: 1
        border.color: area.containsMouse ? "#ff5555" : Qt.alpha(Theme.fg, 0.18)

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 10

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 10
                height: 10
                radius: 5
                color: "#ff5555"
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: win.visible
                    NumberAnimation { to: 0.25; duration: 600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: win.fmt(win.controller.recSeconds)
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: area.containsMouse ? "stop" : "󰑊"
                color: area.containsMouse ? "#ff5555" : Theme.dim
                font.family: Theme.font
                font.pixelSize: area.containsMouse ? 12 : 14
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: win.controller.stopRecording()
        }
    }
}
