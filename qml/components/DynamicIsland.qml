import QtQuick
import QtQuick.Window
import QtQuick.Shapes
import QtQuick.Templates as T
import FakeClicker

// Dynamic Island: one black capsule with a hairline edge that resizes between views; its content
// is clipped to the moving shape. Hover expands it into a control panel with mode, rate and
// start/stop. Size changes are short eased transitions; nothing springs or scales.
Item {
    id: island
    property var engine
    property bool overlay: false
    property bool booting: false
    property bool hidden: false
    property bool pinned: false
    property bool presentsEvents: true
    onPresentsEventsChanged: clearTransient()
    readonly property bool interactive: !overlay && !booting && !hidden

    property string errorText: ""
    property string noticeText: ""
    property string noticeValue: ""
    property string noticeIcon: ""
    // "" plain value, "legit"/"blatant" mode colour, "on"/"off" state pill, "key" key cap.
    property string noticeTone: ""
    property color noticeTint: Theme.islandText
    property bool summaryShown: false
    property real summaryClicks: 0
    property real summaryAverage: -1

    readonly property int mode: engine ? engine.mode : 0
    readonly property string phase: engine ? engine.state : "idle"
    readonly property bool running: phase === "running" || phase === "stopping"
    readonly property bool arming: phase === "arming"
    readonly property color tint: Theme.modeColor(mode)
    readonly property bool expanded: interactive && (hover.hovered || pinned)

    readonly property string view: hidden ? "hidden"
        : booting ? "hidden"
        : expanded ? "expanded"
        : errorText !== "" ? "error"
        : summaryShown ? "summary"
        : noticeText !== "" ? "notice"
        : arming ? "arming"
        : running ? "live"
        : "idle"

    function clearTransient() {
        errorTimer.stop(); noticeTimer.stop(); summaryTimer.stop();
        errorText = ""; noticeText = ""; noticeValue = ""; summaryShown = false;
        pinned = false;
    }
    // One-line notice: profile results and other messages.
    function notify(icon, text, color) {
        if (!presentsEvents) return;
        noticeIcon = icon; noticeText = text; noticeValue = ""; noticeTone = ""; noticeTint = color;
        noticeTimer.restart();
    }
    // A setting changed: what changed (muted) and its new value (bright).
    function inform(icon, label, value, tone) {
        if (!presentsEvents) return;
        const t = tone || "";
        noticeIcon = icon; noticeText = label; noticeValue = value; noticeTone = t;
        noticeTint = t === "legit" ? Theme.legit : t === "blatant" ? Theme.blatant : t === "off" ? Theme.islandMuted : Theme.islandText;
        noticeTimer.restart();
    }
    function showError(text) {
        if (!presentsEvents) return;
        errorText = text;
        errorTimer.restart();
    }

    readonly property bool noticeBoxed: noticeTone === "on" || noticeTone === "off" || noticeTone === "key"
    readonly property real targetWidth: {
        switch (view) {
        case "hidden": return 14;
        // +4: physical-pixel snapping must never cut a label short and trigger its elide.
        case "idle": return Math.max(176, 40 + idleName.implicitWidth + 24 + idleRate.implicitWidth + 4 + idleUnit.implicitWidth + 16 + 4);
        case "arming": return Math.max(216, 40 + armingLabel.implicitWidth + 60 + 4);
        case "live": return Math.max(232, 98 + liveRate.implicitWidth + 4 + liveUnit.implicitWidth + 16 + 4);
        case "expanded": return 456;
        case "notice": return Math.min(460, Math.max(200, 42 + noticeLabel.implicitWidth
                                   + (noticeValue !== "" ? 14 + valueSlot.naturalWidth + (noticeBoxed ? 8 : 16) : 20) + 4));
        case "error": return Math.min(460, Math.max(240, errorLabel.implicitWidth + 64 + 4));
        case "summary": return Math.min(460, Math.max(322, 62 + summaryTotal.implicitWidth + 24 + summaryRateColumn.width + 22));
        }
        return 176;
    }
    readonly property real targetHeight: view === "hidden" ? 14 : view === "expanded" ? 184
        : view === "summary" ? 64 : view === "error" && errorLabel.lineCount > 1 ? 56 : 38

    // Animate only the container geometry, never raster-scale the text.
    readonly property real pixelRatio: Math.max(1, Screen.devicePixelRatio)
    function snap(value) { return Math.round(value * pixelRatio) / pixelRatio; }
    property real animatedWidth: targetWidth
    property real animatedHeight: targetHeight
    width: snap(animatedWidth)
    height: snap(animatedHeight)
    Behavior on animatedWidth { NumberAnimation { duration: island.overlay ? 150 : 200; easing.type: Easing.OutCubic } }
    Behavior on animatedHeight { NumberAnimation { duration: island.overlay ? 150 : 200; easing.type: Easing.OutCubic } }
    opacity: view === "hidden" ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: Theme.base; easing.type: Easing.OutCubic } }

    // Clock is independent of window activation for the passive overlay.
    property real clock: 0
    FrameAnimation {
        running: (Theme.animating || island.overlay) && island.visible && !island.hidden
        onTriggered: island.clock += Math.max(frameTime, 0.001)
    }

    Timer { id: noticeTimer; interval: 1800; onTriggered: { island.noticeText = ""; island.noticeValue = ""; } }
    Timer { id: errorTimer; interval: 4000; onTriggered: island.errorText = "" }
    Timer { id: summaryTimer; interval: 2600; onTriggered: island.summaryShown = false }
    property string previousPhase: "idle"
    property real armedAt: 0
    onPhaseChanged: {
        if (phase === "arming")
            armedAt = clock;
        if (presentsEvents && phase === "idle" && engine && engine.error === "" && engine.clicks > 0
                && (previousPhase === "running" || previousPhase === "stopping")) {
            summaryClicks = engine.clicks;
            summaryAverage = engine.averageCps;
            summaryShown = true;
            summaryTimer.restart();
        }
        previousPhase = phase;
    }
    readonly property real armProgress: {
        if (!arming || !engine) return 0;
        const total = Math.max(1, engine.launchDelaySec);
        return Math.max(0, Math.min(1, (clock - armedAt) / total));
    }

    HoverHandler { id: hover; enabled: island.interactive }
    // A click only clears transient views; the panel follows the pointer and collapses when it
    // leaves, even after a click. `pinned` is kept for scripted tours.
    TapHandler {
        enabled: island.interactive
        onTapped: {
            island.errorText = "";
            island.summaryShown = false;
        }
    }
    Connections {
        target: hover
        function onHoveredChanged() { if (!hover.hovered) island.pinned = false; }
    }
    onInteractiveChanged: if (!interactive) pinned = false

    // A stable opaque capsule: no cross-window texture sampling or shader rims.
    Rectangle {
        id: capsule
        anchors.fill: parent
        radius: Math.min(height / 2, 30)
        antialiasing: true
        color: Theme.island
        border.width: 1
        border.color: Theme.islandEdge
    }

    // Direct scene-graph content: no FBO mask, no bilinear resampling of glyphs.
    // Text is inset from the rounded corners; rectangular clipping is only a transition guard.
    Item {
        id: canvas
        anchors.fill: parent
        clip: true
        visible: width >= 80 && height >= 24
        Item {
            id: frame
            anchors.fill: parent

            // idle
            Face {
                on: island.view === "idle"
                ModeDot { mode: island.mode; x: 7; anchors.verticalCenter: parent.verticalCenter }
                IslandLabel {
                    id: idleName
                    x: 40; anchors.verticalCenter: parent.verticalCenter
                    text: I18n.t(island.mode === 1 ? "mode.blatant" : "mode.legit")
                    color: Theme.islandText
                    font.pixelSize: 13; font.weight: Font.DemiBold
                }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Num { id: idleRate; text: island.engine ? I18n.rate(island.engine.cps) : ""; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                    Unit { id: idleUnit; text: I18n.t("cps"); anchors.verticalCenter: parent.verticalCenter }
                }
            }
            // arming: the ring empties continuously over the countdown
            Face {
                on: island.view === "arming"
                CountdownRing { x: 7; anchors.verticalCenter: parent.verticalCenter; size: 24; progress: island.armProgress; count: island.engine ? island.engine.countdown : 0 }
                IslandLabel {
                    id: armingLabel
                    x: 40; anchors.verticalCenter: parent.verticalCenter
                    text: I18n.t("state.arming")
                    color: Theme.islandText
                    font.pixelSize: 13; font.weight: Font.DemiBold
                }
                ModeDot { mode: island.mode; size: 20; anchors.right: parent.right; anchors.rightMargin: 9; anchors.verticalCenter: parent.verticalCenter }
            }
            // live
            Face {
                on: island.view === "live"
                ModeDot { mode: island.mode; x: 7; anchors.verticalCenter: parent.verticalCenter }
                Waveform { x: 40; anchors.verticalCenter: parent.verticalCenter; bars: 6; height: 18; clock: island.clock; rate: island.shownRate; tint: island.tint }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Num { id: liveRate; text: I18n.rate(island.shownRate); font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
                    Unit { id: liveUnit; text: I18n.t("cps"); anchors.verticalCenter: parent.verticalCenter }
                }
            }
            // expanded control panel
            Face {
                on: island.view === "expanded"
                // mode switch
                Item {
                    id: modeSwitch
                    x: 16; y: 16
                    width: 214; height: 34
                    enabled: island.engine && !island.engine.active
                    opacity: enabled ? 1 : 0.45
                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Theme.islandControl
                        border.width: 1
                        border.color: Theme.islandEdge
                    }
                    Rectangle {
                        x: 3 + island.mode * parent.width / 2
                        Behavior on x { NumberAnimation { duration: Theme.base; easing.type: Easing.OutCubic } }
                        y: 3
                        width: parent.width / 2 - 6; height: parent.height - 6
                        radius: height / 2
                        color: "#2E2E2E"
                    }
                    Row {
                        anchors.fill: parent
                        Repeater {
                            model: [{ icon: "hand", key: "mode.legit" }, { icon: "bolt", key: "mode.blatant" }]
                            T.AbstractButton {
                                id: modeButton
                                required property int index
                                required property var modelData
                                objectName: "islandMode" + index
                                width: modeSwitch.width / 2; height: modeSwitch.height
                                hoverEnabled: true
                                Accessible.name: I18n.t(modelData.key)
                                onClicked: if (island.engine && !selected) { sounds.play("select"); island.engine.mode = index; }
                                readonly property bool selected: island.mode === index
                                contentItem: Item {
                                    Row {
                                        spacing: 6
                                        anchors.centerIn: parent
                                        Icon { name: modeButton.modelData.icon; size: 14; stroke: 2; color: modeButton.selected ? Theme.modeColor(modeButton.index) : Theme.islandMuted; anchors.verticalCenter: parent.verticalCenter }
                                        IslandLabel { text: I18n.t(modeButton.modelData.key); color: modeButton.selected || modeButton.hovered ? Theme.islandText : Theme.islandMuted; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                }
                                background: Item {}
                            }
                        }
                    }
                }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 20
                    y: 26
                    spacing: 7
                    Rectangle {
                        width: 7; height: 7; radius: 3.5
                        anchors.verticalCenter: parent.verticalCenter
                        color: island.arming ? Theme.islandText : island.running ? island.tint : Theme.islandMuted
                        opacity: island.running || island.arming ? 0.55 + 0.45 * Math.abs(Math.sin(island.clock * 2.4)) : 1
                    }
                    IslandLabel {
                        text: I18n.t("state." + island.phase)
                        color: Theme.islandMuted
                        font.pixelSize: 12; font.weight: Font.Medium
                    }
                }
                // value
                Item {
                    id: valueBlock
                    x: 20; y: 62
                    width: Math.max(80, action.x - x - (island.running ? 110 : 62))
                    height: 66
                    Num {
                        id: bigValue
                        objectName: "islandBigValue"
                        width: Math.max(40, valueBlock.width - valueUnit.implicitWidth - 6)
                        height: valueBlock.height
                        verticalAlignment: Text.AlignVCenter
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: 18
                        elide: Text.ElideRight
                        text: island.arming ? (island.engine ? island.engine.countdown : "") : island.running ? I18n.rate(island.shownRate) : island.engine ? I18n.rate(island.engine.cps) : ""
                        font.pixelSize: 46
                        font.weight: Font.Bold
                        font.letterSpacing: -1.5
                        color: Theme.islandText
                    }
                    Unit {
                        id: valueUnit
                        x: Math.min(bigValue.contentWidth, bigValue.width) + 6
                        anchors.baseline: bigValue.baseline
                        text: island.arming ? I18n.t("sec") : I18n.t("cps")
                        font.pixelSize: 12
                    }
                }
                // detail line
                Row {
                    id: detailLine
                    x: 20; y: 136
                    width: action.x - x - 16
                    clip: true
                    spacing: 8
                    visible: island.running
                    IslandLabel {
                        width: Math.max(20, Math.min(implicitWidth, detailLine.width - detailUnit.implicitWidth - detailSeparator.implicitWidth - detailTime.implicitWidth - 24))
                        elide: Text.ElideRight
                        text: island.engine ? I18n.number(island.engine.clicks, 0) : ""
                        color: Theme.islandText; font.pixelSize: 13; font.weight: Font.DemiBold; font.features: { "tnum": 1 }
                    }
                    IslandLabel { id: detailUnit; text: I18n.t("live.clicks").toLocaleLowerCase(); color: Theme.islandMuted; font.pixelSize: 13 }
                    IslandLabel { id: detailSeparator; text: "·"; color: Theme.islandMuted; font.pixelSize: 13 }
                    IslandLabel { id: detailTime; text: island.engine ? I18n.duration(island.engine.elapsedSec) : ""; color: Theme.islandText; font.pixelSize: 13; font.weight: Font.DemiBold; font.features: { "tnum": 1 } }
                }
                // rate adjust (idle) or live waveform (running)
                Column {
                    x: action.x - 50; y: 76
                    spacing: 8
                    visible: !island.running && !island.arming
                    DarkRound { objectName: "islandPlus"; glyph: "plus"; enabled: island.engine && !island.engine.active; onClicked: { sounds.play("step"); island.nudge(true); } }
                    DarkRound { objectName: "islandMinus"; glyph: "minus"; enabled: island.engine && !island.engine.active && island.engine.cps > 1; onClicked: { sounds.play("step"); island.nudge(false); } }
                }
                Waveform { visible: island.running; x: action.x - 96; y: 104; bars: 9; height: 34; clock: island.clock; rate: island.shownRate; tint: island.tint }
                // start / cancel / stop
                T.AbstractButton {
                    id: action
                    objectName: "islandAction"
                    anchors.right: parent.right; anchors.rightMargin: 18
                    y: 86
                    width: 72; height: 72
                    hoverEnabled: true
                    enabled: island.engine && (island.engine.available || island.engine.active)
                    Accessible.name: island.running ? I18n.t("stop") : island.arming ? I18n.t("cancel") : I18n.t("start")
                    onClicked: island.engine.toggle()
                    opacity: enabled ? 1 : 0.4
                    background: Rectangle {
                        radius: width / 2
                        color: island.running ? (action.hovered ? "#E8141A" : Theme.blatant)
                             : island.arming ? Theme.islandControl
                             : action.pressed ? "#D4D4D4" : action.hovered ? "#E8E8E8" : Theme.islandText
                        border.width: island.arming ? 1 : 0
                        border.color: Theme.islandEdge
                        CountdownRing {
                            anchors.centerIn: parent
                            visible: island.arming
                            size: 66; thickness: 3
                            progress: island.armProgress
                            count: -1
                        }
                    }
                    contentItem: Item {
                        Icon {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: !island.running && !island.arming ? 2 : 0
                            name: island.running ? "stop" : island.arming ? "x" : "play"
                            size: 28; stroke: 2.4
                            color: island.running || island.arming ? "#FFFFFF" : "#000000"
                        }
                    }
                }
            }
            // notice: what changed, then the new value
            Face {
                on: island.view === "notice"
                Icon { x: 14; anchors.verticalCenter: parent.verticalCenter; name: island.noticeIcon; size: 18; stroke: 2; color: island.noticeTint }
                IslandLabel {
                    id: noticeLabel
                    x: 42; anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 360, Math.max(1, island.width - x
                                    - (island.noticeValue !== "" ? valueSlot.width + 14 + valueSlot.anchors.rightMargin : 20)))
                    elide: Text.ElideRight
                    text: island.noticeText
                    color: island.noticeValue !== "" ? Theme.islandMuted : island.noticeTint
                    font.pixelSize: 13; font.weight: island.noticeValue !== "" ? Font.Medium : Font.DemiBold
                }
                Rectangle {
                    id: valueSlot
                    visible: island.noticeValue !== ""
                    readonly property real naturalWidth: Math.min(200, valueText.implicitWidth + (island.noticeBoxed ? 18 : 0))
                    anchors.right: parent.right; anchors.rightMargin: island.noticeBoxed ? 8 : 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(naturalWidth, Math.max(40, island.width - 42 - 14 - 60 - anchors.rightMargin))
                    height: island.noticeBoxed ? 22 : valueText.implicitHeight
                    radius: island.noticeTone === "key" ? 6 : height / 2
                    color: island.noticeTone === "on" ? Theme.islandText : island.noticeTone === "key" ? Theme.islandControl : "transparent"
                    border.width: island.noticeTone === "off" || island.noticeTone === "key" ? 1 : 0
                    border.color: island.noticeTone === "key" ? "#363636" : "#3A3A3A"
                    IslandLabel {
                        id: valueText
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, valueSlot.width - (island.noticeBoxed ? 18 : 0))
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: island.noticeValue
                        color: island.noticeTone === "on" ? "#000000"
                             : island.noticeTone === "off" ? Theme.islandMuted
                             : island.noticeTone === "legit" ? Theme.legit
                             : island.noticeTone === "blatant" ? Theme.dangerText
                             : Theme.islandText
                        font.family: island.noticeBoxed ? Theme.mono : Theme.sans
                        font.pixelSize: island.noticeBoxed ? 11 : 13
                        font.weight: Font.DemiBold
                        font.capitalization: island.noticeTone === "on" || island.noticeTone === "off" ? Font.AllUppercase : Font.MixedCase
                        font.letterSpacing: island.noticeTone === "on" || island.noticeTone === "off" ? 0.8 : 0
                        font.features: { "tnum": 1 }
                    }
                }
            }
            // error
            Face {
                on: island.view === "error"
                Icon { x: 14; anchors.verticalCenter: parent.verticalCenter; name: "warning"; size: 18; stroke: 2; color: Theme.dangerText }
                IslandLabel {
                    id: errorLabel
                    x: 42; anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 380, Math.max(1, island.width - x - 22))
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    text: island.errorText
                    color: Theme.islandText
                    font.pixelSize: 13; font.weight: Font.Medium
                }
            }
            // summary
            Face {
                on: island.view === "summary"
                Rectangle {
                    x: 15; anchors.verticalCenter: parent.verticalCenter
                    width: 34; height: 34; radius: 17
                    color: island.tint
                    Icon { anchors.centerIn: parent; name: "check"; size: 18; stroke: 2.4; color: "#FFFFFF" }
                }
                Column {
                    x: 62; anchors.verticalCenter: parent.verticalCenter
                    Num {
                        id: summaryTotal
                        objectName: "islandSummaryTotal"
                        width: Math.max(40, Math.min(implicitWidth, island.width - 62 - 24 - summaryRateColumn.width - 22))
                        elide: Text.ElideRight
                        text: I18n.number(island.summaryClicks, 0); font.pixelSize: 20; font.weight: Font.Bold
                    }
                    IslandLabel { text: I18n.t("live.clicks"); color: Theme.islandMuted; font.pixelSize: 11 }
                }
                Column {
                    id: summaryRateColumn
                    anchors.right: parent.right; anchors.rightMargin: 22
                    anchors.verticalCenter: parent.verticalCenter
                    Row {
                        anchors.right: parent.right
                        spacing: 4
                        Num { id: avg; text: I18n.rate(island.summaryAverage); font.pixelSize: 20; font.weight: Font.Bold }
                        Unit { text: I18n.t("cps"); anchors.baseline: avg.baseline }
                    }
                    IslandLabel { anchors.right: parent.right; text: I18n.t("live.average"); color: Theme.islandMuted; font.pixelSize: 11 }
                }
            }
        }
    }

    // Display measured samples directly: do not reshape number strings every animation frame.
    property real shownRate: engine && engine.measuredCps >= 0 ? engine.measuredCps : 0

    function nudge(up) {
        if (!engine) return;
        const v = engine.cps;
        const base = up ? v : v - 0.0001;
        const s = base < 20 ? 1 : base < 100 ? 5 : base < 500 ? 25 : base < 2000 ? 100 : base < 10000 ? 500 : 1000;
        const next = up ? Math.floor(v / s) * s + s : Math.ceil(v / s) * s - s;
        if (next > 0) engine.cps = next;
    }

    // Inline components have their own id scope; island values are passed in explicitly.
    component Face: Item {
        id: face
        property bool on: false
        anchors.fill: parent
        opacity: on ? 1 : 0
        // Hide the outgoing face immediately; overlapping text must never ghost/double.
        visible: on
        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }
    // Native grayscale bitmap glyphs: no analytic-curve shader or distance-field contours.
    component IslandLabel: Label {
        renderType: Text.NativeRendering
        font.hintingPreference: Font.PreferFullHinting
        antialiasing: true
    }
    component Num: IslandLabel {
        color: Theme.islandText
        font.weight: Font.DemiBold
        font.features: { "tnum": 1 }
    }
    component Unit: IslandLabel {
        color: Theme.islandMuted
        font.family: Theme.mono
        font.pixelSize: 10
        font.weight: Font.Medium
    }
    component ModeDot: Rectangle {
        property real size: 24
        property int mode: 0
        width: size; height: size; radius: size / 2
        color: Theme.modeColor(mode)
        Behavior on color { ColorAnimation { duration: Theme.base } }
        Icon { anchors.centerIn: parent; name: parent.mode === 1 ? "bolt" : "hand"; size: parent.size * 0.62; stroke: 2; color: "#FFFFFF" }
    }
    component CountdownRing: Item {
        id: ring
        property real size: 24
        property real thickness: 2.5
        property real progress: 0
        property int count: 0
        width: size; height: size
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Qt.rgba(1, 1, 1, 0.18); strokeWidth: ring.thickness; fillColor: "transparent"
                PathAngleArc { centerX: ring.size / 2; centerY: ring.size / 2; radiusX: ring.size / 2 - ring.thickness; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
            }
            ShapePath {
                strokeColor: Theme.islandText; strokeWidth: ring.thickness; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                PathAngleArc { centerX: ring.size / 2; centerY: ring.size / 2; radiusX: ring.size / 2 - ring.thickness; radiusY: radiusX; startAngle: -90; sweepAngle: -360 * (1 - ring.progress) }
            }
        }
        IslandLabel {
            anchors.centerIn: parent
            visible: ring.count >= 0
            text: ring.count
            color: Theme.islandText
            font.pixelSize: 11; font.weight: Font.Bold
            font.features: { "tnum": 1 }
        }
    }
    // Activity bars follow continuous sine phases; their speed follows the click rate.
    component Waveform: Row {
        id: wave
        property int bars: 6
        property real clock: 0
        property real rate: 0
        property color tint: "white"
        spacing: 3
        Repeater {
            model: wave.bars
            Rectangle {
                required property int index
                readonly property real speed: 5 + Math.min(wave.rate, 60) / 6
                readonly property real level: 0.5 + 0.5 * Math.sin(wave.clock * speed * (0.8 + 0.13 * index) + index * 1.7)
                width: 3; radius: 1.5
                anchors.verticalCenter: parent.verticalCenter
                height: 4 + (wave.height - 4) * (0.15 + 0.85 * level)
                color: wave.tint
            }
        }
    }
    component DarkRound: T.AbstractButton {
        id: round
        property string glyph
        width: 36; height: 36
        hoverEnabled: true
        autoRepeat: true
        Accessible.name: glyph === "plus" ? "+" : "−"
        opacity: enabled ? 1 : 0.35
        background: Rectangle {
            radius: 18
            color: round.pressed ? "#333333" : round.hovered ? Theme.islandControlHover : Theme.islandControl
            border.width: 1
            border.color: Theme.islandEdge
        }
        contentItem: Item { Icon { anchors.centerIn: parent; name: round.glyph; size: 15; stroke: 2.2; color: Theme.islandText } }
    }
}
