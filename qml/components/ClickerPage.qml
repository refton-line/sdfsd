import QtQuick
import QtQuick.Templates as T
import CClicker

Item {
    id: page
    property var engine
    readonly property bool locked: engine.active
    readonly property bool blatant: engine.mode === 1
    readonly property var presets: blatant ? [20, 50, 100, 250, 500, 1000] : [8, 10, 12, 14, 16, 20]
    readonly property real gap: Theme.gap
    readonly property real rightWidth: Theme.isGlass ? 300 : 286
    readonly property real leftWidth: width - rightWidth - gap

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
    Card {
        id: modeCard
        title: Theme.isGlass ? "" : I18n.t("section.mode")
        width: page.leftWidth
        height: headerHeight + 96
        Item {
            id: modes
            x: 8; y: 8
            width: parent.width - 16; height: parent.height - 16
            readonly property real cell: (width - 8) / 2
            readonly property real target: page.engine.mode * (cell + 8)
            property real lensX: target
            Behavior on lensX { enabled: Theme.isGlass; SpringAnimation { spring: Theme.springStiff; damping: Theme.springDamp; epsilon: 0.05 } }
            readonly property real travel: Math.min(70, Math.abs(target - lensX) * 0.35)
            Rectangle {
                visible: Theme.isGlass
                anchors.fill: parent
                radius: 24
                color: Theme.well
            }
            Surface {
                visible: Theme.isGlass
                x: modes.lensX + 3 - modes.travel / 2
                y: 3 + modes.travel * 0.04
                width: modes.cell - 6 + modes.travel
                height: modes.height - 6 - modes.travel * 0.08
                radius: 21
                elevation: 0.8
                tintAlpha: 0.7 - 0.45 * Math.min(1, modes.travel / 40)
                magnify: 0.05 * Math.min(1, modes.travel / 40)
            }
            Repeater {
                model: [
                    { icon: "hand", title: "mode.legit", sub: "mode.legit.sub" },
                    { icon: "bolt", title: "mode.blatant", sub: "mode.blatant.sub" }
                ]
                T.AbstractButton {
                    id: tile
                    required property int index
                    required property var modelData
                    objectName: "mode" + index
                    x: index * (modes.cell + 8)
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
                    background: Rectangle {
                        radius: Theme.isGlass ? 21 : 10
                        color: Theme.isGlass ? (!tile.selected && tile.hovered ? Qt.rgba(1, 1, 1, 0.3) : "transparent")
                                             : tile.selected ? Theme.accentSoft : tile.hovered ? Theme.fill : "transparent"
                        border.width: tile.visualFocus ? 2 : !Theme.isGlass && tile.selected ? 2 : 0
                        border.color: tile.visualFocus ? Theme.focusRing : "#007aff"
                        Behavior on color { ColorAnimation { duration: Theme.isGlass ? Theme.fast : 200 } }
                    }
                    contentItem: Item {
                        scale: Theme.isGlass && tile.pressed ? 0.96 : 1
                        opacity: !Theme.isGlass && tile.pressed ? 0.6 : 1
                        Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
                        Rectangle {
                            id: badge
                            x: 16; anchors.verticalCenter: parent.verticalCenter
                            width: 46; height: 46; radius: Theme.isGlass ? 15 : 10
                            color: tile.selected ? Theme.modeColor(tile.index) : Theme.isGlass ? Theme.well : "#8e8e93"
                            Behavior on color { ColorAnimation { duration: Theme.slow } }
                            Icon {
                                anchors.centerIn: parent
                                name: tile.modelData.icon
                                size: 25; stroke: 2
                                color: tile.selected || !Theme.isGlass ? "#ffffff" : Theme.muted
                                rotation: tile.selected ? 0 : -10
                                Behavior on rotation { SpringAnimation { spring: 4; damping: 0.25 } }
                            }
                        }
                        Column {
                            anchors.left: badge.right; anchors.leftMargin: 14
                            anchors.right: parent.right; anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            Label {
                                text: I18n.t(tile.modelData.title)
                                font.pixelSize: 17
                                font.weight: Font.DemiBold
                                color: !Theme.isGlass && tile.selected ? "#007aff" : Theme.ink
                            }
                            Label {
                                width: parent.width
                                elide: Text.ElideRight
                                text: I18n.t(tile.modelData.sub)
                                font.pixelSize: Theme.small
                                color: Theme.muted
                            }
                        }
                        Rectangle {
                            visible: !Theme.isGlass
                            anchors.right: parent.right; anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22; height: 22; radius: 11
                            color: tile.selected ? "#007aff" : "transparent"
                            border.width: tile.selected ? 0 : 1.5
                            border.color: "#c7c7cc"
                            Icon { anchors.centerIn: parent; visible: tile.selected; name: "check"; size: 13; stroke: 2.6; color: "#ffffff" }
                        }
                    }
                }
            }
        }
    }

    // ── Rate ────────────────────────────────────────────────────────────────
    Card {
        id: rateCard
        title: Theme.isGlass ? "" : I18n.t("cps.title")
        y: modeCard.height + page.gap
        width: page.leftWidth
        height: page.height - modeCard.height - optionsCard.height - 2 * page.gap
        Item {
            id: rateRow
            x: rateCard.pad; y: Math.max(8, (parent.height - 76 - 50) / 2)
            width: parent.width - 2 * rateCard.pad; height: 76
            TextInput {
                id: rateInput
                objectName: "cpsField"
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(60, contentWidth + 4)
                readOnly: page.locked
                text: I18n.rate(page.engine.cps)
                color: Theme.ink
                font.family: Theme.sans
                font.pixelSize: Theme.isGlass ? 64 : 54
                font.weight: Theme.isGlass ? Font.DemiBold : Font.Bold
                font.letterSpacing: -1.6
                font.features: { "tnum": 1 }
                selectByMouse: true
                selectionColor: Theme.focusRing
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
                property real lastCps: -1
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
                SequentialAnimation {
                    id: popAnim
                    NumberAnimation { target: rateInput; property: "pop"; to: Theme.isGlass ? 1.07 : 1.03; duration: 80; easing.type: Easing.OutQuad }
                    SpringAnimation { target: rateInput; property: "pop"; to: 1; spring: 4; damping: Theme.isGlass ? 0.28 : 0.6; epsilon: 0.001 }
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
                AppButton {
                    objectName: "cpsMinus"
                    width: 48; height: 48
                    iconName: "minus"; iconSize: 20
                    Accessible.name: "−"
                    enabled: !page.locked && page.engine.cps > 1
                    autoRepeat: true
                    onClicked: page.nudge(false)
                }
                AppButton {
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
            x: rateCard.pad
            anchors.bottom: parent.bottom; anchors.bottomMargin: Theme.isGlass ? 18 : 14
            spacing: 8
            Repeater {
                model: page.presets
                T.AbstractButton {
                    id: chip
                    required property int index
                    required property int modelData
                    objectName: "preset" + modelData
                    readonly property bool selected: Math.abs(page.engine.cps - modelData) < 0.001
                    height: Theme.isGlass ? 34 : 30
                    width: Math.max(Theme.isGlass ? 54 : 50, chipText.implicitWidth + 26)
                    hoverEnabled: true
                    focusPolicy: Qt.StrongFocus
                    enabled: !page.locked
                    opacity: enabled ? 1 : 0.45
                    Accessible.name: modelData + " " + I18n.t("cps")
                    onClicked: page.engine.cps = modelData
                    scale: Theme.isGlass && pressed ? 0.9 : 1
                    Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
                    property real arrive: 1
                    transform: Translate { y: (1 - chip.arrive) * -10 }
                    Connections {
                        target: page
                        function onBlatantChanged() { chipIn.restart(); }
                    }
                    SequentialAnimation {
                        id: chipIn
                        PropertyAction { target: chip; property: "arrive"; value: 0 }
                        PauseAnimation { duration: chip.index * 30 }
                        SpringAnimation { target: chip; property: "arrive"; to: 1; spring: 4; damping: 0.3; epsilon: 0.002 }
                    }
                    background: Rectangle {
                        radius: Theme.isGlass ? height / 2 : 8
                        color: chip.selected ? Theme.accent : chip.hovered ? (Theme.isGlass ? Qt.rgba(1, 1, 1, 0.75) : Theme.fillStrong) : Theme.well
                        Behavior on color { ColorAnimation { duration: Theme.base } }
                        border.width: chip.visualFocus ? 2 : 0
                        border.color: Theme.focusRing
                    }
                    contentItem: Label {
                        id: chipText
                        text: I18n.number(chip.modelData, 0)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: chip.selected ? "#ffffff" : Theme.isGlass ? Theme.inkSoft : "#007aff"
                        font.pixelSize: 13; font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                        opacity: chip.arrive
                    }
                }
            }
        }
    }

    // ── Options ─────────────────────────────────────────────────────────────
    Card {
        id: optionsCard
        title: Theme.isGlass ? "" : I18n.t("section.options")
        y: page.height - height
        width: page.leftWidth
        height: headerHeight + options.height + (Theme.isGlass ? 12 : 0)
        Column {
            id: options
            y: Theme.isGlass ? 6 : 0
            width: parent.width
            Cell {
                icon: "mouse"; title: I18n.t("button")
                SegmentedControl {
                    objectName: "buttonSegment"
                    anchors.verticalCenter: parent.verticalCenter
                    width: 270
                    enabled: !page.locked
                    options: [{ text: I18n.t("button.0") }, { text: I18n.t("button.1") }, { text: I18n.t("button.2") }]
                    currentIndex: page.engine.mouseButton
                    onActivated: index => page.engine.mouseButton = index
                }
            }
            // Legit variance or Blatant hold, crossfading in place.
            Item {
                width: options.width; height: Theme.rowHeight
                Cell {
                    icon: "wave"; title: I18n.t("variance")
                    opacity: page.blatant ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Theme.base } }
                    SegmentedControl {
                        objectName: "varianceSegment"
                        anchors.verticalCenter: parent.verticalCenter
                        width: 270
                        enabled: !page.locked && !page.blatant
                        options: [{ text: I18n.t("variance.0") }, { text: I18n.t("variance.1") }, { text: I18n.t("variance.2") }]
                        currentIndex: page.engine.variance
                        onActivated: index => page.engine.variance = index
                    }
                }
                Cell {
                    icon: "timer"; title: I18n.t("hold")
                    opacity: page.blatant ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Theme.base } }
                    Stepper {
                        objectName: "holdField"
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.isGlass ? 180 : 210
                        enabled: !page.locked && page.blatant
                        from: 0
                        to: Math.max(0, Math.min(1000, Math.ceil(1000 / page.engine.cps) - 1))
                        value: page.engine.holdMs
                        unit: I18n.t("ms")
                        zeroText: I18n.t("hold.instant")
                        onValueModified: v => page.engine.holdMs = v
                    }
                }
            }
            // Glass: both limits on one row. Solid: one row per limit.
            Cell {
                visible: Theme.isGlass
                icon: "hourglass"; title: I18n.t("limits")
                last: true
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Stepper {
                        objectName: "durationField"
                        width: 146
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
                        width: 146
                        enabled: !page.locked
                        from: 0; to: 1e12; step: 100
                        value: page.engine.countLimit
                        zeroText: "∞"
                        Accessible.name: I18n.t("limit.clicks")
                        onValueModified: v => page.engine.countLimit = v
                    }
                }
            }
            Cell {
                visible: !Theme.isGlass
                icon: "hourglass"; title: I18n.t("limit.time")
                Stepper {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 210
                    enabled: !page.locked
                    from: 0; to: 86400; step: 5
                    value: page.engine.durationSec
                    unit: I18n.t("sec")
                    zeroText: "∞"
                    onValueModified: v => page.engine.durationSec = v
                }
            }
            Cell {
                visible: !Theme.isGlass
                icon: "cursor"; title: I18n.t("limit.clicks")
                last: true
                Stepper {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 210
                    enabled: !page.locked
                    from: 0; to: 1e12; step: 100
                    value: page.engine.countLimit
                    zeroText: "∞"
                    onValueModified: v => page.engine.countLimit = v
                }
            }
        }
    }

    // ── Session ─────────────────────────────────────────────────────────────
    Card {
        id: live
        title: Theme.isGlass ? "" : I18n.t("section.session")
        x: page.leftWidth + page.gap
        width: page.rightWidth
        height: page.height
        readonly property bool running: page.engine.state === "running" || page.engine.state === "stopping"
        readonly property color stateColor: page.engine.state === "arming" ? Theme.arming : running ? Theme.modeColor(page.engine.mode) : Theme.faint

        Row {
            x: live.pad + 2; y: Theme.isGlass ? 22 : 18
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
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: live.pad
            y: Theme.isGlass ? 16 : 12
            height: 26; radius: Theme.isGlass ? 13 : 7
            width: modeTag.implicitWidth + 34
            color: Qt.alpha(Theme.modeColor(page.engine.mode), 0.14)
            Behavior on color { ColorAnimation { duration: Theme.slow } }
            Icon { x: 9; anchors.verticalCenter: parent.verticalCenter; name: page.blatant ? "bolt" : "hand"; size: 13; stroke: 2; color: Theme.modeColor(page.engine.mode) }
            Label {
                id: modeTag
                x: 26; anchors.verticalCenter: parent.verticalCenter
                text: I18n.t(page.blatant ? "mode.blatant" : "mode.legit")
                color: Qt.darker(Theme.modeColor(page.engine.mode), 1.25)
                font.pixelSize: 12; font.weight: Font.DemiBold
            }
        }
        Label {
            x: live.pad + 2; y: Theme.isGlass ? 64 : 56
            text: live.running ? I18n.t("cps") : I18n.t("live.target") + " · " + I18n.t("cps")
            color: Theme.muted
            font.pixelSize: Theme.small; font.weight: Font.Medium
        }
        Label {
            id: bigRate
            x: live.pad; y: Theme.isGlass ? 78 : 70
            width: parent.width - 2 * live.pad
            property real shown: live.running ? Math.max(0, page.engine.measuredCps) : page.engine.cps
            Behavior on shown { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            text: I18n.rate(shown)
            font.pixelSize: 52; font.weight: Theme.isGlass ? Font.DemiBold : Font.Bold
            font.letterSpacing: -1.2
            font.features: { "tnum": 1 }
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: 22
            color: live.running ? Theme.ink : Theme.inkSoft
        }
        Sparkline {
            id: spark
            x: live.pad; y: bigRate.y + 70
            width: parent.width - 2 * live.pad; height: 70
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
            x: live.pad; y: spark.y + spark.height + 12
            width: parent.width - 2 * live.pad
            Repeater {
                model: [
                    { icon: "cursor", k: "live.clicks", v: I18n.number(page.engine.clicks, 0) },
                    { icon: "timer", k: "live.time", v: I18n.duration(page.engine.elapsedSec) },
                    { icon: "pulse", k: "live.average", v: I18n.rate(page.engine.averageCps) }
                ]
                Item {
                    required property var modelData
                    required property int index
                    width: parent.width; height: 38
                    Rectangle { width: parent.width; height: 1; color: Theme.separator; visible: index > 0 }
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: modelData.icon; size: 16; color: Theme.muted }
                    Label {
                        x: 26; anchors.verticalCenter: parent.verticalCenter
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
            x: 12; width: parent.width - 24
            anchors.bottom: startButton.top; anchors.bottomMargin: 10
            height: Math.max(46, errorText.implicitHeight + 22)
            radius: Theme.isGlass ? 16 : 10
            color: Qt.rgba(1, 0.231, 0.188, 0.10)
            readonly property bool shown: page.engine.error !== ""
            property string message: ""
            onShownChanged: if (shown) message = I18n.msg(page.engine.error)
            Connections { target: I18n; function onLanguageChanged() { if (errorBanner.shown) errorBanner.message = I18n.msg(page.engine.error); } }
            opacity: shown ? 1 : 0
            visible: opacity > 0
            scale: shown ? 1 : 0.94
            Behavior on opacity { NumberAnimation { duration: Theme.base } }
            Behavior on scale { SpringAnimation { spring: 4; damping: 0.3; epsilon: 0.001 } }
            Icon { x: 12; anchors.verticalCenter: parent.verticalCenter; name: "warning"; size: 17; color: Theme.danger }
            Label {
                id: errorText
                x: 38; anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 38 - 38
                text: errorBanner.message
                wrapMode: Text.WordWrap
                color: Theme.ink
                font.pixelSize: Theme.small
            }
            AppButton {
                objectName: "dismissError"
                kind: "plain"
                anchors.right: parent.right; anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 28; height: 28
                iconName: "x"; iconSize: 13
                Accessible.name: I18n.t("dismiss")
                onClicked: page.engine.dismissError()
            }
        }
        // Start / countdown / stop
        T.AbstractButton {
            id: startButton
            objectName: "startButton"
            x: 12; width: parent.width - 24; height: 56
            anchors.bottom: parent.bottom; anchors.bottomMargin: 12
            hoverEnabled: true
            focusPolicy: Qt.StrongFocus
            enabled: page.engine.available || page.engine.active
            readonly property string phase: page.engine.state
            readonly property bool armed: phase === "arming"
            readonly property bool live: phase === "running" || phase === "stopping"
            Accessible.name: armed ? I18n.t("cancel") : live ? I18n.t("stop") : I18n.t("start")
            onClicked: page.engine.toggle()
            scale: Theme.isGlass ? (pressed ? 0.96 : hovered ? 1.015 : 1) : 1
            Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
            opacity: !enabled ? 0.4 : !Theme.isGlass && pressed ? 0.7 : 1
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
                radius: Theme.isGlass ? height / 2 : 12
                color: startButton.live ? Theme.modeColor(page.engine.mode) : startButton.armed ? "#2c2c2e"
                     : Theme.isGlass ? (startButton.hovered ? "#2c2c2e" : Theme.ink) : "#007aff"
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
                    visible: Theme.isGlass
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.2) }
                        GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0) }
                    }
                }
                Rectangle {
                    anchors.fill: parent; anchors.margins: -4
                    radius: Theme.isGlass ? height / 2 : 15
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
                    anchors.right: parent.right; anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    height: 26; radius: 8
                    width: keyText.implicitWidth + 16
                    color: Qt.rgba(1, 1, 1, 0.18)
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
}
