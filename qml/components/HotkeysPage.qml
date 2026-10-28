import QtQuick
import QtQuick.Templates as T
import LightClicker

Item {
    id: page
    property var engine
    property var keyboard

    Row {
        id: cards
        width: parent.width
        spacing: Theme.gap
        Repeater {
            model: 2
            Card {
                id: card
                required property int index
                readonly property bool stopAction: index === 1
                readonly property var bindings: stopAction ? page.engine.stopBindings : page.engine.startBindings
                title: Theme.isGlass ? "" : I18n.t(stopAction ? "keys.stop" : "keys.start")
                width: (page.width - Theme.gap) / 2
                height: headerHeight + Math.max(Theme.isGlass ? 190 : 150, (Theme.isGlass ? 84 : 20) + flow.implicitHeight + 20)
                Behavior on height { SpringAnimation { spring: 3.5; damping: 0.32; epsilon: 0.1 } }
                // Glass header: coloured badge, title and add button inside the panel.
                Fill {
                    id: badge
                    visible: Theme.isGlass
                    x: 22; y: 22
                    width: 40; height: 40; radius: 13
                    color: card.stopAction ? Theme.blatant : Theme.legit
                    Icon { anchors.centerIn: parent; name: card.stopAction ? "stop" : "play"; size: 20; color: "#ffffff" }
                }
                Label {
                    visible: Theme.isGlass
                    anchors.left: badge.right; anchors.leftMargin: 14
                    anchors.verticalCenter: badge.verticalCenter
                    text: I18n.t(card.stopAction ? "keys.stop" : "keys.start")
                    font.pixelSize: 18; font.weight: Font.DemiBold
                }
                AppButton {
                    objectName: card.stopAction ? "addStopBinding" : "addStartBinding"
                    anchors.right: parent.right; anchors.rightMargin: Theme.isGlass ? 18 : 12
                    y: Theme.isGlass ? 23 : 12
                    width: Theme.isGlass ? 38 : 32; height: width
                    kind: Theme.isGlass ? "normal" : "plain"
                    iconName: "plus"; iconSize: 18
                    Accessible.name: I18n.t("keys.add")
                    enabled: !page.engine.active && card.bindings.length < 8
                    onClicked: page.keyboard.edit(card.index, card.bindings.length)
                }
                Flow {
                    id: flow
                    x: Theme.isGlass ? 22 : 16; y: Theme.isGlass ? 84 : 14
                    width: parent.width - x - (Theme.isGlass ? 22 : 56)
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
                            height: Theme.isGlass ? 46 : 40
                            width: chipRow.implicitWidth + 28 + (removable ? 26 : 0)
                            hoverEnabled: true
                            focusPolicy: Qt.StrongFocus
                            enabled: !page.engine.active
                            readonly property bool removable: card.bindings.length > 1
                            Accessible.name: modelData.label
                            onClicked: page.keyboard.edit(card.index, index)
                            scale: Theme.isGlass ? (pressed ? 0.94 : hovered ? 1.03 : 1) : 1
                            opacity: !Theme.isGlass && pressed ? 0.55 : 1
                            Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
                            background: Item {
                                Surface {
                                    anchors.fill: parent
                                    visible: Theme.isGlass
                                    radius: 15
                                    elevation: 0.5
                                    tintAlpha: keyChip.hovered ? 0.75 : 0.58
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    visible: !Theme.isGlass
                                    radius: 10
                                    color: keyChip.hovered ? Theme.fillStrong : Theme.fill
                                }
                                Rectangle {
                                    anchors.fill: parent; anchors.margins: -3
                                    radius: Theme.isGlass ? 18 : 12; color: "transparent"
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
                                        Fill {
                                            id: cap
                                            required property int modelData
                                            height: 28; radius: Theme.isGlass ? 8 : 6
                                            width: Math.max(28, capText.implicitWidth + 14)
                                            color: Theme.white
                                            strength: 0.62
                                            Rectangle { visible: !Theme.isGlass; anchors.bottom: parent.bottom; width: parent.width; height: 2; radius: 1; color: Qt.rgba(0, 0, 0, 0.18) }
                                            Label {
                                                id: capText
                                                anchors.centerIn: parent
                                                text: page.engine.keyName(cap.modelData)
                                                font.pixelSize: Theme.small + 1; font.weight: Font.DemiBold
                                            }
                                        }
                                    }
                                }
                            }
                            AppButton {
                                visible: keyChip.removable
                                kind: "plain"
                                anchors.right: parent.right; anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                width: 26; height: 26
                                iconName: "x"; iconSize: 12
                                opacity: keyChip.hovered || hovered ? 1 : 0.5
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

    Card {
        id: settingsCard
        y: cards.y + cards.childrenRect.height + Theme.gap
        width: parent.width
        height: headerHeight + Theme.rowHeight + (Theme.isGlass ? 18 : 0)
        Cell {
            y: Theme.isGlass ? 9 : 0
            icon: "timer"
            title: I18n.t("keys.countdown")
            last: true
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12
                Stepper {
                    objectName: "delayField"
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.isGlass ? 150 : 170
                    from: 1; to: 10
                    value: page.engine.launchDelaySec
                    unit: I18n.t("sec")
                    enabled: !page.engine.active
                    onValueModified: v => page.engine.launchDelaySec = v
                }
                AppButton {
                    objectName: "resetBindings"
                    anchors.verticalCenter: parent.verticalCenter
                    compact: !Theme.isGlass
                    iconName: "reset"
                    text: I18n.t("keys.reset")
                    enabled: !page.engine.active
                    onClicked: page.engine.resetBindings()
                }
            }
        }
    }
}
