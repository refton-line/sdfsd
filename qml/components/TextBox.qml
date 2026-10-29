import QtQuick
import QtQuick.Templates as T
import FakeClicker

T.TextField {
    id: field
    property string iconName
    implicitHeight: 40
    implicitWidth: 240
    leftPadding: iconName ? 40 : 14
    rightPadding: 14
    verticalAlignment: TextInput.AlignVCenter
    color: Theme.ink
    font.family: Theme.sans
    font.pixelSize: Theme.body
    renderType: Text.NativeRendering
    selectionColor: Theme.selection
    selectedTextColor: Theme.ink
    placeholderTextColor: Theme.faint
    selectByMouse: true
    background: Rectangle {
        radius: Theme.controlRadius
        color: Theme.raised
        border.width: 1
        border.color: field.activeFocus ? Qt.rgba(1, 1, 1, 0.32) : field.hovered ? Theme.hairlineStrong : Theme.hairline
        Icon {
            visible: field.iconName !== ""
            x: 14; anchors.verticalCenter: parent.verticalCenter
            name: field.iconName; size: 16
            color: Theme.muted
        }
        Label {
            x: field.leftPadding
            anchors.verticalCenter: parent.verticalCenter
            visible: field.text === "" && !field.preeditText
            text: field.placeholderText
            color: field.placeholderTextColor
            font: field.font
        }
    }
}
