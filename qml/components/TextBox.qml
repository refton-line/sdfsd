import QtQuick
import QtQuick.Templates as T
import CClicker

T.TextField {
    id: field
    property string iconName
    implicitHeight: 40
    implicitWidth: 240
    leftPadding: iconName ? 40 : 16
    rightPadding: 16
    verticalAlignment: TextInput.AlignVCenter
    color: Theme.ink
    font.family: Theme.sans
    font.pixelSize: Theme.body
    selectionColor: Theme.focusRing
    selectedTextColor: "#ffffff"
    placeholderTextColor: Theme.faint
    selectByMouse: true
    background: Item {
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Theme.well
            border.width: field.activeFocus ? 2 : 0
            border.color: Qt.rgba(0, 0.443, 0.89, 0.55)
            Behavior on border.width { NumberAnimation { duration: Theme.fast } }
        }
        Icon {
            visible: field.iconName !== ""
            x: 14; anchors.verticalCenter: parent.verticalCenter
            name: field.iconName; size: 17
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
