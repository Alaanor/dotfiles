import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs

Scope {
    id: root

    required property string namespace
    property int frameWidth: 640
    property bool open: false
    property var screen: Quickshell.screens[0]
    property real reveal: open ? 1 : 0
    default property alias content: body.data

    signal shown()

    Behavior on reveal { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

    function show() {
        const mon = Hyprland.focusedMonitor;
        screen = Quickshell.screens.find(s => mon !== null && s.name === mon.name) ?? Quickshell.screens[0];
        open = true;
        shown();
    }

    function toggle() {
        if (open) open = false;
        else show();
    }

    PanelWindow {
        screen: root.screen
        visible: root.reveal > 0
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: root.namespace
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        anchors { left: true; right: true; top: true; bottom: true }

        Rectangle {
            anchors.fill: parent
            color: "#0a0810"
            opacity: 0.3 * root.reveal

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }
        }

        Rectangle {
            id: frame
            x: Math.round((parent.width - width) / 2)
            y: Math.round(parent.height * 0.22 - 10 * (1 - root.reveal))
            width: root.frameWidth + 4
            height: term.height + 4
            radius: 7
            opacity: root.reveal
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
                width: root.frameWidth
                height: body.implicitHeight + 36
                radius: 5
                color: Qt.alpha(Theme.bg, 0.97)

                Column {
                    id: body
                    x: 20
                    y: 18
                    width: parent.width - 40
                    spacing: 12
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
            shadowVerticalOffset: 24
            opacity: root.reveal
        }
    }
}
