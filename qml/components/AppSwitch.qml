import QtQuick
import QtQuick.Templates as T
import FakeClicker

// Monochrome switch: a white track with a black knob when on, graphite when off. On and off
// click differently; `audible: false` leaves the sound to the owner.
T.Switch {
    id: control
    property bool audible: true
    onToggled: if (audible) sounds.play(checked ? "switchOn" : "switchOff")
    implicitWidth: 44
    implicitHeight: 24
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    indicator: Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: control.checked ? Theme.ink : control.hovered ? Theme.controlHover : Theme.control
        border.width: control.checked ? 0 : 1
        border.color: Theme.hairlineStrong
        Rectangle {
            width: 18; height: 18; radius: 9
            y: 3
            x: control.checked ? parent.width - width - 3 : 3
            Behavior on x { NumberAnimation { duration: Theme.base; easing.type: Easing.OutCubic } }
            color: control.checked ? Theme.inverse : Theme.muted
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: height / 2
            color: "transparent"
            visible: control.visualFocus
            border.width: 2
            border.color: Theme.focusRing
        }
    }
    contentItem: Item {}
}
