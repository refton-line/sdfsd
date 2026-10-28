import QtQuick
import QtQuick.Templates as T
import CClicker

// Glass: iOS 26 switch whose knob turns into a clear lens while pressed.
// Solid: the classic iOS 14 switch.
T.Switch {
    id: control
    implicitWidth: Theme.isGlass ? 62 : 51
    implicitHeight: Theme.isGlass ? 28 : 31
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    property real knob: checked ? 1 : 0
    Behavior on knob {
        SpringAnimation { spring: Theme.isGlass ? 4.5 : 6; damping: Theme.isGlass ? 0.32 : 0.6; epsilon: 0.002 }
    }
    indicator: Item {
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: control.checked ? Theme.legit : Theme.isGlass ? Qt.rgba(0.47, 0.47, 0.5, 0.2) : "#e9e9eb"
            Behavior on color { ColorAnimation { duration: 220 } }
            border.width: control.visualFocus ? 2 : 0
            border.color: Theme.focusRing
        }
        // Glass knob
        Item {
            visible: Theme.isGlass
            property real w: control.pressed ? 46 : 38
            property real h: control.pressed ? 34 : 24
            Behavior on w { SpringAnimation { spring: 5; damping: 0.36; epsilon: 0.05 } }
            Behavior on h { SpringAnimation { spring: 5; damping: 0.36; epsilon: 0.05 } }
            width: w; height: h
            x: 2 + control.knob * (control.width - 38 - 4) - (w - 38) / 2
            y: (control.height - h) / 2
            Surface {
                anchors.fill: parent
                radius: height / 2
                elevation: 0.6
                tintAlpha: control.pressed ? 0.12 : 0.92
                frost: control.pressed ? 0.15 : 1
                magnify: control.pressed ? 0.1 : 0
                Behavior on tintAlpha { NumberAnimation { duration: 180 } }
            }
        }
        // Solid knob
        Rectangle {
            visible: !Theme.isGlass
            width: 27; height: 27; radius: 13.5
            y: 2
            x: 2 + control.knob * (control.width - 31)
            color: "#ffffff"
            Rectangle { anchors.fill: parent; anchors.topMargin: 2; anchors.bottomMargin: -2; radius: 13.5; color: Qt.rgba(0, 0, 0, 0.1); z: -1 }
            border.width: 0.5
            border.color: Qt.rgba(0, 0, 0, 0.04)
        }
    }
    contentItem: Item {}
}
