import QtQuick
import qs

Item {
    id: root

    required property string cmd
    property string placeholder: ""
    property string info: ""
    readonly property alias text: field.text
    default property alias trailing: trail.data

    signal keyPressed(var event)

    implicitHeight: 30

    function reset() {
        field.text = "";
        field.forceActiveFocus();
    }

    function killWord() {
        const before = field.text.slice(0, field.cursorPosition).replace(/\S+\s*$/, "");
        const after = field.text.slice(field.cursorPosition);
        field.text = before + after;
        field.cursorPosition = before.length;
    }

    Text {
        id: prefix
        anchors.verticalCenter: parent.verticalCenter
        font.family: Theme.font
        font.pixelSize: 17
        textFormat: Text.RichText
        text: `<font color="${Theme.green}">❯</font> <font color="${Theme.purple}">${root.cmd}</font>`
    }

    TextInput {
        id: field
        anchors.left: prefix.right
        anchors.leftMargin: 11
        anchors.right: trail.left
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: 17
        selectionColor: Qt.alpha(Theme.cyan, 0.35)
        selectedTextColor: Theme.fg
        selectByMouse: true
        clip: true
        focus: true

        cursorDelegate: Rectangle {
            id: cursor
            width: 9
            height: field.cursorRectangle.height
            color: Theme.green
            visible: field.activeFocus

            Connections {
                target: field
                function onCursorPositionChanged() {
                    cursor.opacity = 1;
                    blink.restart();
                }
            }

            SequentialAnimation on opacity {
                id: blink
                running: field.activeFocus
                loops: Animation.Infinite
                PauseAnimation { duration: 520 }
                NumberAnimation { to: 0; duration: 90 }
                PauseAnimation { duration: 400 }
                NumberAnimation { to: 1; duration: 90 }
            }
        }

        Keys.onPressed: event => {
            if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U) {
                field.text = field.text.slice(field.cursorPosition);
                field.cursorPosition = 0;
                event.accepted = true;
            } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_W) {
                root.killWord();
                event.accepted = true;
            } else {
                root.keyPressed(event);
            }
        }

        Text {
            x: 15
            anchors.verticalCenter: parent.verticalCenter
            visible: field.text === ""
            text: root.placeholder
            color: Theme.dim
            font: field.font
        }
    }

    Row {
        id: trail
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.info !== ""
            text: root.info
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 13
        }
    }
}
