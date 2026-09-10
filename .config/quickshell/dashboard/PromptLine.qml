import QtQuick
import qs

Text {
    required property string cmd
    property string args: ""

    font.family: Theme.font
    font.pixelSize: 15
    textFormat: Text.RichText
    text: `<font color="${Theme.green}">❯</font> <font color="${Theme.purple}">${cmd}</font> <font color="${Theme.dim}">${args}</font>`
}
