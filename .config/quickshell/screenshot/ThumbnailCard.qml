import QtQuick
import Quickshell
import Quickshell.Io
import QtMultimedia
import Quickshell.Widgets
import qs

Item {
    id: win
    required property var controller
    required property string file
    property bool video: false
    readonly property url fileUrl: "file://" + file
    readonly property int previewHeight: 168

    width: 300
    height: card.height

    Process { id: clip }

    function copy() {
        if (video) clip.exec(["wl-copy", "--type", "text/uri-list", fileUrl.toString()]);
        else clip.exec(["sh", "-c", `wl-copy --type image/png < "$1"`, "sh", file]);
        copied.restart();
    }

    Timer { id: copied; interval: 1500 }

    function fmtDuration(ms: int): string {
        const s = Math.round(ms / 1000);
        return `${String(Math.floor(s / 60)).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}`;
    }

    component ActionButton: Rectangle {
        id: btn
        required property string glyph
        signal clicked()

        width: 30
        height: 30
        radius: 15
        color: btnArea.containsMouse ? "#ffffff" : "#cc000000"
        border.width: 1
        border.color: "#66ffffff"
        Behavior on color { ColorAnimation { duration: 100 } }

        Text {
            anchors.centerIn: parent
            text: btn.glyph
            color: btnArea.containsMouse ? "#000000" : "#ffffff"
            font.family: Theme.font
            font.pixelSize: 15
        }

        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    Rectangle {
        id: card
        width: parent.width
        height: preview.height + 16
        radius: 10
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.alpha(Theme.accentA, 0.9) }
            GradientStop { position: 1; color: Qt.alpha(Theme.accentB, 0.9) }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: 8
            color: Qt.alpha(Theme.bg, 0.97)
        }

        ClippingRectangle {
            id: clipRect
            x: 8
            y: 8
            width: parent.width - 16
            height: preview.height
            radius: 5
            color: "transparent"

            Item {
                id: preview
                width: parent.width
                height: win.video ? win.previewHeight : img.height

                Image {
                    id: img
                    visible: !win.video
                    width: parent.width
                    source: win.video ? "" : win.fileUrl
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    height: status === Image.Ready && sourceSize.width > 0 ? Math.min(220, width * sourceSize.height / sourceSize.width) : 120
                }

                Rectangle {
                    visible: win.video
                    anchors.fill: parent
                    color: "#000000"
                }

                VideoOutput {
                    id: vo
                    visible: win.video
                    anchors.fill: parent
                    fillMode: VideoOutput.PreserveAspectFit
                }

                MediaPlayer {
                    id: player
                    source: win.video ? win.fileUrl : ""
                    videoOutput: vo
                    loops: MediaPlayer.Infinite
                    audioOutput: AudioOutput { muted: true }
                    onMediaStatusChanged: if (mediaStatus === MediaPlayer.LoadedMedia) play()
                }

                Text {
                    visible: win.video
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 10
                    text: "󰑊 " + win.fmtDuration(player.duration)
                    color: "#ffffff"
                    font.family: Theme.font
                    font.pixelSize: 12
                    style: Text.Outline
                    styleColor: "#000000"
                }

                Drag.active: drag.active
                Drag.dragType: Drag.Automatic
                Drag.supportedActions: Qt.CopyAction
                Drag.mimeData: { "text/uri-list": win.fileUrl.toString() }
                Drag.imageSource: win.video ? "" : win.fileUrl
                Drag.imageSourceSize: Qt.size(200, 200 * height / Math.max(1, width))

                DragHandler { id: drag; target: null }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    onClicked: Quickshell.execDetached(["xdg-open", win.file])
                    onPressed: e => e.accepted = false
                }
            }
        }

        Row {
            anchors.top: clipRect.top
            anchors.right: clipRect.right
            anchors.margins: 8
            spacing: 6

            ActionButton { glyph: copied.running ? "󰄬" : "󰆏"; onClicked: win.copy() }
            ActionButton { glyph: "󰅖"; onClicked: win.controller.dismiss(win.file) }
        }
    }
}
