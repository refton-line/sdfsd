import QtQuick
import QtQuick.Templates as T
import CClicker

// kind: "glass" (translucent), "primary" (ink pill), "tinted" (tintColor pill), "plain" (no surface).
T.AbstractButton {
    id: control
    property string iconName
    property string kind: "glass"
    property color tintColor: Theme.ink
    property real iconSize: 18
    property bool compact: false
    property bool round: text === ""
    readonly property bool filled: kind === "primary" || kind === "tinted"
    readonly property color fill: kind === "tinted" ? tintColor : Theme.ink
    readonly property color foreground: filled ? "#ffffff" : Theme.ink

    implicitHeight: compact ? 34 : 44
    implicitWidth: round ? implicitHeight : content.implicitWidth + (compact ? 28 : 40)
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.name: text
    opacity: enabled ? 1 : 0.38
    Behavior on opacity { NumberAnimation { duration: Theme.base } }
    // Liquid press: compress, then spring back past rest.
    scale: pressed ? 0.94 : hovered && enabled ? 1.03 : 1
    Behavior on scale { SpringAnimation { spring: 5.5; damping: 0.3; epsilon: 0.001 } }

    HoverHandler { id: pointer }

    background: Item {
        Glass {
            anchors.fill: parent
            visible: control.kind === "glass"
            radius: height / 2
            elevation: 0.6
            interactive: true
            lit: control.hovered
            lightX: pointer.point.position.x
            lightY: pointer.point.position.y
        }
        Rectangle {
            anchors.fill: parent
            visible: control.filled
            radius: height / 2
            color: control.pressed ? Qt.darker(control.fill, 1.15) : control.hovered ? Qt.lighter(control.fill, control.kind === "primary" ? 1.45 : 1.08) : control.fill
            Behavior on color { ColorAnimation { duration: Theme.base } }
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.18) }
                    GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0) }
                }
            }
        }
        Rectangle {
            anchors.fill: parent
            visible: control.kind === "plain"
            radius: height / 2
            color: control.pressed ? Theme.pressedTint : control.hovered ? Theme.well : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
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
                font.pixelSize: control.compact ? Theme.small + 1 : Theme.body
                font.weight: Font.DemiBold
            }
        }
    }
}
