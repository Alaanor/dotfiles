import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win
    required property var modelData
    required property var controller

    readonly property list<var> thumbs: controller.thumbs.filter(t => t.screen === modelData.name)

    visible: controller.phase === "idle" && thumbs.length > 0
    screen: modelData
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-screenshot-thumb"
    color: "transparent"
    anchors { right: true; bottom: true }
    margins { right: 20; bottom: 20 }
    implicitWidth: 300
    implicitHeight: Math.max(1, column.implicitHeight)

    Column {
        id: column
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        spacing: 10

        Repeater {
            model: win.thumbs
            ThumbnailCard {
                required property var modelData
                controller: win.controller
                file: modelData.file
                video: modelData.video === true
            }
        }
    }
}
