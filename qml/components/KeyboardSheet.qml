import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T
import FakeClicker
import "KeyboardMap.js" as KeyMap

// Physical-key picker. Keys can be chosen by mouse or by pressing them; the controller owns
// the draft, so live presses and saved selection stay in sync with Raw Input.
ModalSheet {
    id: picker
    objectName: "keyboardPicker"
    property var engine
    property real roomWidth: 1000
    property real roomHeight: 700
    // Fit both ways: 23 key units across, 6.4 down plus ~250 px of header and footer.
    readonly property real unit: Math.max(26, Math.min(44, (roomWidth - 48) / 23.2, (roomHeight - 300) / 6.4))
    width: unit * 23 + 48
    padding: 24
    readonly property bool combination: engine.captureCombination
    readonly property var chosenKeys: engine.draftKeys
    property int targetBinding: 0
    property int bindingIndex: 0
    closePolicy: T.Popup.CloseOnPressOutside
    function edit(target, slot = 0) {
        if (engine.active) return;
        targetBinding = target; bindingIndex = slot;
        const list = target === 0 ? engine.startBindings : engine.stopBindings;
        const keys = slot < list.length ? list[slot].keys : [];
        engine.setBindingEditor(true);
        engine.beginBindingDraft(keys, keys.length > 1);
        open();
    }
    function choose(key) { engine.selectDraftKey(key); }
    onClosed: engine.setBindingEditor(false)

    contentItem: Item {
        implicitHeight: footer.y + footer.height
        focus: true
        Rectangle {
            id: badge
            width: 36; height: 36; radius: Theme.controlRadius
            color: picker.targetBinding === 0 ? Theme.ink : Theme.control
            border.width: picker.targetBinding === 0 ? 0 : 1
            border.color: Theme.hairlineStrong
            Icon {
                anchors.centerIn: parent
                name: picker.targetBinding === 0 ? "play" : "stop"
                size: 16
                color: picker.targetBinding === 0 ? Theme.inverse : Theme.ink
            }
        }
        Label {
            anchors.left: badge.right; anchors.leftMargin: 12
            anchors.verticalCenter: badge.verticalCenter
            text: I18n.t(picker.targetBinding === 0 ? "keys.start" : "keys.stop")
            font.pixelSize: Theme.title; font.weight: Font.Bold
        }
        SegmentedControl {
            anchors.right: closeButton.left; anchors.rightMargin: 12
            anchors.verticalCenter: badge.verticalCenter
            width: 300
            options: [{ text: I18n.t("sheet.single"), icon: "keyboard" }, { text: I18n.t("sheet.combo"), icon: "keyCombo" }]
            currentIndex: picker.combination ? 1 : 0
            onActivated: index => picker.engine.captureCombination = index === 1
        }
        AppButton {
            id: closeButton
            kind: "plain"
            anchors.right: parent.right
            anchors.verticalCenter: badge.verticalCenter
            width: 36; height: 36
            iconName: "x"; iconSize: 15
            Accessible.name: I18n.t("cancel")
            onClicked: picker.close()
        }
        // Chosen keys
        Rectangle {
            id: chosen
            y: 56; width: parent.width; height: 50
            radius: Theme.controlRadius
            color: Theme.raised
            border.width: 1
            border.color: Theme.hairline
            Label {
                x: 16; anchors.verticalCenter: parent.verticalCenter
                visible: picker.chosenKeys.length === 0
                text: I18n.t("sheet.empty")
                color: Theme.faint
                font.pixelSize: Theme.body
            }
            Row {
                x: 8; anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Repeater {
                    model: picker.chosenKeys
                    T.AbstractButton {
                        id: draftChip
                        required property int modelData
                        objectName: "draftChip" + modelData
                        height: 34
                        width: draftText.implicitWidth + 40
                        hoverEnabled: true
                        Accessible.name: picker.engine.keyName(modelData)
                        onClicked: picker.choose(modelData)
                        background: Rectangle { radius: 8; color: draftChip.hovered ? "#E8E8E8" : Theme.ink }
                        contentItem: Item {
                            Label { id: draftText; x: 12; anchors.verticalCenter: parent.verticalCenter; text: picker.engine.keyName(draftChip.modelData); color: Theme.inverse; font.family: Theme.mono; font.pixelSize: 13; font.weight: Font.DemiBold }
                            Icon { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; name: "x"; size: 11; stroke: 2; color: Qt.rgba(0, 0, 0, 0.55) }
                        }
                        NumberAnimation on opacity { from: 0; to: 1; duration: Theme.base }
                    }
                }
            }
        }
        // Keyboard
        Item {
            id: keys
            y: chosen.y + chosen.height + 18
            width: picker.unit * 23
            height: picker.unit * 6.4
            Repeater {
                model: KeyMap.keys
                T.Button {
                    id: keycap
                    required property var modelData
                    objectName: "keycap" + modelData.v
                    x: modelData.x * picker.unit
                    y: modelData.y * picker.unit
                    width: modelData.u * picker.unit
                    height: modelData.h * picker.unit
                    readonly property bool selected: picker.chosenKeys.indexOf(modelData.v) !== -1
                    readonly property bool held: picker.engine.pressedKeys.indexOf(modelData.v) !== -1
                    readonly property bool numpadDigit: (modelData.v >= 96 && modelData.v <= 105) || modelData.v === 110
                    enabled: picker.engine.keyAllowed(modelData.v) && (!numpadDigit || picker.engine.numLockOn)
                    hoverEnabled: true
                    focusPolicy: Qt.StrongFocus
                    Accessible.name: modelData.t
                    onClicked: picker.choose(modelData.v)
                    background: Item {
                        anchors.fill: parent
                        anchors.margins: 2.5
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.smallRadius + 1
                            color: keycap.selected ? Theme.ink
                                 : keycap.held ? Theme.controlActive
                                 : !keycap.enabled ? "transparent"
                                 : keycap.hovered ? Theme.controlHover : Theme.control
                            border.width: keycap.selected ? 0 : 1
                            border.color: keycap.held ? "#4A4A4A" : keycap.enabled ? Theme.hairlineStrong : Theme.hairline
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.smallRadius + 1
                            color: "transparent"
                            visible: keycap.visualFocus
                            border.width: 2
                            border.color: Theme.focusRing
                        }
                        Rectangle {
                            visible: keycap.modelData.v === 144
                            width: 6; height: 3; radius: 1.5
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom; anchors.bottomMargin: 5
                            color: picker.engine.numLockOn ? Theme.ink : Theme.faint
                        }
                    }
                    contentItem: Label {
                        text: keycap.modelData.t
                        font.family: Theme.mono
                        font.pixelSize: Math.max(9, Math.round(picker.unit * 0.26))
                        font.weight: Font.Medium
                        color: keycap.selected ? Theme.inverse : keycap.held ? Theme.ink : keycap.enabled ? Theme.inkSoft : Theme.faint
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
        Label {
            id: draftError
            y: keys.y + keys.height + 8
            width: parent.width
            elide: Text.ElideRight
            text: I18n.msg(picker.engine.draftError)
            color: Theme.dangerText
            font.pixelSize: Theme.small
            opacity: text !== "" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.base } }
        }
        Item {
            id: footer
            y: draftError.y + 26
            width: parent.width; height: 40
            AppButton {
                kind: "plain"
                iconName: "reset"; iconSize: 14
                text: I18n.t("sheet.default")
                onClicked: picker.engine.beginBindingDraft([picker.targetBinding === 0 ? 117 : 119], false)
            }
            Row {
                anchors.right: parent.right
                spacing: 10
                AppButton { objectName: "cancelKeyboard"; text: I18n.t("cancel"); onClicked: picker.close() }
                AppButton {
                    objectName: "applyKeyboard"
                    kind: "primary"
                    iconName: "check"
                    text: I18n.t("sheet.apply")
                    enabled: picker.chosenKeys.length > 0
                    onClicked: if (picker.engine.applyChordSlot(picker.targetBinding === 1, picker.bindingIndex, picker.chosenKeys)) picker.close()
                }
            }
        }
    }
}
