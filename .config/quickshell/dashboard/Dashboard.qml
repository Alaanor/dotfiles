import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services

Scope {
    id: root

    property bool open: false
    property var screen: Quickshell.screens[0]
    property real reveal: open ? 1 : 0
    Behavior on reveal { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    function toggle() {
        if (open) {
            open = false;
            return;
        }
        const mon = Hyprland.focusedMonitor;
        screen = Quickshell.screens.find(s => mon !== null && s.name === mon.name) ?? Quickshell.screens[0];
        open = true;
    }

    IpcHandler {
        target: "dashboard"
        function toggle(): void { root.toggle() }
        function open(): void { if (!root.open) root.toggle() }
        function close(): void { root.open = false }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
        enabled: root.open
    }

    PanelWindow {
        id: win
        screen: root.screen
        visible: root.reveal > 0
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-dashboard"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        anchors { left: true; right: true; top: true; bottom: true }

        Rectangle {
            anchors.fill: parent
            color: "#0a0810"
            opacity: 0.45 * root.reveal

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.open = false
        }

        Rectangle {
            id: frame
            anchors.centerIn: parent
            width: 940 + 4
            height: term.height + 4
            radius: 7
            opacity: root.reveal
            scale: 0.97 + 0.03 * root.reveal
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.alpha(Theme.accentA, 0.93) }
                GradientStop { position: 1; color: Qt.alpha(Theme.accentB, 0.93) }
            }

            MouseArea { anchors.fill: parent }

            Rectangle {
                id: term
                x: 2
                y: 2
                width: 940
                height: content.height + 20 + 18
                radius: 5
                color: Qt.alpha(Theme.bg, 0.97)

                Column {
                    id: content
                    x: 28
                    y: 20
                    width: parent.width - 56
                    spacing: 11

                    PromptLine { cmd: "date" }

                    Row {
                        leftPadding: 20
                        spacing: 18

                        Text {
                            text: Qt.formatTime(clock.date, "HH:mm:ss")
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 40
                            font.weight: Font.Bold
                        }

                        Text {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 6
                            text: Qt.formatDate(clock.date, "dddd yyyy.MM.dd")
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 16
                        }
                    }

                    PromptLine { cmd: "ticker"; args: "--vs chf" }

                    Text {
                        leftPadding: 20
                        font.family: Theme.font
                        font.pixelSize: 16
                        color: Theme.fg
                        textFormat: Text.RichText
                        text: `<font color="${Theme.orange}">btc</font> ${Ticker.rate("BTC")}<font color="${Theme.dim}">  ·  </font><font color="${Theme.cyan}">eth</font> ${Ticker.rate("ETH")}<font color="${Theme.dim}">  ·  </font><font color="${Theme.magenta}">icp</font> ${Ticker.rate("ICP")}`
                    }

                    Row {
                        width: parent.width
                        spacing: 44

                        Column {
                            width: 420
                            spacing: 11

                            PromptLine { cmd: "np"; args: "--cover" }

                            NowPlaying {
                                x: 20
                                width: parent.width - 20
                            }
                        }

                        Column {
                            width: parent.width - 420 - 44
                            spacing: 11

                            PromptLine { cmd: "btop"; args: "--mini" }

                            Column {
                                x: 20
                                width: parent.width - 20
                                spacing: 9

                                Item {
                                    width: parent.width
                                    height: cpuLabel.height

                                    Text {
                                        id: cpuLabel
                                        text: "cpu"
                                        color: Theme.dim
                                        font.family: Theme.font
                                        font.pixelSize: 14
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        text: `${Math.round(SysStats.cpu)}%`
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: 14
                                        font.weight: Font.Bold
                                    }
                                }

                                CpuGraph {}

                                StatBar { name: "ram"; value: SysStats.ram; color: Theme.cyan }
                                StatBar { name: "disk"; value: SysStats.disk; color: Theme.magenta }
                                StatBar {
                                    name: Audio.muted ? "vol [muted]" : "vol"
                                    value: Audio.volume * 100
                                    valueText: Audio.muted ? "—" : `${Math.round(Audio.volume * 100)}%`
                                    color: Theme.yellow
                                    disabled: Audio.muted
                                    interactive: true
                                    onChanged: v => Audio.setVolume(v / 100)
                                    onNameClicked: Audio.toggleMute()
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 44
                        topPadding: 16

                        Column {
                            width: 420
                            spacing: 11

                            PromptLine { cmd: "hyprctl"; args: "workspaces" }

                            Row {
                                leftPadding: 20
                                spacing: 30
                                WsGroup { name: "dp-1"; ids: [1, 4, 7] }
                                WsGroup { name: "dp-3"; ids: [2, 5, 8] }
                                WsGroup { name: "hdmi"; ids: [3, 6, 9] }
                            }
                        }

                        Column {
                            width: parent.width - 420 - 44
                            spacing: 11

                            PromptLine { cmd: "rsync"; args: "--status" }

                            Item {
                                x: 20
                                width: parent.width - 20
                                height: vaultLabel.height

                                Text {
                                    id: vaultLabel
                                    textFormat: Text.RichText
                                    text: `<font color="${VaultSync.tint}">●</font> vault`
                                    color: Theme.dim
                                    font.family: Theme.font
                                    font.pixelSize: 14
                                }

                                Text {
                                    anchors.right: parent.right
                                    textFormat: Text.RichText
                                    text: `<font color="${Theme.dim}">${VaultSync.summary}  ·  ${VaultSync.filesText}</font>  <b>${VaultSync.sizeText}</b>`
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: 14
                                }
                            }
                        }
                    }
                }
            }
        }

        MultiEffect {
            source: frame
            anchors.fill: frame
            z: -1
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.65 * root.reveal
            shadowBlur: 1.0
            shadowVerticalOffset: 28
            opacity: root.reveal
        }
    }
}
