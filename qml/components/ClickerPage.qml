import QtQuick
import QtQuick.Templates as T
import FakeClicker

Item {
    id: page
    property var engine
    property var windowSheet
    readonly property bool locked: engine.active
    readonly property bool blatant: engine.mode === 1
    readonly property var presets: blatant ? [20, 50, 100, 250, 500, 1000] : [8, 10, 12, 14, 16, 20]
    readonly property real gap: Theme.gap
    // Countdown, live rate, clicks and Start/Stop are on the Dynamic Island.
    readonly property real leftWidth: width

    // Step size grows with the rate so both 12 and 5000 CPS are a few presses away.
    function nudge(up) {
        const v = engine.cps;
        const base = up ? v : v - 0.0001;
        const s = base < 20 ? 1 : base < 100 ? 5 : base < 500 ? 25 : base < 2000 ? 100 : base < 10000 ? 500 : 1000;
        const next = up ? Math.floor(v / s) * s + s : Math.ceil(v / s) * s - s;
        if (next > 0)
            engine.cps = next;
    }

    // ── Mode ────────────────────────────────────────────────────────────────
    Panel {
        id: modeCard
        width: page.leftWidth
        height: 88
        Row {
            x: 8; y: 8
            spacing: 8
            Repeater {
                model: [
                    { icon: "hand", title: "mode.legit", note: "mode.legit.note" },
                    { icon: "bolt", title: "mode.blatant", note: "mode.blatant.note" }
                ]
                T.AbstractButton {
                    id: tile
                    required property int index
                    required property var modelData
                    objectName: "mode" + index
                    width: (modeCard.width - 24) / 2
                    height: modeCard.height - 16
                    hoverEnabled: true
                    focusPolicy: Qt.StrongFocus
                    enabled: !page.locked
                    readonly property bool selected: page.engine.mode === index
                    readonly property color tint: Theme.modeColor(index)
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: I18n.t(modelData.title)
                    Accessible.checked: selected
                    onClicked: if (!selected) { sounds.play("select"); page.engine.mode = index; }
                    Keys.onLeftPressed: if (page.engine.mode !== 0) { sounds.play("select"); page.engine.mode = 0; }
                    Keys.onRightPressed: if (page.engine.mode !== 1) { sounds.play("select"); page.engine.mode = 1; }
                    opacity: enabled || selected ? 1 : 0.45
                    background: Rectangle {
                        radius: Theme.controlRadius
                        color: tile.selected ? Theme.raised : tile.hovered ? Qt.rgba(1, 1, 1, 0.025) : "transparent"
                        border.width: tile.visualFocus ? 2 : 1
                        border.color: tile.visualFocus ? Theme.focusRing : tile.selected ? Theme.tint(tile.tint, 0.55) : "transparent"
                    }
                    contentItem: Item {
                        Rectangle {
                            id: badge
                            x: 12; anchors.verticalCenter: parent.verticalCenter
                            width: 44; height: 44; radius: Theme.controlRadius
                            color: tile.selected ? tile.tint : Theme.control
                            border.width: tile.selected ? 0 : 1
                            border.color: Theme.hairlineStrong
                            Behavior on color { ColorAnimation { duration: Theme.base } }
                            Icon {
                                anchors.centerIn: parent
                                name: tile.modelData.icon
                                size: 22; stroke: 2
                                color: tile.selected ? "#FFFFFF" : Theme.muted
                            }
                        }
                        Column {
                            anchors.left: badge.right; anchors.leftMargin: 14
                            anchors.right: parent.right; anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            Label {
                                text: I18n.t(tile.modelData.title)
                                font.pixelSize: 17
                                font.weight: Font.Bold
                                color: tile.selected ? Theme.ink : tile.hovered ? Theme.inkSoft : Theme.muted
                            }
                            Label {
                                width: parent.width
                                elide: Text.ElideRight
                                text: I18n.t(tile.modelData.note)
                                font.pixelSize: Theme.small
                                color: tile.selected ? Theme.muted : Theme.faint
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Rate ────────────────────────────────────────────────────────────────
    Panel {
        id: rateCard
        y: modeCard.height + page.gap
        width: page.leftWidth
        height: page.height - modeCard.height - optionsCard.height - 2 * page.gap
        Item {
            id: rateRow
            x: rateCard.pad
            y: Math.max(0, (parent.height - 70 - presetRow.height - 18) / 2 - 8)
            width: parent.width - 2 * rateCard.pad; height: 70
            TextInput {
                id: rateInput
                objectName: "cpsField"
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(60, Math.min(contentWidth + 4, parent.width - 170))
                clip: true
                readOnly: page.locked
                text: I18n.rate(page.engine.cps)
                color: Theme.ink
                font.family: Theme.sans
                font.pixelSize: Theme.display
                font.weight: Font.Bold
                font.letterSpacing: -2.4
                font.features: { "tnum": 1 }
                renderType: Text.NativeRendering
                selectByMouse: true
                selectionColor: Theme.selection
                selectedTextColor: Theme.ink
                // Any positive amount, no upper cap.
                validator: RegularExpressionValidator { regularExpression: /^[0-9]{0,12}([.,][0-9]{0,2})?$/ }
                Accessible.name: I18n.t("cps.title")
                function apply() {
                    const v = parseFloat(text.replace(",", "."));
                    if (v > 0 && isFinite(v) && v !== page.engine.cps)
                        page.engine.cps = v;
                    text = Qt.binding(() => I18n.rate(page.engine.cps));
                }
                // Edit the plain number; grouping separators would read as decimals.
                onActiveFocusChanged: {
                    if (activeFocus) {
                        text = String(Math.round(page.engine.cps * 100) / 100);
                        selectAll();
                    } else {
                        apply();
                    }
                }
                onAccepted: { apply(); focus = false; }
            }
            Label {
                anchors.left: rateInput.right; anchors.leftMargin: 10
                anchors.baseline: rateInput.baseline
                text: I18n.t("cps")
                color: Theme.muted
                font.family: Theme.mono
                font.pixelSize: 14; font.weight: Font.Medium
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                AppButton {
                    objectName: "cpsMinus"
                    width: 44; height: 44
                    iconName: "minus"; iconSize: 18
                    Accessible.name: "−"
                    enabled: !page.locked && page.engine.cps > 1
                    autoRepeat: true
                    cue: "step"
                    onClicked: page.nudge(false)
                }
                AppButton {
                    objectName: "cpsPlus"
                    width: 44; height: 44
                    iconName: "plus"; iconSize: 18
                    Accessible.name: "+"
                    enabled: !page.locked
                    autoRepeat: true
                    cue: "step"
                    onClicked: page.nudge(true)
                }
            }
        }
        Row {
            id: presetRow
            x: rateCard.pad
            anchors.bottom: parent.bottom; anchors.bottomMargin: 18
            spacing: 6
            Repeater {
                model: page.presets
                T.AbstractButton {
                    id: chip
                    required property int index
                    required property int modelData
                    objectName: "preset" + modelData
                    readonly property bool selected: Math.abs(page.engine.cps - modelData) < 0.001
                    height: 30
                    width: Math.max(48, chipText.implicitWidth + 24)
                    hoverEnabled: true
                    focusPolicy: Qt.StrongFocus
                    enabled: !page.locked
                    opacity: enabled ? 1 : 0.4
                    Accessible.name: modelData + " " + I18n.t("cps")
                    onClicked: { if (!selected) sounds.play("select"); page.engine.cps = modelData; }
                    background: Rectangle {
                        radius: 8
                        color: chip.selected ? Theme.ink : chip.hovered ? Theme.control : Theme.raised
                        border.width: chip.selected ? 0 : 1
                        border.color: Theme.hairline
                        Rectangle {
                            anchors.fill: parent; anchors.margins: -3
                            radius: 11
                            color: "transparent"
                            visible: chip.visualFocus
                            border.width: 2
                            border.color: Theme.focusRing
                        }
                    }
                    contentItem: Label {
                        id: chipText
                        text: I18n.number(chip.modelData, 0)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: chip.selected ? Theme.inverse : chip.hovered ? Theme.ink : Theme.inkSoft
                        font.family: Theme.mono
                        font.pixelSize: Theme.small; font.weight: Font.DemiBold
                    }
                }
            }
        }
    }

    // ── Options ─────────────────────────────────────────────────────────────
    Panel {
        id: optionsCard
        title: I18n.t("section.options")
        y: page.height - height
        width: page.leftWidth
        height: headerHeight + options.height + 4
        Column {
            id: options
            width: parent.width
            SettingRow {
                icon: "target"; title: I18n.t("target")
                // Opens the window picker with live thumbnails.
                T.AbstractButton {
                    id: targetButton
                    objectName: "targetButton"
                    anchors.verticalCenter: parent.verticalCenter
                    width: 258; height: 36
                    hoverEnabled: true
                    focusPolicy: Qt.StrongFocus
                    enabled: !page.locked
                    opacity: enabled ? 1 : 0.4
                    Accessible.name: I18n.t("target") + ": " + (page.engine.targetWindow === "" ? I18n.t("target.any") : page.engine.targetTitle)
                    onClicked: if (page.windowSheet) { sounds.play("tap"); page.windowSheet.choose(); }
                    background: Rectangle {
                        radius: Theme.controlRadius
                        color: targetButton.pressed ? Theme.controlActive : targetButton.hovered ? Theme.control : Theme.raised
                        border.width: targetButton.visualFocus ? 2 : 1
                        border.color: targetButton.visualFocus ? Theme.focusRing : Theme.hairline
                    }
                    contentItem: Item {
                        Label {
                            anchors.left: parent.left; anchors.leftMargin: 12
                            anchors.right: targetChevron.left; anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignRight
                            text: page.engine.targetWindow === "" ? I18n.t("target.any") : page.engine.targetTitle
                            elide: Text.ElideRight
                            color: page.engine.targetWindow === "" ? Theme.inkSoft : Theme.ink
                            font.pixelSize: 13; font.weight: Font.DemiBold
                        }
                        Icon { id: targetChevron; anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; name: "chevron"; size: 14; color: Theme.faint }
                    }
                }
            }
            SettingRow {
                icon: "mouse"; title: I18n.t("button")
                SegmentedControl {
                    objectName: "buttonSegment"
                    anchors.verticalCenter: parent.verticalCenter
                    width: 258
                    enabled: !page.locked
                    options: [{ text: I18n.t("button.0") }, { text: I18n.t("button.1") }, { text: I18n.t("button.2") }]
                    currentIndex: page.engine.mouseButton
                    onActivated: index => page.engine.mouseButton = index
                }
            }
            // Legit variance or Blatant hold, crossfading in place.
            Item {
                width: options.width; height: Theme.rowHeight
                SettingRow {
                    icon: "wave"; title: I18n.t("variance")
                    opacity: page.blatant ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Theme.base } }
                    SegmentedControl {
                        objectName: "varianceSegment"
                        anchors.verticalCenter: parent.verticalCenter
                        width: 258
                        enabled: !page.locked && !page.blatant
                        options: [{ text: I18n.t("variance.0") }, { text: I18n.t("variance.1") }, { text: I18n.t("variance.2") }]
                        currentIndex: page.engine.variance
                        onActivated: index => page.engine.variance = index
                    }
                }
                SettingRow {
                    icon: "hold"; title: I18n.t("hold")
                    opacity: page.blatant ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Theme.base } }
                    Stepper {
                        objectName: "holdField"
                        anchors.verticalCenter: parent.verticalCenter
                        width: 180
                        enabled: !page.locked && page.blatant
                        from: 0
                        to: Math.max(0, Math.min(1000, Math.ceil(1000 / page.engine.cps) - 1))
                        value: page.engine.holdMs
                        unit: I18n.t("ms")
                        zeroText: I18n.t("hold.instant")
                        Accessible.name: I18n.t("hold")
                        onValueModified: v => page.engine.holdMs = v
                    }
                }
            }
            SettingRow {
                icon: "hourglass"; title: I18n.t("limit.time")
                Stepper {
                    objectName: "durationField"
                    anchors.verticalCenter: parent.verticalCenter
                    width: 180
                    enabled: !page.locked
                    from: 0; to: 86400; step: 5
                    value: page.engine.durationSec
                    unit: I18n.t("sec")
                    zeroText: "∞"
                    Accessible.name: I18n.t("limit.time")
                    onValueModified: v => page.engine.durationSec = v
                }
            }
            SettingRow {
                icon: "hash"; title: I18n.t("limit.clicks")
                last: true
                Stepper {
                    objectName: "countField"
                    anchors.verticalCenter: parent.verticalCenter
                    width: 180
                    enabled: !page.locked
                    from: 0; to: 1e12; step: 100
                    value: page.engine.countLimit
                    zeroText: "∞"
                    Accessible.name: I18n.t("limit.clicks")
                    onValueModified: v => page.engine.countLimit = v
                }
            }
        }
    }
}
