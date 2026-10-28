import QtQuick
import QtQuick.Templates as T
import CClicker

Item {
    id: page
    property var engine
    readonly property bool locked: engine.active
    readonly property bool blatant: engine.mode === 1
    readonly property var presets: blatant ? [20, 50, 100, 250, 500, 1000] : [8, 10, 12, 14, 16, 20]

    // Step size grows with the rate so both 12 and 5000 CPS are a few presses away.
    function stepFor(v, up) {
        const base = up ? v : v - 0.0001;
        return base < 20 ? 1 : base < 100 ? 5 : base < 500 ? 25 : base < 2000 ? 100 : base < 10000 ? 500 : 1000;
    }
    function nudge(up) {
        const v = engine.cps;
        const s = stepFor(v, up);
        const next = up ? Math.floor(v / s) * s + s : Math.ceil(v / s) * s - s;
        if (next > 0)
            engine.cps = next;
    }

    // Inline components do not see outer ids; width comes from the parent column.
    component OptionRow: Item {
        id: optionRow
        property string icon
        property string title
        property real shift: 0
        Behavior on shift { SpringAnimation { spring: 4; damping: 0.3; epsilon: 0.05 } }
        transform: Translate { y: optionRow.shift }
        default property alias control: slot.data
        width: parent ? parent.width : 0
        height: 40
        Icon { id: rowIcon; anchors.verticalCenter: parent.verticalCenter; name: optionRow.icon; size: 19; color: Theme.inkSoft }
        Label {
            anchors.left: rowIcon.right; anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: optionRow.title
            font.pixelSize: Theme.body; font.weight: Font.Medium
        }
        Item { id: slot; anchors.right: parent.right; width: childrenRect.width; height: parent.height }
    }

    // ── Controls card ──────────────────────────────────────────────────────────
    Glass {
        id: controls
        width: parent.width - live.width - Theme.gutter
        height: parent.height

        // Mode tiles with a shared sliding lens.
        Item {
            id: modes
            x: 20; y: 20
            width: parent.width - 40
            height: 88
            readonly property real cell: (width - 10) / 2
            property real lensX: page.engine.mode * (cell + 10)
            Behavior on lensX { SpringAnimation { spring: Theme.springStiff; damping: Theme.springDamp; epsilon: 0.05 } }
            readonly property real travel: Math.min(60, Math.abs(page.engine.mode * (cell + 10) - lensX) * 0.3)
            Rectangle { anchors.fill: parent; radius: 24; color: Theme.well }
            Glass {
                x: modes.lensX + 4 - modes.travel / 2
                y: 4
                width: modes.cell - 8 + modes.travel
                height: modes.height - 8
                radius: 20
                elevation: 0.9
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.width: 1.5
                    border.color: Qt.rgba(Theme.modeColor(page.engine.mode).r, Theme.modeColor(page.engine.mode).g, Theme.modeColor(page.engine.mode).b, 0.45)
                    Behavior on border.color { ColorAnimation { duration: Theme.slow } }
                }
            }
            Repeater {
                id: modeButtons
                model: [
                    { icon: "hand", title: "mode.legit", sub: "mode.legit.sub" },
                    { icon: "bolt", title: "mode.blatant", sub: "mode.blatant.sub" }
                ]
                T.AbstractButton {
                    id: tile
                    required property int index
                    required property var modelData
                    objectName: "mode" + index
                    x: index * (modes.cell + 10)
                    width: modes.cell; height: modes.height
                    hoverEnabled: true
                    focusPolicy: Qt.StrongFocus
                    enabled: !page.locked
                    readonly property bool selected: page.engine.mode === index
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: I18n.t(modelData.title)
                    Accessible.checked: selected
                    onClicked: page.engine.mode = index
                    Keys.onLeftPressed: page.engine.mode = 0
                    Keys.onRightPressed: page.engine.mode = 1
                    opacity: enabled || selected ? 1 : 0.5
                    contentItem: Item {
                        scale: tile.pressed ? 0.97 : 1
                        Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
                        Rectangle {
                            id: modeBadge
                            x: 18; anchors.verticalCenter: parent.verticalCenter
                            width: 44; height: 44; radius: 14
                            color: tile.selected ? Theme.modeColor(tile.index) : Theme.well
                            Behavior on color { ColorAnimation { duration: Theme.slow } }
                            Icon {
                                anchors.centerIn: parent
                                name: tile.modelData.icon
                                size: 24; stroke: 2
                                color: tile.selected ? "#ffffff" : Theme.muted
                                rotation: tile.selected ? 0 : -8
                                Behavior on rotation { SpringAnimation { spring: 4; damping: 0.25 } }
                            }
                        }
                        Column {
                            anchors.left: modeBadge.right; anchors.leftMargin: 14
                            anchors.right: parent.right; anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            Label {
                                text: I18n.t(tile.modelData.title)
                                font.pixelSize: 17
                                font.weight: Font.DemiBold
                                color: tile.selected ? Theme.ink : Theme.inkSoft
                            }
                            Label {
                                width: parent.width
                                elide: Text.ElideRight
                                text: I18n.t(tile.modelData.sub)
                                font.pixelSize: Theme.small
                                color: Theme.muted
                            }
                        }
                    }
                    background: Rectangle {
                        radius: 20
                        color: !tile.selected && tile.hovered ? Qt.rgba(1, 1, 1, 0.35) : "transparent"
                        border.width: tile.visualFocus ? 2 : 0
                        border.color: Theme.focusRing
                    }
                }
            }
        }

        // Rate: large editable number, steppers and presets.
        Label {
            id: rateTitle
            x: 24; y: modes.y + modes.height + 22
            text: I18n.t("cps.title")
            color: Theme.muted
            font.pixelSize: Theme.small; font.weight: Font.Medium
        }
        Item {
            id: rateRow
            x: 20; y: rateTitle.y + 18
            width: parent.width - 40; height: 72
            TextInput {
                id: rateInput
                objectName: "cpsField"
                x: 4; anchors.verticalCenter: parent.verticalCenter
                width: Math.max(60, contentWidth + 4)
                readOnly: page.locked
                text: I18n.rate(page.engine.cps)
                color: Theme.ink
                font.family: Theme.sans
                font.pixelSize: Theme.display
                font.weight: Font.DemiBold
                font.letterSpacing: -1.5
                font.features: { "tnum": 1 }
                selectByMouse: true
                selectionColor: Theme.focusRing
                // Any positive amount; no upper cap.
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
                // Gentle pop when the value changes from outside the field.
                property real pop: 1
                scale: pop
                transformOrigin: Item.Left
                Connections {
                    target: page.engine
                    function onChanged() {
                        if (rateInput.lastCps !== page.engine.cps) {
                            rateInput.lastCps = page.engine.cps;
                            popAnim.restart();
                        }
                    }
                }
                property real lastCps: -1
                SequentialAnimation {
                    id: popAnim
                    NumberAnimation { target: rateInput; property: "pop"; to: 1.06; duration: 80; easing.type: Easing.OutQuad }
                    SpringAnimation { target: rateInput; property: "pop"; to: 1; spring: 4; damping: 0.28; epsilon: 0.001 }
                }
            }
            Label {
                anchors.left: rateInput.right; anchors.leftMargin: 8
                anchors.baseline: rateInput.baseline
                text: I18n.t("cps")
                color: Theme.muted
                font.pixelSize: 18; font.weight: Font.DemiBold
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                GlassButton {
                    objectName: "cpsMinus"
                    width: 48; height: 48
                    iconName: "minus"; iconSize: 20
                    Accessible.name: "−"
                    enabled: !page.locked && page.engine.cps > 1
                    autoRepeat: true
                    onClicked: page.nudge(false)
                }
                GlassButton {
                    objectName: "cpsPlus"
                    width: 48; height: 48
                    iconName: "plus"; iconSize: 20
                    Accessible.name: "+"
                    enabled: !page.locked
                    autoRepeat: true
                    onClicked: page.nudge(true)
                }
            }
        }
        Row {
            id: presetRow
            x: 20; y: rateRow.y + rateRow.height + 6
            spacing: 8
            Repeater {
                model: page.presets
                T.AbstractButton {
                    id: chip
                    required property int index
                    required property int modelData
                    objectName: "preset" + modelData
                    readonly property bool selected: Math.abs(page.engine.cps - modelData) < 0.001
                    height: 32
                    width: Math.max(52, chipText.implicitWidth + 26)
                    hoverEnabled: true
                    focusPolicy: Qt.StrongFocus
                    enabled: !page.locked
                    opacity: enabled ? 1 : 0.45
                    Accessible.name: modelData + " " + I18n.t("cps")
                    onClicked: page.engine.cps = modelData
                    scale: pressed ? 0.92 : 1
                    Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
                    // Presets swap with a staggered drop when the mode changes.
                    property real arrive: 1
                    transform: Translate { y: (1 - chip.arrive) * -8 }
                    Connections {
                        target: page
                        function onBlatantChanged() { chipIn.restart(); }
                    }
                    SequentialAnimation {
                        id: chipIn
                        PropertyAction { target: chip; property: "arrive"; value: 0 }
                        PauseAnimation { duration: chip.index * 35 }
                        SpringAnimation { target: chip; property: "arrive"; to: 1; spring: 4; damping: 0.3; epsilon: 0.002 }
                    }
                    background: Rectangle {
                        radius: 16
                        color: chip.selected ? Theme.ink : chip.hovered ? Qt.rgba(1, 1, 1, 0.7) : Theme.well
                        Behavior on color { ColorAnimation { duration: Theme.base } }
                        border.width: chip.visualFocus ? 2 : 0
                        border.color: Theme.focusRing
                    }
                    contentItem: Label {
                        id: chipText
                        text: I18n.number(chip.modelData, 0)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: chip.selected ? "#ffffff" : Theme.inkSoft
                        font.pixelSize: 13; font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                        opacity: chip.arrive
                    }
                }
            }
        }

        Rectangle { id: divider; x: 24; y: presetRow.y + 52; width: parent.width - 48; height: 1; color: Theme.hairline; opacity: 0.8 }

        // Options
        Column {
            id: options
            x: 24; y: divider.y + 16
            width: parent.width - 48
            spacing: 12
            OptionRow {
                icon: "mouse"; title: I18n.t("button")
                Segmented {
                    objectName: "buttonSegment"
                    width: 300; height: 38
                    enabled: !page.locked
                    options: [{ text: I18n.t("button.0") }, { text: I18n.t("button.1") }, { text: I18n.t("button.2") }]
                    currentIndex: page.engine.mouseButton
                    onActivated: index => page.engine.mouseButton = index
                }
            }
            // Mode-specific row: Legit variance or Blatant hold, crossfading in place.
            Item {
                width: options.width; height: 40
                OptionRow {
                    icon: "wave"; title: I18n.t("variance")
                    opacity: page.blatant ? 0 : 1
                    visible: opacity > 0
                    enabled: !page.blatant
                    Behavior on opacity { NumberAnimation { duration: Theme.base } }
                    shift: page.blatant ? -6 : 0
                    Segmented {
                        objectName: "varianceSegment"
                        width: 300; height: 38
                        enabled: !page.locked
                        options: [{ text: I18n.t("variance.0") }, { text: I18n.t("variance.1") }, { text: I18n.t("variance.2") }]
                        currentIndex: page.engine.variance
                        onActivated: index => page.engine.variance = index
                    }
                }
                OptionRow {
                    icon: "timer"; title: I18n.t("hold")
                    opacity: page.blatant ? 1 : 0
                    visible: opacity > 0
                    enabled: page.blatant
                    Behavior on opacity { NumberAnimation { duration: Theme.base } }
                    shift: page.blatant ? 0 : 6
                    Stepper {
                        objectName: "holdField"
                        width: 180; height: 38
                        enabled: !page.locked
                        from: 0
                        to: Math.max(0, Math.min(1000, Math.ceil(1000 / page.engine.cps) - 1))
                        value: page.engine.holdMs
                        unit: I18n.t("ms")
                        zeroText: I18n.t("hold.instant")
                        onValueModified: v => page.engine.holdMs = v
                    }
                }
            }
            OptionRow {
                icon: "hourglass"; title: I18n.t("limits")
                Row {
                    spacing: 8
                    Stepper {
                        objectName: "durationField"
                        width: 146; height: 38
                        enabled: !page.locked
                        from: 0; to: 86400; step: 5
                        value: page.engine.durationSec
                        unit: I18n.t("sec")
                        zeroText: "∞"
                        Accessible.name: I18n.t("limit.time")
                        onValueModified: v => page.engine.durationSec = v
                    }
                    Stepper {
                        objectName: "countField"
                        width: 146; height: 38
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

        // Start / countdown / stop
        T.AbstractButton {
            id: startButton
            objectName: "startButton"
            x: 20; width: parent.width - 40; height: 58
            anchors.bottom: parent.bottom; anchors.bottomMargin: 20
            hoverEnabled: true
            focusPolicy: Qt.StrongFocus
            enabled: page.engine.available || page.engine.active
            readonly property string phase: page.engine.state
            readonly property bool armed: phase === "arming"
            readonly property bool live: phase === "running" || phase === "stopping"
            Accessible.name: armed ? I18n.t("cancel") : live ? I18n.t("stop") : I18n.t("start")
            onClicked: page.engine.toggle()
            scale: pressed ? 0.97 : hovered ? 1.01 : 1
            Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
            opacity: enabled ? 1 : 0.4
            property real progress: 0
            onArmedChanged: {
                if (armed) {
                    progress = 0;
                    countdownFill.duration = page.engine.launchDelaySec * 1000;
                    countdownFill.restart();
                } else {
                    countdownFill.stop();
                    progress = 0;
                }
            }
            NumberAnimation { id: countdownFill; target: startButton; property: "progress"; from: 0; to: 1; easing.type: Easing.Linear }
            background: Rectangle {
                radius: 29
                color: startButton.live ? Theme.modeColor(page.engine.mode) : startButton.armed ? "#2c2c2e" : startButton.hovered ? "#2c2c2e" : Theme.ink
                Behavior on color { ColorAnimation { duration: Theme.slow } }
                clip: true
                Rectangle {
                    width: parent.width * startButton.progress
                    height: parent.height
                    radius: parent.radius
                    color: Theme.arming
                    opacity: startButton.armed ? 0.9 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.base } }
                }
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.16) }
                        GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0) }
                    }
                }
                Rectangle {
                    anchors.fill: parent; anchors.margins: -4
                    radius: height / 2
                    color: "transparent"
                    border.width: startButton.visualFocus ? 2 : 0
                    border.color: Theme.focusRing
                }
            }
            contentItem: Item {
                Row {
                    anchors.centerIn: parent
                    spacing: 10
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: startButton.live ? "stop" : startButton.armed ? "x" : "play"
                        size: 20; stroke: 2.2
                        color: "#ffffff"
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: startButton.armed ? I18n.t("cancel") + "  ·  " + page.engine.countdown
                              : startButton.live ? I18n.t("stop") : I18n.t("start")
                        color: "#ffffff"
                        font.pixelSize: 16; font.weight: Font.DemiBold
                    }
                }
                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    height: 26; radius: 8
                    width: keyText.implicitWidth + 16
                    color: Qt.rgba(1, 1, 1, 0.16)
                    border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.22)
                    Label {
                        id: keyText
                        anchors.centerIn: parent
                        text: startButton.live || startButton.armed ? page.engine.stopLabel : page.engine.startLabel
                        color: "#ffffff"
                        font.pixelSize: Theme.small; font.weight: Font.DemiBold
                    }
                }
            }
        }
    }

    // ── Live card ──────────────────────────────────────────────────────────────
    Glass {
        id: live
        anchors.right: parent.right
        width: 272; height: parent.height
        readonly property bool running: page.engine.state === "running" || page.engine.state === "stopping"
        readonly property color stateColor: page.engine.state === "arming" ? Theme.arming : running ? Theme.modeColor(page.engine.mode) : Theme.faint

        Row {
            x: 22; y: 24
            spacing: 8
            Rectangle {
                id: stateDot
                width: 8; height: 8; radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: live.stateColor
                Behavior on color { ColorAnimation { duration: Theme.slow } }
                SequentialAnimation on opacity {
                    running: page.engine.active
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
                    onRunningChanged: if (!running) stateDot.opacity = 1
                }
            }
            Label {
                objectName: "sessionStatus"
                text: I18n.t("state." + page.engine.state)
                font.pixelSize: Theme.body; font.weight: Font.DemiBold
            }
        }
        Label {
            x: 22; y: 62
            text: live.running ? I18n.t("cps") : I18n.t("live.target") + " · " + I18n.t("cps")
            color: Theme.muted
            font.pixelSize: Theme.small; font.weight: Font.Medium
        }
        Label {
            id: bigRate
            x: 20; y: 78
            width: parent.width - 40
            property real shown: live.running ? Math.max(0, page.engine.measuredCps) : page.engine.cps
            Behavior on shown { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            text: I18n.rate(shown)
            font.pixelSize: 52; font.weight: Font.DemiBold
            font.letterSpacing: -1.2
            font.features: { "tnum": 1 }
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: 22
            color: live.running ? Theme.ink : Theme.inkSoft
        }
        Sparkline {
            id: spark
            x: 22; y: 150
            width: parent.width - 44; height: 84
            tint: Theme.modeColor(page.engine.mode)
            ceiling: Math.min(page.engine.cps, 1e9)
            Timer {
                interval: 100; repeat: true
                running: live.running
                onTriggered: spark.push(Math.max(0, page.engine.measuredCps))
            }
            Connections {
                target: page.engine
                function onChanged() { if (page.engine.state === "arming" && spark.samples.length) spark.reset(); }
            }
        }
        Column {
            x: 22; y: 254
            width: parent.width - 44
            Repeater {
                model: [
                    { icon: "cursor", k: "live.clicks", v: I18n.number(page.engine.clicks, 0) },
                    { icon: "timer", k: "live.time", v: I18n.duration(page.engine.elapsedSec) },
                    { icon: "pulse", k: "live.average", v: I18n.rate(page.engine.averageCps) },
                    { icon: "target", k: "live.target", v: I18n.rate(page.engine.cps) }
                ]
                Item {
                    required property var modelData
                    required property int index
                    width: parent.width; height: 44
                    Rectangle { width: parent.width; height: 1; color: Theme.hairline; opacity: index ? 0.7 : 0 }
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: modelData.icon; size: 17; color: Theme.muted }
                    Label {
                        x: 28; anchors.verticalCenter: parent.verticalCenter
                        text: I18n.t(modelData.k)
                        color: Theme.muted
                        font.pixelSize: 13
                    }
                    Label {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        text: modelData.v
                        font.pixelSize: 14; font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }
        // Persistent error until dismissed (the island shows it briefly).
        Rectangle {
            id: errorBanner
            objectName: "generalError"
            x: 14; width: parent.width - 28
            anchors.bottom: parent.bottom; anchors.bottomMargin: 14
            height: Math.max(48, errorText.implicitHeight + 24)
            radius: 16
            color: Qt.rgba(1, 0.231, 0.188, 0.10)
            border.width: 1; border.color: Qt.rgba(1, 0.231, 0.188, 0.25)
            readonly property bool shown: page.engine.error !== ""
            // Keep the last message while the banner fades out.
            property string message: ""
            onShownChanged: if (shown) message = I18n.msg(page.engine.error)
            Connections { target: I18n; function onLanguageChanged() { if (errorBanner.shown) errorBanner.message = I18n.msg(page.engine.error); } }
            opacity: shown ? 1 : 0
            visible: opacity > 0
            scale: shown ? 1 : 0.94
            Behavior on opacity { NumberAnimation { duration: Theme.base } }
            Behavior on scale { SpringAnimation { spring: 4; damping: 0.3; epsilon: 0.001 } }
            Icon { x: 12; y: 14; name: "warning"; size: 18; color: Theme.danger }
            Label {
                id: errorText
                x: 38; anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 38 - 40
                text: errorBanner.message
                wrapMode: Text.WordWrap
                color: Theme.ink
                font.pixelSize: Theme.small
            }
            GlassButton {
                objectName: "dismissError"
                kind: "plain"
                anchors.right: parent.right; anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 30; height: 30
                iconName: "x"; iconSize: 14
                Accessible.name: I18n.t("dismiss")
                onClicked: page.engine.dismissError()
            }
        }
    }
}
