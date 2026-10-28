import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T
import CClicker
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
            width: 36; height: 36; radius: 12
            color: picker.targetBinding === 0 ? Theme.legit : Theme.blatant
            Icon { anchors.centerIn: parent; name: picker.targetBinding === 0 ? "play" : "stop"; size: 18; color: "#ffffff" }
        }
        Label {
            anchors.left: badge.right; anchors.leftMargin: 12
            anchors.verticalCenter: badge.verticalCenter
            text: I18n.t(picker.targetBinding === 0 ? "keys.start" : "keys.stop")
            font.pixelSize: Theme.title; font.weight: Font.DemiBold
        }
        Segmented {
            anchors.right: closeButton.left; anchors.rightMargin: 12
            anchors.verticalCenter: badge.verticalCenter
            width: 300; height: 38
            options: [{ text: I18n.t("sheet.single"), icon: "keyboard" }, { text: I18n.t("sheet.combo"), icon: "stack" }]
            currentIndex: picker.combination ? 1 : 0
            onActivated: index => picker.engine.captureCombination = index === 1
        }
        GlassButton {
            id: closeButton
            anchors.right: parent.right
            anchors.verticalCenter: badge.verticalCenter
            width: 38; height: 38
            iconName: "x"; iconSize: 16
            Accessible.name: I18n.t("cancel")
            onClicked: picker.close()
        }
        // Chosen keys
        Item {
            id: chosen
            y: 56; width: parent.width; height: 48
            Rectangle { anchors.fill: parent; radius: 16; color: Theme.well }
            Label {
                x: 18; anchors.verticalCenter: parent.verticalCenter
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
                        scale: pressed ? 0.94 : 1
                        Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
                        background: Rectangle { radius: 11; color: Theme.ink }
                        contentItem: Item {
                            Label { id: draftText; x: 12; anchors.verticalCenter: parent.verticalCenter; text: picker.engine.keyName(draftChip.modelData); color: "#ffffff"; font.pixelSize: 13; font.weight: Font.DemiBold }
                            Icon { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; name: "x"; size: 12; color: Qt.rgba(1, 1, 1, 0.7) }
                        }
                        NumberAnimation on scale { from: 0.5; to: 1; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 2 }
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
                    background: Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2.5
                        radius: 8
                        scale: keycap.held ? 0.93 : 1
                        Behavior on scale { SpringAnimation { spring: 6; damping: 0.3; epsilon: 0.001 } }
                        color: keycap.held ? Theme.focusRing : keycap.selected ? Theme.ink
                             : keycap.hovered && keycap.enabled ? Theme.white : keycap.enabled ? Qt.rgba(1, 1, 1, 0.55 + 0.45 * (1 - Theme.glass)) : Theme.well
                        Behavior on color { ColorAnimation { duration: 90 } }
                        border.width: keycap.visualFocus ? 2 : 1
                        border.color: keycap.visualFocus ? Theme.focusRing : Qt.rgba(0, 0, 0, 0.07)
                        Rectangle {
                            visible: keycap.modelData.v === 144
                            width: 6; height: 3; radius: 1.5
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom; anchors.bottomMargin: 5
                            color: picker.engine.numLockOn ? Theme.legit : Theme.faint
                        }
                    }
                    contentItem: Label {
                        text: keycap.modelData.t
                        font.pixelSize: Math.max(9, Math.round(picker.unit * 0.27))
                        font.weight: Font.Medium
                        color: keycap.held || keycap.selected ? "#ffffff" : keycap.enabled ? Theme.ink : Theme.faint
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
            color: Theme.danger
            font.pixelSize: Theme.small
            opacity: text !== "" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.base } }
        }
        Item {
            id: footer
            y: draftError.y + 26
            width: parent.width; height: 44
            GlassButton {
                kind: "plain"
                iconName: "reset"
                text: I18n.t("sheet.default")
                onClicked: picker.engine.beginBindingDraft([picker.targetBinding === 0 ? 117 : 119], false)
            }
            Row {
                anchors.right: parent.right
                spacing: 10
                GlassButton { objectName: "cancelKeyboard"; text: I18n.t("cancel"); onClicked: picker.close() }
                GlassButton {
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
