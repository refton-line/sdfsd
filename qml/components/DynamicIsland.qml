import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Shapes
import QtQuick.Templates as T
import LightClicker

// iPhone-style Dynamic Island. One black capsule morphs on springs, and its content is clipped
// to the moving shape. Hover expands it at once into a control panel with mode, rate and
// start/stop. Continuous motion (waveform, countdown ring, pulse) runs per frame and never
// steps or pauses.
Item {
    id: island
    property var engine
    property bool overlay: false
    property bool booting: false
    property bool hidden: false
    property bool pinned: false
    readonly property bool interactive: !overlay && !booting && !hidden

    property string errorText: ""
    property string noticeText: ""
    property string noticeIcon: ""
    property color noticeTint: Theme.islandText
    property bool summaryShown: false
    property real summaryClicks: 0
    property real summaryAverage: -1

    readonly property int mode: engine ? engine.mode : 0
    readonly property string phase: engine ? engine.state : "idle"
    readonly property bool running: phase === "running" || phase === "stopping"
    readonly property bool arming: phase === "arming"
    readonly property color tint: Theme.modeBright(mode)
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

    function notify(icon, text, color) {
        noticeIcon = icon; noticeText = text; noticeTint = color;
        noticeTimer.restart();
    }
    function showError(text) {
        errorText = text;
        errorTimer.restart();
    }

    readonly property real targetWidth: {
        switch (view) {
        case "hidden": return 14;
        case "idle": return Math.max(172, 44 + idleName.implicitWidth + 24 + idleRate.implicitWidth + 44);
        case "arming": return Math.max(214, 46 + armingLabel.implicitWidth + 64);
        case "live": return Math.max(228, 100 + liveRate.implicitWidth + 48);
        case "expanded": return 456;
        case "notice": return Math.min(440, Math.max(196, noticeLabel.implicitWidth + 72));
        case "error": return Math.min(460, Math.max(240, errorLabel.implicitWidth + 72));
        case "summary": return 322;
        }
        return 172;
    }
    readonly property real targetHeight: view === "hidden" ? 14 : view === "expanded" ? 184
        : view === "summary" ? 64 : view === "error" && errorLabel.lineCount > 1 ? 56 : 38

    width: targetWidth
    height: targetHeight
    Behavior on width { SpringAnimation { spring: 3.3; damping: 0.25; epsilon: 0.2 } }
    Behavior on height { SpringAnimation { spring: 3.3; damping: 0.28; epsilon: 0.2 } }
    opacity: view === "hidden" ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    // Velocity-driven jelly: widening squashes the capsule vertically, shrinking stretches it.
    property real clock: 0
    property real lastWidth: width
    property real lastHeight: height
    property real stretch: 0
    FrameAnimation {
        id: ticker
        running: (Theme.animating || island.overlay) && island.visible
        onTriggered: {
            const dt = Math.max(frameTime, 0.001);
            island.clock += dt;
            const v = (island.width - island.lastWidth) - (island.height - island.lastHeight) * 1.5;
            island.lastWidth = island.width;
            island.lastHeight = island.height;
            island.stretch = island.stretch * 0.7 + 0.3 * Math.max(-0.08, Math.min(0.08, v / dt / 5200));
        }
    }
    transform: Scale {
        origin.x: island.width / 2; origin.y: island.height / 2
        xScale: 1 + island.stretch * 0.45
        yScale: 1 - island.stretch
    }

    Timer { id: noticeTimer; interval: 1600; onTriggered: island.noticeText = "" }
    Timer { id: errorTimer; interval: 4000; onTriggered: island.errorText = "" }
    Timer { id: summaryTimer; interval: 2600; onTriggered: island.summaryShown = false }
    property string previousPhase: "idle"
    property real armedAt: 0
    onPhaseChanged: {
        if (phase === "arming")
            armedAt = clock;
        if (phase === "idle" && engine && engine.clicks > 0 && previousPhase !== "arming") {
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
    TapHandler {
        enabled: island.interactive
        onTapped: {
            if (island.view === "expanded" && island.pinned) island.pinned = false;
            else island.pinned = true;
            island.errorText = "";
            island.summaryShown = false;
        }
    }
    onInteractiveChanged: if (!interactive) pinned = false

    // Capsule: smoked Liquid Glass refracting the window below it (no backdrop in the overlay
    // window, where it is lit tint only); plain black on solid.
    Fill {
        id: capsule
        anchors.fill: parent
        radius: Math.min(height / 2, 36)
        color: Theme.island
        strength: 0.86
        floating: true
        detached: island.overlay
    }

    // Content lives in a fixed-size layer (no texture churn while morphing) clipped to the capsule.
    readonly property real canvasWidth: 480
    readonly property real canvasHeight: 200
    Item {
        id: maskRoot
        width: island.canvasWidth; height: island.canvasHeight
        x: (island.width - width) / 2
        visible: false
        layer.enabled: true
        Rectangle {
            x: (parent.width - island.width) / 2
            width: island.width; height: island.height
            radius: capsule.radius
            color: "white"
        }
    }
    Item {
        id: canvas
        width: island.canvasWidth; height: island.canvasHeight
        x: (island.width - width) / 2
        layer.enabled: true
        layer.effect: MultiEffect { maskEnabled: true; maskSource: maskRoot; maskThresholdMin: 0.5; maskSpreadAtMin: 0.4 }
        Item {
            id: frame
            x: (parent.width - island.width) / 2
            width: island.width; height: island.height

            // idle
            Face {
                on: island.view === "idle"
                ModeDot { mode: island.mode; x: 6; anchors.verticalCenter: parent.verticalCenter }
                Label {
                    id: idleName
                    x: 42; anchors.verticalCenter: parent.verticalCenter
                    text: I18n.t(island.mode === 1 ? "mode.blatant" : "mode.legit")
                    color: Theme.islandText
                    font.pixelSize: 13; font.weight: Font.DemiBold
                }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Num { id: idleRate; text: island.engine ? I18n.rate(island.engine.cps) : ""; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: I18n.t("cps"); color: Theme.islandMuted; font.pixelSize: 10; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                }
            }
            // arming: the ring empties continuously over the countdown
            Face {
                on: island.view === "arming"
                CountdownRing { x: 6; anchors.verticalCenter: parent.verticalCenter; size: 26; progress: island.armProgress; count: island.engine ? island.engine.countdown : 0 }
                Label {
                    id: armingLabel
                    x: 42; anchors.verticalCenter: parent.verticalCenter
                    text: I18n.t("state.arming")
                    color: Theme.islandText
                    font.pixelSize: 13; font.weight: Font.DemiBold
                }
                ModeDot { mode: island.mode; size: 22; anchors.right: parent.right; anchors.rightMargin: 9; anchors.verticalCenter: parent.verticalCenter }
            }
            // live
            Face {
                id: liveFace
                on: island.view === "live"
                ModeDot { mode: island.mode; x: 6; anchors.verticalCenter: parent.verticalCenter; scale: 1 + 0.08 * Math.sin(island.clock * 7) }
                Waveform { x: 42; anchors.verticalCenter: parent.verticalCenter; bars: 6; height: 20; clock: island.clock; rate: island.shownRate; tint: island.tint }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Num { id: liveRate; text: I18n.rate(island.shownRate); font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: I18n.t("cps"); color: Theme.islandMuted; font.pixelSize: 10; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
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
                    opacity: enabled ? 1 : 0.5
                    Fill { anchors.fill: parent; radius: 17; color: Theme.islandRaised; strength: 0.82; inset: true; floating: true; detached: island.overlay }
                    Fill {
                        property real slide: island.mode * parent.width / 2
                        Behavior on slide { SpringAnimation { spring: 4; damping: 0.3; epsilon: 0.05 } }
                        x: 3 + slide; y: 3
                        width: parent.width / 2 - 6; height: parent.height - 6
                        radius: height / 2
                        color: "#48484a"
                        strength: 0.82
                        floating: true; detached: island.overlay
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
                                Accessible.name: I18n.t(modelData.key)
                                onClicked: if (island.engine) island.engine.mode = index
                                contentItem: Item {
                                    Row {
                                        spacing: 6
                                        anchors.centerIn: parent
                                        Icon { name: modeButton.modelData.icon; size: 15; stroke: 2; color: island.mode === modeButton.index ? Theme.modeBright(modeButton.index) : Theme.islandMuted; anchors.verticalCenter: parent.verticalCenter }
                                        Label { text: I18n.t(modeButton.modelData.key); color: island.mode === modeButton.index ? Theme.islandText : Theme.islandMuted; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
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
                        color: island.arming ? Theme.armingBright : island.running ? island.tint : Theme.islandMuted
                        opacity: island.running || island.arming ? 0.55 + 0.45 * Math.abs(Math.sin(island.clock * 3)) : 1
                    }
                    Label {
                        text: I18n.t("state." + island.phase)
                        color: Theme.islandMuted
                        font.pixelSize: 12; font.weight: Font.Medium
                    }
                }
                // value
                Row {
                    x: 20; y: 62
                    spacing: 6
                    Num {
                        id: bigValue
                        text: island.arming ? (island.engine ? island.engine.countdown : "") : island.running ? I18n.rate(island.shownRate) : island.engine ? I18n.rate(island.engine.cps) : ""
                        font.pixelSize: 48
                        font.letterSpacing: -1
                        color: island.arming ? Theme.armingBright : Theme.islandText
                    }
                    Label {
                        anchors.baseline: bigValue.baseline
                        text: island.arming ? I18n.t("sec") : I18n.t("cps")
                        color: Theme.islandMuted
                        font.pixelSize: 13; font.weight: Font.DemiBold
                    }
                }
                // detail line
                Row {
                    x: 20; y: 136
                    spacing: 8
                    visible: island.running
                    Label { text: island.engine ? I18n.number(island.engine.clicks, 0) : ""; color: Theme.islandText; font.pixelSize: 13; font.weight: Font.DemiBold; font.features: { "tnum": 1 } }
                    Label { text: I18n.t("live.clicks").toLocaleLowerCase(); color: Theme.islandMuted; font.pixelSize: 13 }
                    Label { text: "·"; color: Theme.islandMuted; font.pixelSize: 13 }
                    Label { text: island.engine ? I18n.duration(island.engine.elapsedSec) : ""; color: Theme.islandText; font.pixelSize: 13; font.weight: Font.DemiBold; font.features: { "tnum": 1 } }
                }
                // rate adjust (idle) or live waveform (running)
                Column {
                    x: action.x - 50; y: 76
                    spacing: 8
                    visible: !island.running && !island.arming
                    DarkRound { objectName: "islandPlus"; glyph: "plus"; enabled: island.engine && !island.engine.active; onClicked: island.nudge(true) }
                    DarkRound { objectName: "islandMinus"; glyph: "minus"; enabled: island.engine && !island.engine.active && island.engine.cps > 1; onClicked: island.nudge(false) }
                }
                Waveform { visible: island.running; x: action.x - 96; y: 104; bars: 9; height: 34; clock: island.clock; rate: island.shownRate; tint: island.tint }
                // start / cancel / stop
                T.AbstractButton {
                    id: action
                    objectName: "islandAction"
                    anchors.right: parent.right; anchors.rightMargin: 18
                    y: 84
                    width: 76; height: 76
                    hoverEnabled: true
                    enabled: island.engine && (island.engine.available || island.engine.active)
                    Accessible.name: island.running ? I18n.t("stop") : island.arming ? I18n.t("cancel") : I18n.t("start")
                    onClicked: island.engine.toggle()
                    scale: pressed ? 0.88 : hovered ? 1.06 : 1
                    Behavior on scale { SpringAnimation { spring: 5; damping: 0.28; epsilon: 0.001 } }
                    opacity: enabled ? 1 : 0.4
                    background: Fill {
                        radius: width / 2
                        color: island.running ? Theme.blatantBright : island.arming ? "#3a2a10" : Theme.legitBright
                        strength: 0.84
                        floating: true; detached: island.overlay
                        Behavior on color { ColorAnimation { duration: 260 } }
                        CountdownRing {
                            anchors.centerIn: parent
                            visible: island.arming
                            size: 70; thickness: 4
                            progress: island.armProgress
                            count: -1
                        }
                    }
                    contentItem: Item {
                        Icon {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: !island.running && !island.arming ? 2 : 0
                            name: island.running ? "stop" : island.arming ? "x" : "play"
                            size: 30; stroke: 2.6
                            color: island.arming ? Theme.armingBright : "#ffffff"
                        }
                    }
                }
            }
            // notice
            Face {
                on: island.view === "notice"
                Icon { x: 15; anchors.verticalCenter: parent.verticalCenter; name: island.noticeIcon; size: 18; stroke: 2; color: island.noticeTint }
                Label {
                    id: noticeLabel
                    x: 44; anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 360)
                    elide: Text.ElideRight
                    text: island.noticeText
                    color: island.noticeTint
                    font.pixelSize: 13; font.weight: Font.DemiBold
                }
            }
            // error
            Face {
                on: island.view === "error"
                Icon { x: 15; anchors.verticalCenter: parent.verticalCenter; name: "warning"; size: 18; stroke: 2; color: Theme.blatantBright }
                Label {
                    id: errorLabel
                    x: 44; anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 380)
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
                Fill {
                    x: 15; anchors.verticalCenter: parent.verticalCenter
                    width: 34; height: 34; radius: 17
                    strength: 0.84
                    floating: true; detached: island.overlay
                    color: island.tint
                    Icon { anchors.centerIn: parent; name: "check"; size: 18; stroke: 2.4; color: "#ffffff" }
                }
                Column {
                    x: 62; anchors.verticalCenter: parent.verticalCenter
                    Num { text: I18n.number(island.summaryClicks, 0); font.pixelSize: 20 }
                    Label { text: I18n.t("live.clicks"); color: Theme.islandMuted; font.pixelSize: 11 }
                }
                Column {
                    anchors.right: parent.right; anchors.rightMargin: 22
                    anchors.verticalCenter: parent.verticalCenter
                    Row {
                        anchors.right: parent.right
                        spacing: 4
                        Num { id: avg; text: I18n.rate(island.summaryAverage); font.pixelSize: 20 }
                        Label { text: I18n.t("cps"); color: Theme.islandMuted; font.pixelSize: 10; font.weight: Font.DemiBold; anchors.baseline: avg.baseline }
                    }
                    Label { anchors.right: parent.right; text: I18n.t("live.average"); color: Theme.islandMuted; font.pixelSize: 11 }
                }
            }
        }
    }

    // Smoothed live rate shared by faces.
    property real shownRate: engine && engine.measuredCps >= 0 ? engine.measuredCps : 0
    Behavior on shownRate { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

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
        visible: opacity > 0.001
        scale: on ? 1 : 0.86
        Behavior on opacity { NumberAnimation { duration: face.on ? 260 : 110; easing.type: face.on ? Easing.OutCubic : Easing.InQuad } }
        Behavior on scale { SpringAnimation { spring: 4; damping: 0.3; epsilon: 0.002 } }
    }
    component Num: Label {
        color: Theme.islandText
        font.weight: Font.DemiBold
        font.features: { "tnum": 1 }
    }
    component ModeDot: Fill {
        property real size: 26
        property int mode: 0
        width: size; height: size; radius: size / 2
        strength: 0.84
        floating: true; detached: Window.window ? Window.window.objectName === "islandOverlay" : false
        color: Theme.modeBright(mode)
        Behavior on color { ColorAnimation { duration: Theme.slow } }
        Icon { anchors.centerIn: parent; name: parent.mode === 1 ? "bolt" : "hand"; size: parent.size * 0.62; stroke: 2; color: "#ffffff" }
    }
    component CountdownRing: Item {
        id: ring
        property real size: 26
        property real thickness: 2.5
        property real progress: 0
        property int count: 0
        width: size; height: size
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Qt.rgba(1, 0.62, 0.04, 0.25); strokeWidth: ring.thickness; fillColor: "transparent"
                PathAngleArc { centerX: ring.size / 2; centerY: ring.size / 2; radiusX: ring.size / 2 - ring.thickness; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
            }
            ShapePath {
                strokeColor: Theme.armingBright; strokeWidth: ring.thickness; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                PathAngleArc { centerX: ring.size / 2; centerY: ring.size / 2; radiusX: ring.size / 2 - ring.thickness; radiusY: radiusX; startAngle: -90; sweepAngle: -360 * (1 - ring.progress) }
            }
        }
        Label {
            anchors.centerIn: parent
            visible: ring.count >= 0
            text: ring.count
            color: Theme.armingBright
            font.pixelSize: 12; font.weight: Font.Bold
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
        scale: pressed ? 0.88 : 1
        Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
        background: Fill { radius: 18; color: round.hovered ? "#3a3a3c" : Theme.islandControl; strength: 0.82; floating: true; detached: Window.window ? Window.window.objectName === "islandOverlay" : false }
        contentItem: Item { Icon { anchors.centerIn: parent; name: round.glyph; size: 16; stroke: 2.2; color: Theme.islandText } }
    }
}
