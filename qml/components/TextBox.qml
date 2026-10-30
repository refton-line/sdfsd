import QtQuick
import QtQuick.Templates as T
import LightClicker

T.TextField {
    id: field
    property string iconName
    implicitHeight: Theme.isGlass ? 42 : 36
    implicitWidth: 240
    leftPadding: iconName ? (Theme.isGlass ? 42 : 32) : 14
    rightPadding: 14
    verticalAlignment: TextInput.AlignVCenter
    color: Theme.ink
    font.family: Theme.sans
    font.pixelSize: Theme.isGlass ? 14 : 15
    selectionColor: Theme.focusRing
    selectedTextColor: "#ffffff"
    placeholderTextColor: Theme.isGlass ? Theme.muted : "#8e8e93"
    selectByMouse: true
    background: Item {
        Surface {
            anchors.fill: parent
            visible: Theme.isGlass
            radius: height / 2
            elevation: 0.4
            tintAlpha: field.activeFocus ? 0.75 : 0.5
        }
        Rectangle {
            anchors.fill: parent
            visible: !Theme.isGlass
            radius: 10
            color: Theme.fill
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: Theme.isGlass ? height / 2 : 12
            color: "transparent"
            border.width: field.activeFocus ? 2 : 0
            border.color: Qt.rgba(0, 0.443, 0.89, 0.5)
        }
        Icon {
            visible: field.iconName !== ""
            x: Theme.isGlass ? 16 : 9; anchors.verticalCenter: parent.verticalCenter
            name: field.iconName; size: Theme.isGlass ? 17 : 16
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
