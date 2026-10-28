import QtQuick
import QtQuick.Templates as T
import CClicker

T.Switch {
    id: control
    implicitWidth: 50
    implicitHeight: 30
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    property real knob: checked ? 1 : 0
    Behavior on knob { SpringAnimation { spring: 4.5; damping: 0.36; epsilon: 0.002 } }
    indicator: Item {
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: control.checked ? Theme.legit : Theme.chip
            Behavior on color { ColorAnimation { duration: Theme.base } }
            border.width: control.visualFocus ? 2 : 0
            border.color: Theme.focusRing
        }
        Glass {
            width: (control.pressed ? 32 : 26)
            Behavior on width { SpringAnimation { spring: 5; damping: 0.4; epsilon: 0.05 } }
            height: 26
            radius: 13
            y: 2
            x: 2 + control.knob * (control.width - width - 4)
            elevation: 0.8
            Rectangle { anchors.fill: parent; radius: 13; color: "white"; opacity: 1 - 0.35 * Theme.glass }
        }
    }
    contentItem: Item {}
}
