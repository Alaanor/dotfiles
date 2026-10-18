import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs

Scope {
    id: root

    property string phase: "idle"
    property string message: ""
    property real level: 0
    property int seconds: 0
    property var screen: Quickshell.screens[0]
    readonly property var focusedMonitor: Hyprland.focusedMonitor
    property Socket sock: null

    function reconnect(): void {
        sock?.destroy();
        sock = sockComponent.createObject(root);
    }

    function send(cmd: string): void {
        if (sock === null || !sock.connected) {
            flash("offline", "dictation daemon offline", 1500);
            return;
        }
        sock.write(cmd + "\n");
        sock.flush();
    }

    function flash(p: string, msg: string, ms: int): void {
        phase = p;
        message = msg;
        hideTimer.interval = ms;
        hideTimer.restart();
    }

    function onLine(line: string): void {
        const sp = line.indexOf(" ");
        const kind = sp < 0 ? line : line.slice(0, sp);
        const arg = sp < 0 ? "" : line.slice(sp + 1);
        if (kind === "level") {
            level = level * 0.4 + parseFloat(arg) * 0.6;
        } else if (kind === "rec") {
            screen = Quickshell.screens.find(s => focusedMonitor !== null && s.name === focusedMonitor.name) ?? Quickshell.screens[0];
            hideTimer.stop();
            seconds = 0;
            level = 0;
            phase = "rec";
        } else if (kind === "busy") {
            phase = "busy";
        } else if (kind === "text") {
            const text = JSON.parse(arg);
            Quickshell.execDetached(["wl-copy", "--", text]);
            Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | wtype -', "sh", text]);
            flash("done", text, 1500);
        } else if (kind === "empty") {
            flash("empty", "nothing heard", 900);
        } else if (kind === "error") {
            flash("error", arg, 2500);
        }
    }

    Component {
        id: sockComponent
        Socket {
            path: `${Quickshell.env("XDG_RUNTIME_DIR")}/dictate.sock`
            connected: true
            parser: SplitParser { onRead: line => root.onLine(line) }
        }
    }

    Component.onCompleted: reconnect()

    Timer {
        interval: 2000
        repeat: true
        running: root.sock === null || !root.sock.connected
        onTriggered: root.reconnect()
    }

    Timer {
        id: hideTimer
        onTriggered: root.phase = "idle"
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.phase === "rec"
        onTriggered: root.seconds++
    }

    IpcHandler {
        target: "dictate"
        function start(): void { root.send("start") }
        function stop(): void { root.send("stop") }
        function cancel(): void { root.send("cancel") }
    }

    PanelWindow {
        id: win
        readonly property bool shown: root.phase !== "idle"

        visible: shown || card.opacity > 0
        screen: root.screen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-dictate"
        color: "transparent"
        mask: Region {}
        anchors.top: true
        margins.top: 16
        implicitWidth: 420
        implicitHeight: 40

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            width: row.implicitWidth + 28
            height: 38
            radius: 19
            color: Qt.alpha(Theme.bg, 0.96)
            border.width: 1
            border.color: root.phase === "rec" ? Qt.alpha("#ff5555", 0.5)
                : root.phase === "done" ? Qt.alpha(Theme.green, 0.45)
                : Qt.alpha(Theme.fg, 0.18)
            opacity: win.shown ? 1 : 0
            scale: win.shown ? 1 : 0.92

            Behavior on opacity { NumberAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 10

                Rectangle {
                    visible: root.phase === "rec"
                    anchors.verticalCenter: parent.verticalCenter
                    width: 10
                    height: 10
                    radius: 5
                    color: "#ff5555"
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: root.phase === "rec"
                        NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
                    }
                }

                Row {
                    visible: root.phase === "rec"
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    Repeater {
                        model: [0.55, 0.8, 1, 0.8, 0.55]
                        Rectangle {
                            required property real modelData
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            radius: 1.5
                            height: 4 + 16 * root.level * modelData
                            color: Theme.fg
                            Behavior on height { NumberAnimation { duration: 70 } }
                        }
                    }
                }

                Text {
                    visible: root.phase === "rec"
                    anchors.verticalCenter: parent.verticalCenter
                    text: `${Math.floor(root.seconds / 60)}:${String(root.seconds % 60).padStart(2, "0")}`
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Row {
                    visible: root.phase === "busy"
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Repeater {
                        model: 3
                        Rectangle {
                            required property int index
                            width: 6
                            height: 6
                            radius: 3
                            color: Theme.cyan
                            opacity: 0.3
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: root.phase === "busy"
                                PauseAnimation { duration: index * 150 }
                                NumberAnimation { to: 1; duration: 250 }
                                NumberAnimation { to: 0.3; duration: 250 }
                                PauseAnimation { duration: (2 - index) * 150 }
                            }
                        }
                    }
                }

                Text {
                    visible: root.phase !== "rec" && root.phase !== "busy"
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.phase === "done" ? "󰄬" : root.phase === "error" || root.phase === "offline" ? "󰅙" : "󰍭"
                    color: root.phase === "done" ? Theme.green : root.phase === "empty" ? Theme.dim : "#ff5555"
                    font.family: Theme.font
                    font.pixelSize: 15
                }

                Text {
                    visible: root.phase !== "rec"
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 300)
                    elide: Text.ElideRight
                    text: root.phase === "busy" ? "transcribing" : root.phase === "done" ? "copied" : root.message
                    color: root.phase === "empty" || root.phase === "busy" ? Theme.dim : Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: root.phase === "done" ? Font.DemiBold : Font.Normal
                }

                Text {
                    visible: root.phase === "done"
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 260)
                    elide: Text.ElideRight
                    text: root.message
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 13
                }
            }
        }
    }
}
