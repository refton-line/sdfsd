import QtQuick
import QtQuick.Templates as T
import LightClicker

// kind: "normal" | "primary" | "danger" | "plain".
// Glass: glass capsules that squash on press. Solid: iOS 14 rounded buttons that dim on press.
T.AbstractButton {
    id: control
    property string iconName
    property string kind: "normal"
    property real iconSize: 18
    property bool compact: false
    readonly property bool round: text === ""
    readonly property bool filled: kind === "primary" || kind === "danger"
    readonly property color fillColor: kind === "danger" ? Theme.danger : Theme.isGlass ? Theme.ink : "#007aff"
    readonly property color foreground: filled ? "#ffffff" : Theme.isGlass ? Theme.ink : (kind === "plain" && round ? Theme.inkSoft : "#007aff")

    implicitHeight: compact ? 34 : 42
    implicitWidth: round ? implicitHeight : content.implicitWidth + (compact ? 26 : 36)
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.name: text
    opacity: !enabled ? 0.35 : !Theme.isGlass && pressed ? 0.55 : 1
    Behavior on opacity { NumberAnimation { duration: Theme.isGlass ? Theme.base : 90 } }
    scale: !Theme.isGlass ? 1 : pressed ? 0.92 : hovered && enabled ? 1.04 : 1
    Behavior on scale { SpringAnimation { spring: 5.5; damping: 0.28; epsilon: 0.001 } }

    background: Item {
        // Glass
        Surface {
            anchors.fill: parent
            visible: Theme.isGlass && !control.filled && control.kind !== "plain"
            radius: height / 2
            elevation: 0
            tintAlpha: control.pressed ? 0.25 : control.hovered ? 0.7 : 0.55
            magnify: control.pressed ? 0.08 : 0
        }
        Fill {
            anchors.fill: parent
            visible: Theme.isGlass && control.filled
            radius: height / 2
            strength: 0.8
            magnify: control.pressed ? 0.08 : 0
            color: control.hovered ? Qt.lighter(control.fillColor, control.kind === "primary" ? 1.5 : 1.08) : control.fillColor
            Behavior on color { ColorAnimation { duration: Theme.base } }
        }
        Rectangle {
            anchors.fill: parent
            visible: Theme.isGlass && control.kind === "plain"
            radius: height / 2
            color: control.pressed ? Qt.rgba(0, 0, 0, 0.08) : control.hovered ? Qt.rgba(1, 1, 1, 0.55) : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
        // Solid
        Rectangle {
            anchors.fill: parent
            visible: !Theme.isGlass && control.kind !== "plain"
            radius: control.round ? height / 2 : 10
            color: control.filled ? control.fillColor : control.hovered ? Theme.fillStrong : Theme.fill
        }
        Rectangle {
            anchors.fill: parent
            visible: !Theme.isGlass && control.kind === "plain"
            radius: control.round ? height / 2 : 8
            color: control.hovered ? Theme.fill : "transparent"
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: control.round || Theme.isGlass ? height / 2 : 12
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
            spacing: 7
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
                font.weight: Theme.isGlass || control.filled ? Font.DemiBold : Font.Medium
            }
        }
    }
}
