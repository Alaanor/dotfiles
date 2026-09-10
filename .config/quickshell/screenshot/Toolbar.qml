import QtQuick
import qs

Rectangle {
    id: root
    required property var controller

    width: inner.width + 4
    height: inner.height + 4
    radius: 14
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: Qt.alpha(Theme.accentA, 0.9) }
        GradientStop { position: 1; color: Qt.alpha(Theme.accentB, 0.9) }
    }

    MouseArea { anchors.fill: parent; hoverEnabled: true }

    component Hint: Row {
        required property string keycap
        required property string label
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(24, capText.implicitWidth + 12)
            height: 22
            radius: 5
            color: Qt.alpha(Theme.fg, 0.06)
            border.width: 1
            border.color: Qt.alpha(Theme.fg, 0.18)

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 1
                height: 2
                radius: 1
                color: Qt.alpha(Theme.fg, 0.14)
            }

            Text {
                id: capText
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                text: parent.parent.keycap
                color: Qt.alpha(Theme.fg, 0.85)
                font.family: Theme.font
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.label
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 12
        }
    }

    Rectangle {
        id: inner
        x: 2
        y: 2
        width: row.implicitWidth + 20
        height: 54
        radius: 12
        color: Qt.alpha(Theme.bg, 0.96)

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: root.controller.tools
                ToolButton {
                    required property var modelData
                    glyph: modelData.glyph
                    tip: `${modelData.label}  ·  ${modelData.key}`
                    active: root.controller.tool === modelData.id
                    onClicked: root.controller.tool = modelData.id
                }
            }

            Item { width: 10; height: 1 }
            Rectangle { width: 1; height: 24; color: Qt.alpha(Theme.fg, 0.12); anchors.verticalCenter: parent.verticalCenter }
            Item { width: 10; height: 1 }

            Repeater {
                model: root.controller.palette
                Item {
                    required property color modelData
                    readonly property bool active: root.controller.color === modelData
                    width: 30
                    height: 38

                    Rectangle {
                        anchors.centerIn: parent
                        width: active ? 22 : 16
                        height: width
                        radius: width / 2
                        color: parent.modelData
                        border.width: active ? 3 : 0
                        border.color: Theme.bg
                        Behavior on width { NumberAnimation { duration: 100 } }

                        Rectangle {
                            visible: parent.parent.active
                            anchors.fill: parent
                            anchors.margins: -3
                            radius: width / 2
                            color: "transparent"
                            border.width: 2
                            border.color: parent.color
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.controller.color = parent.modelData
                    }
                }
            }

            Item { width: 10; height: 1 }
            Rectangle { width: 1; height: 24; color: Qt.alpha(Theme.fg, 0.12); anchors.verticalCenter: parent.verticalCenter }
            Item { width: 12; height: 1 }

            Hint { keycap: "↵"; label: "save" }
            Item { width: 14; height: 1 }
            Hint { keycap: "esc"; label: "cancel" }
            Item { width: 4; height: 1 }
        }
    }
}
