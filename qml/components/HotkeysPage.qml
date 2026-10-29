import QtQuick
import QtQuick.Templates as T
import FakeClicker

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
            Panel {
                id: card
                required property int index
                readonly property bool stopAction: index === 1
                readonly property var bindings: stopAction ? page.engine.stopBindings : page.engine.startBindings
                width: (page.width - Theme.gap) / 2
                height: Math.max(164, flow.y + flow.implicitHeight + 22)
                Rectangle {
                    id: badge
                    x: 20; y: 20
                    width: 40; height: 40; radius: Theme.controlRadius
                    color: card.stopAction ? Theme.control : Theme.ink
                    border.width: card.stopAction ? 1 : 0
                    border.color: Theme.hairlineStrong
                    Icon {
                        anchors.centerIn: parent
                        name: card.stopAction ? "stop" : "play"
                        size: 18
                        color: card.stopAction ? Theme.ink : Theme.inverse
                    }
                }
                Column {
                    anchors.left: badge.right; anchors.leftMargin: 14
                    anchors.verticalCenter: badge.verticalCenter
                    spacing: 2
                    Label {
                        text: I18n.t(card.stopAction ? "keys.stop" : "keys.start")
                        font.pixelSize: 17; font.weight: Font.Bold
                    }
                    Caption { text: card.bindings.length + " / 8" }
                }
                AppButton {
                    objectName: card.stopAction ? "addStopBinding" : "addStartBinding"
                    anchors.right: parent.right; anchors.rightMargin: 18
                    anchors.verticalCenter: badge.verticalCenter
                    width: 36; height: 36
                    iconName: "plus"; iconSize: 16
                    Accessible.name: I18n.t("keys.add")
                    enabled: !page.engine.active && card.bindings.length < 8
                    onClicked: page.keyboard.edit(card.index, card.bindings.length)
                }
                Rectangle {
                    x: 20; y: 80
                    width: parent.width - 40; height: 1
                    color: Theme.hairline
                }
                Flow {
                    id: flow
                    x: 20; y: 98
                    width: parent.width - 40
                    spacing: 8
                    add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.base } }
                    Repeater {
                        model: card.bindings
                        T.AbstractButton {
                            id: keyChip
                            required property int index
                            required property var modelData
                            objectName: index === 0 ? (card.stopAction ? "editStopBinding" : "editStartBinding") : "binding" + card.index + "_" + index
                            height: 44
                            width: chipRow.implicitWidth + 24 + (removable ? 26 : 0)
                            hoverEnabled: true
                            focusPolicy: Qt.StrongFocus
                            enabled: !page.engine.active
                            readonly property bool removable: card.bindings.length > 1
                            Accessible.name: modelData.label
                            onClicked: { sounds.play("tap"); page.keyboard.edit(card.index, index); }
                            opacity: enabled ? 1 : 0.5
                            background: Rectangle {
                                radius: Theme.controlRadius
                                color: keyChip.pressed ? Theme.control : keyChip.hovered ? Theme.raised : "transparent"
                                border.width: keyChip.visualFocus ? 2 : 1
                                border.color: keyChip.visualFocus ? Theme.focusRing : keyChip.hovered ? Theme.hairlineStrong : Theme.hairline
                            }
                            contentItem: Item {
                                Row {
                                    id: chipRow
                                    x: 12; anchors.verticalCenter: parent.verticalCenter
                                    spacing: 6
                                    Repeater {
                                        model: keyChip.modelData.keys
                                        Row {
                                            required property int modelData
                                            required property int index
                                            spacing: 6
                                            Label {
                                                visible: index > 0
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "+"
                                                color: Theme.faint
                                                font.family: Theme.mono
                                                font.pixelSize: Theme.small
                                            }
                                            KeyCap {
                                                size: 26
                                                text: page.engine.keyName(modelData)
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
                                width: 24; height: 24
                                iconName: "x"; iconSize: 11
                                opacity: keyChip.hovered || hovered ? 1 : 0.45
                                Accessible.name: I18n.t("keys.remove")
                                enabled: !page.engine.active
                                cue: "remove"
                                onClicked: page.engine.removeBinding(card.stopAction, keyChip.index)
                            }
                        }
                    }
                }
            }
        }
    }

    Panel {
        id: settingsCard
        y: cards.y + cards.childrenRect.height + Theme.gap
        width: parent.width
        height: Theme.rowHeight + 12
        SettingRow {
            y: 6
            icon: "timer"
            title: I18n.t("keys.countdown")
            last: true
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                Stepper {
                    objectName: "delayField"
                    anchors.verticalCenter: parent.verticalCenter
                    width: 150
                    from: 1; to: 10
                    value: page.engine.launchDelaySec
                    unit: I18n.t("sec")
                    enabled: !page.engine.active
                    Accessible.name: I18n.t("keys.countdown")
                    onValueModified: v => page.engine.launchDelaySec = v
                }
                AppButton {
                    objectName: "resetCountdown"
                    anchors.verticalCenter: parent.verticalCenter
                    compact: true
                    iconName: "reset"; iconSize: 14
                    text: I18n.t("keys.reset")
                    enabled: !page.engine.active && page.engine.launchDelaySec !== page.engine.defaultLaunchDelaySec
                    onClicked: page.engine.resetLaunchDelay()
                }
            }
        }
    }
}
