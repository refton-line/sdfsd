import QtQuick
import QtQuick.Templates as T
import FakeClicker

// kind: "primary" (white pill, the one call to action), "normal" (graphite), "plain" (no fill
// until hovered), "danger" (red). Text buttons are pills, icon-only buttons are circles.
// Hover and press change colour instantly; nothing scales or bounces. `cue` is the click sound;
// buttons whose result has its own sound (start, save, delete) clear it.
T.AbstractButton {
    id: control
    property string cue: "tap"
    property string iconName
    property string kind: "normal"
    property real iconSize: 16
    property bool compact: false
    readonly property bool round: text === ""
    readonly property color fillColor: kind === "primary" ? (pressed ? "#D4D4D4" : hovered ? "#E8E8E8" : Theme.ink)
        : kind === "danger" ? (pressed ? "#A30004" : hovered ? "#E8141A" : Theme.danger)
        : kind === "plain" ? (pressed ? Theme.controlActive : hovered ? Theme.control : "transparent")
        : (pressed ? Theme.controlActive : hovered ? Theme.controlHover : Theme.control)
    readonly property color foreground: kind === "primary" ? Theme.inverse
        : kind === "danger" ? "#FFFFFF"
        : kind === "plain" && !hovered ? Theme.inkSoft : Theme.ink

    implicitHeight: compact ? 32 : 40
    implicitWidth: round ? implicitHeight : content.implicitWidth + (compact ? 24 : 34)
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.name: text
    opacity: enabled ? 1 : 0.32
    onClicked: if (cue !== "") sounds.play(cue)

    background: Rectangle {
        radius: height / 2
        color: control.fillColor
        border.width: control.kind === "normal" ? 1 : 0
        border.color: Theme.hairlineStrong
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: height / 2
            color: "transparent"
            border.width: 2
            border.color: Theme.focusRing
            visible: control.visualFocus
        }
    }
    contentItem: Item {
        Row {
            id: content
            anchors.centerIn: parent
            spacing: 8
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: control.iconName !== ""
                name: control.iconName
                size: control.iconSize
                color: control.foreground
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                visible: control.text !== ""
                text: control.text
                color: control.foreground
                font.pixelSize: control.compact ? 13 : 14
                font.weight: Font.DemiBold
            }
        }
    }
}
