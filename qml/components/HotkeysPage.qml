import QtQuick
import QtQuick.Templates as T
import CClicker

Item {
    id: page
    property var engine
    property var keyboard

    Row {
        id: cards
        width: parent.width
        spacing: Theme.gutter
        Repeater {
            model: 2
            Glass {
                id: card
                required property int index
                readonly property bool stopAction: index === 1
                readonly property var bindings: stopAction ? page.engine.stopBindings : page.engine.startBindings
                width: (page.width - Theme.gutter) / 2
                height: Math.max(168, 96 + flow.implicitHeight + 24)
                Behavior on height { SpringAnimation { spring: 3.5; damping: 0.32; epsilon: 0.1 } }
                Rectangle {
                    id: badge
                    x: 22; y: 22
                    width: 40; height: 40; radius: 13
                    color: card.stopAction ? Theme.blatant : Theme.legit
                    Icon { anchors.centerIn: parent; name: card.stopAction ? "stop" : "play"; size: 20; color: "#ffffff" }
                }
                Label {
                    anchors.left: badge.right; anchors.leftMargin: 14
                    anchors.verticalCenter: badge.verticalCenter
                    text: I18n.t(card.stopAction ? "keys.stop" : "keys.start")
                    font.pixelSize: 18; font.weight: Font.DemiBold
                }
                GlassButton {
                    objectName: card.stopAction ? "addStopBinding" : "addStartBinding"
                    anchors.right: parent.right; anchors.rightMargin: 18
                    anchors.verticalCenter: badge.verticalCenter
                    width: 38; height: 38
                    iconName: "plus"; iconSize: 18
                    Accessible.name: I18n.t("keys.add")
                    enabled: !page.engine.active && card.bindings.length < 8
                    onClicked: page.keyboard.edit(card.index, card.bindings.length)
                }
                Flow {
                    id: flow
                    x: 22; y: 84
                    width: parent.width - 44
                    spacing: 10
                    move: Transition { SpringAnimation { properties: "x,y"; spring: 4; damping: 0.32 } }
                    add: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.base }
                            NumberAnimation { property: "scale"; from: 0.6; to: 1; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.8 }
                        }
                    }
                    Repeater {
                        model: card.bindings
                        T.AbstractButton {
                            id: keyChip
                            required property int index
                            required property var modelData
                            objectName: index === 0 ? (card.stopAction ? "editStopBinding" : "editStartBinding") : "binding" + card.index + "_" + index
                            height: 46
                            width: chipRow.implicitWidth + 28 + (removable ? 26 : 0)
                            hoverEnabled: true
                            focusPolicy: Qt.StrongFocus
                            enabled: !page.engine.active
                            readonly property bool removable: card.bindings.length > 1
                            Accessible.name: modelData.label
                            onClicked: page.keyboard.edit(card.index, index)
                            scale: pressed ? 0.95 : hovered ? 1.03 : 1
                            Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
                            HoverHandler { id: chipHover }
                            background: Glass {
                                radius: 14
                                elevation: 0.6
                                interactive: true
                                lit: keyChip.hovered
                                lightX: chipHover.point.position.x
                                lightY: chipHover.point.position.y
                                Rectangle {
                                    anchors.fill: parent; anchors.margins: -3
                                    radius: 17; color: "transparent"
                                    border.width: keyChip.visualFocus ? 2 : 0
                                    border.color: Theme.focusRing
                                }
                            }
                            contentItem: Item {
                                Row {
                                    id: chipRow
                                    x: 14; anchors.verticalCenter: parent.verticalCenter
                                    spacing: 6
                                    Repeater {
                                        model: keyChip.modelData.keys
                                        Rectangle {
                                            required property int modelData
                                            height: 28; radius: 8
                                            width: Math.max(28, capText.implicitWidth + 14)
                                            color: Theme.white
                                            border.width: 1; border.color: Theme.hairline
                                            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 2; radius: 1; color: Theme.hairline }
                                            Label {
                                                id: capText
                                                anchors.centerIn: parent
                                                text: page.engine.keyName(parent.modelData)
                                                font.pixelSize: Theme.small + 1; font.weight: Font.DemiBold
                                            }
                                        }
                                    }
                                }
                            }
                            GlassButton {
                                visible: keyChip.removable
                                kind: "plain"
                                anchors.right: parent.right; anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                width: 26; height: 26
                                iconName: "x"; iconSize: 12
                                opacity: keyChip.hovered || hovered ? 1 : 0.45
                                Accessible.name: I18n.t("keys.remove")
                                enabled: !page.engine.active
                                onClicked: page.engine.removeBinding(card.stopAction, keyChip.index)
                            }
                        }
                    }
                }
            }
        }
    }

    Glass {
        id: settingsCard
        y: cards.y + cards.childrenRect.height + Theme.gutter
        width: parent.width
        height: 76
        Icon { x: 24; anchors.verticalCenter: parent.verticalCenter; name: "timer"; size: 20; color: Theme.inkSoft }
        Label {
            x: 56; anchors.verticalCenter: parent.verticalCenter
            text: I18n.t("keys.countdown")
            font.pixelSize: Theme.body; font.weight: Font.Medium
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            Stepper {
                objectName: "delayField"
                width: 150; height: 40
                from: 1; to: 10
                value: page.engine.launchDelaySec
                unit: I18n.t("sec")
                enabled: !page.engine.active
                onValueModified: v => page.engine.launchDelaySec = v
            }
            GlassButton {
                objectName: "resetBindings"
                height: 40
                iconName: "reset"
                text: I18n.t("keys.reset")
                enabled: !page.engine.active
                onClicked: page.engine.resetBindings()
            }
        }
    }
}
