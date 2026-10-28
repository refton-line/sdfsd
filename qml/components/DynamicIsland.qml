import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import QtQuick.Templates as T
import CClicker

// iPhone-style Dynamic Island. One black capsule morphs between presentations with springs;
// each presentation's content fades through a short blur so shape and content never jump.
Item {
    id: island
    property var engine
    property bool overlay: false          // floating copy above other windows
    property bool booting: false
    property real bootProgress: 0
    property bool hidden: false
    property bool interactive: !overlay

    // Transient presentations, highest priority first: error, summary, notice.
    property string errorText: ""
    property string noticeText: ""
    property string noticeIcon: ""
    property color noticeTint: Theme.islandText
    property bool summaryShown: false
    property real summaryClicks: 0
    property real summaryAverage: -1
    property bool pinned: false

    readonly property int mode: engine ? engine.mode : 0
    readonly property string engineState: engine ? engine.state : "idle"
    readonly property bool running: engineState === "running" || engineState === "stopping"
    readonly property bool arming: engineState === "arming"
    readonly property color modeTint: Theme.modeBright(mode)
    readonly property bool expanded: (pinned || hover.hovered && hoverDelay.elapsed) && (running || arming) && interactive

    readonly property string view: hidden ? "hidden"
        : booting ? "boot"
        : errorText !== "" ? "error"
        : summaryShown ? "summary"
        : noticeText !== "" ? "notice"
        : expanded ? "expanded"
        : arming ? "arming"
        : running ? "live"
        : "idle"

    function notify(icon, text, tint) {
        noticeIcon = icon; noticeText = text; noticeTint = tint;
        noticeTimer.restart();
    }
    function showError(text) {
        errorText = text;
        errorTimer.restart();
    }

    readonly property real targetWidth: {
        switch (view) {
        case "hidden": return 12;
        case "boot": return 44;
        case "idle": return Math.max(156, 44 + idleName.implicitWidth + 22 + idleRate.implicitWidth + 16);
        case "arming": return Math.max(212, 44 + armingLabel.implicitWidth + 60);
        case "live": return Math.max(206, 44 + 52 + liveRate.implicitWidth + 18);
        case "expanded": return 392;
        case "notice": return Math.min(420, Math.max(200, noticeLabel.implicitWidth + 74));
        case "error": return Math.min(440, Math.max(240, errorLabel.implicitWidth + 74));
        case "summary": return 316;
        }
        return 156;
    }
    readonly property real targetHeight: view === "hidden" ? 12 : view === "boot" ? 44 : view === "expanded" ? 98
        : view === "summary" ? 66 : view === "error" && errorLabel.lineCount > 1 ? 56 : 38

    width: targetWidth
    height: targetHeight
    Behavior on width { SpringAnimation { spring: 3.4; damping: 0.27; epsilon: 0.1 } }
    Behavior on height { SpringAnimation { spring: 3.4; damping: 0.3; epsilon: 0.1 } }
    opacity: view === "hidden" ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: island.view === "hidden" ? 260 : 180; easing.type: Easing.OutCubic } }
    // Squash on arrival of a new presentation, like the hardware cutout absorbing it.
    property real squash: 1
    transform: Scale { origin.x: island.width / 2; origin.y: 0; xScale: island.squash; yScale: 2 - island.squash }
    onViewChanged: if (view !== "hidden") squashAnim.restart()
    SequentialAnimation {
        id: squashAnim
        NumberAnimation { target: island; property: "squash"; to: 1.035; duration: 90; easing.type: Easing.OutQuad }
        SpringAnimation { target: island; property: "squash"; to: 1; spring: 4; damping: 0.25; epsilon: 0.0005 }
    }

    Timer { id: noticeTimer; interval: 1700; onTriggered: island.noticeText = "" }
    Timer { id: errorTimer; interval: 4200; onTriggered: island.errorText = "" }
    Timer { id: summaryTimer; interval: 3000; onTriggered: island.summaryShown = false }
    onEngineStateChanged: {
        if (engineState === "idle" && engine && engine.clicks > 0 && !summaryShown && previousState !== "arming") {
            summaryClicks = engine.clicks;
            summaryAverage = engine.averageCps;
            summaryShown = true;
            summaryTimer.restart();
        }
        if (engineState === "arming" || engineState === "idle")
            pinned = false;
        previousState = engineState;
    }
    property string previousState: "idle"

    HoverHandler { id: hover; enabled: island.interactive }
    Timer { id: hoverTimer; interval: 260; running: hover.hovered; onTriggered: hoverDelay.elapsed = true }
    QtObject { id: hoverDelay; property bool elapsed: false }
    Connections { target: hover; function onHoveredChanged() { if (!hover.hovered) hoverDelay.elapsed = false; } }
    TapHandler {
        enabled: island.interactive
        onTapped: {
            if (island.view === "error") { island.errorText = ""; return; }
            if (island.view === "summary") { island.summaryShown = false; return; }
            if (island.running || island.arming) island.pinned = !island.pinned;
        }
    }

    // Capsule
    Rectangle {
        id: capsule
        anchors.fill: parent
        radius: Math.min(height / 2, 34)
        color: Theme.island
        antialiasing: true
        border.width: island.overlay ? 0 : 1
        border.color: Qt.rgba(1, 1, 1, 0.06)
    }

    // Each presentation fades through blur; `on` drives it.
    component Face: Item {
        id: face
        property bool on: false
        anchors.fill: parent
        opacity: on ? 1 : 0
        visible: opacity > 0.001
        scale: on ? 1 : 0.9
        Behavior on opacity { NumberAnimation { duration: face.on ? 280 : 120; easing.type: face.on ? Easing.OutCubic : Easing.InQuad } }
        Behavior on scale { NumberAnimation { duration: face.on ? 380 : 140; easing.type: face.on ? Easing.OutBack : Easing.InQuad } }
        layer.enabled: opacity > 0.001 && opacity < 0.999
        layer.effect: MultiEffect { blurEnabled: true; blurMax: 16; blur: 1 - face.opacity }
    }
    // Inline components do not see outer ids, so mode and tint are passed in.
    component ModeDot: Rectangle {
        property real dot: 26
        property int mode: 0
        width: dot; height: dot; radius: dot / 2
        color: Theme.modeBright(mode)
        Behavior on color { ColorAnimation { duration: Theme.slow } }
        Icon {
            anchors.centerIn: parent
            name: parent.mode === 1 ? "bolt" : "hand"
            size: parent.dot * 0.62
            stroke: 2
            color: "#ffffff"
        }
    }
    component Num: Label {
        color: Theme.islandText
        font.weight: Font.DemiBold
        font.features: { "tnum": 1 }
    }

    // boot: progress ring around the brand C
    Face {
        on: island.view === "boot"
        Shape {
            anchors.centerIn: parent
            width: 32; height: 32
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Qt.rgba(1, 1, 1, 0.18); strokeWidth: 2.5; fillColor: "transparent"
                PathAngleArc { centerX: 16; centerY: 16; radiusX: 14; radiusY: 14; startAngle: 0; sweepAngle: 360 }
            }
            ShapePath {
                strokeColor: Theme.islandText; strokeWidth: 2.5; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                PathAngleArc { centerX: 16; centerY: 16; radiusX: 14; radiusY: 14; startAngle: -90; sweepAngle: 360 * island.bootProgress }
            }
            ShapePath {
                strokeColor: Theme.islandText; strokeWidth: 2.4; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                PathAngleArc { centerX: 16; centerY: 16; radiusX: 6.5; radiusY: 6.5; startAngle: -40; sweepAngle: -280 }
            }
        }
    }
    // idle: mode and target rate
    Face {
        on: island.view === "idle"
        ModeDot { mode: island.mode; x: 6; anchors.verticalCenter: parent.verticalCenter }
        Label {
            id: idleName
            x: 40; anchors.verticalCenter: parent.verticalCenter
            text: I18n.t(island.mode === 1 ? "mode.blatant" : "mode.legit")
            color: Theme.islandText
            font.pixelSize: 13; font.weight: Font.DemiBold
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Num { id: idleRate; text: island.engine ? I18n.rate(island.engine.cps) : ""; font.pixelSize: 13; anchors.baseline: idleUnit.baseline }
            Label { id: idleUnit; text: I18n.t("cps"); color: Theme.islandMuted; font.pixelSize: 10; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        }
    }
    // arming: countdown ring
    Face {
        on: island.view === "arming"
        Item {
            x: 6; width: 26; height: 26
            anchors.verticalCenter: parent.verticalCenter
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Qt.rgba(1, 0.62, 0.04, 0.25); strokeWidth: 2.5; fillColor: "transparent"
                    PathAngleArc { centerX: 13; centerY: 13; radiusX: 11.5; radiusY: 11.5; startAngle: 0; sweepAngle: 360 }
                }
                ShapePath {
                    strokeColor: Theme.armingBright; strokeWidth: 2.5; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: 13; centerY: 13; radiusX: 11.5; radiusY: 11.5; startAngle: -90; sweepAngle: -360 * countdownSweep.value }
                }
            }
            Num {
                anchors.centerIn: parent
                text: island.engine ? island.engine.countdown : ""
                color: Theme.armingBright
                font.pixelSize: 12; font.weight: Font.Bold
            }
            // Smooth sweep across each second of the countdown.
            QtObject { id: countdownSweep; property real value: 1 }
            NumberAnimation {
                id: sweep
                property int lastCount: -1
                target: countdownSweep; property: "value"
                duration: 1000; easing.type: Easing.Linear
            }
            Connections {
                target: island.engine
                function onChanged() {
                    if (!island.engine || island.engine.state !== "arming") { sweep.lastCount = -1; return; }
                    const total = Math.max(1, island.engine.launchDelaySec);
                    const left = island.engine.countdown;
                    if (sweep.lastCount !== left) {
                        sweep.lastCount = left;
                        sweep.stop();
                        countdownSweep.value = left / total;
                        sweep.to = (left - 1) / total;
                        sweep.start();
                    }
                }
            }
        }
        Label {
            id: armingLabel
            x: 42; anchors.verticalCenter: parent.verticalCenter
            text: I18n.t("state.arming")
            color: Theme.islandText
            font.pixelSize: 13; font.weight: Font.DemiBold
        }
        ModeDot { mode: island.mode; dot: 22; anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter }
    }
    // live: pulsing mode, activity bars, measured rate
    Face {
        id: liveFace
        on: island.view === "live"
        property real shownRate: island.engine && island.engine.measuredCps >= 0 ? island.engine.measuredCps : 0
        Behavior on shownRate { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        ModeDot {
            id: livePulse
            mode: island.mode
            x: 6; anchors.verticalCenter: parent.verticalCenter
            SequentialAnimation on scale {
                running: liveFace.on
                loops: Animation.Infinite
                NumberAnimation { to: 1.1; duration: 520; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 520; easing.type: Easing.InOutSine }
            }
        }
        Row {
            x: 42; anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            Repeater {
                model: 5
                Rectangle {
                    id: bar
                    required property int index
                    width: 3; radius: 1.5
                    color: island.modeTint
                    anchors.verticalCenter: parent.verticalCenter
                    property real level: 0.3
                    height: 4 + 14 * level
                    SequentialAnimation on level {
                        running: liveFace.on
                        loops: Animation.Infinite
                        NumberAnimation { to: 1; duration: 190 + bar.index * 47; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.15 + 0.1 * (bar.index % 2); duration: 230 + bar.index * 39; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Num { id: liveRate; text: I18n.rate(liveFace.shownRate); font.pixelSize: 15; anchors.baseline: liveUnit.baseline }
            Label { id: liveUnit; text: I18n.t("cps"); color: Theme.islandMuted; font.pixelSize: 10; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        }
    }
    // expanded: rate, totals and a stop control
    Face {
        on: island.view === "expanded"
        ModeDot { mode: island.mode; x: 16; y: 14; dot: 28 }
        Column {
            x: 54; y: 13
            spacing: 1
            Label { text: I18n.t(island.mode === 1 ? "mode.blatant" : "mode.legit"); color: Theme.islandText; font.pixelSize: 13; font.weight: Font.DemiBold }
            Label { text: I18n.t("state." + island.engineState); color: island.arming ? Theme.armingBright : Theme.islandMuted; font.pixelSize: 11 }
        }
        Row {
            x: 18; anchors.bottom: parent.bottom; anchors.bottomMargin: 12
            spacing: 6
            Num {
                id: bigRate
                text: island.arming ? (island.engine ? island.engine.countdown : "") : I18n.rate(liveFace.shownRate)
                font.pixelSize: 30
                color: island.arming ? Theme.armingBright : Theme.islandText
            }
            Label { text: island.arming ? I18n.t("sec") : I18n.t("cps"); color: Theme.islandMuted; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.baseline: bigRate.baseline }
        }
        Column {
            x: 196; anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Repeater {
                model: [
                    { k: "live.clicks", v: island.engine ? I18n.number(island.engine.clicks, 0) : "0" },
                    { k: "live.time", v: island.engine ? I18n.duration(island.engine.elapsedSec) : "0:00" }
                ]
                Row {
                    required property var modelData
                    spacing: 8
                    Label { width: 54; text: I18n.t(modelData.k); color: Theme.islandMuted; font.pixelSize: 11 }
                    Num { text: modelData.v; font.pixelSize: 13 }
                }
            }
        }
        T.AbstractButton {
            id: stopButton
            anchors.right: parent.right; anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 46; height: 46
            hoverEnabled: true
            Accessible.name: I18n.t("stop")
            onClicked: if (island.engine) island.engine.stop()
            scale: pressed ? 0.9 : hovered ? 1.06 : 1
            Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
            background: Rectangle { radius: 23; color: Theme.blatantBright }
            contentItem: Item { Icon { anchors.centerIn: parent; name: "stop"; size: 20; color: "#ffffff" } }
        }
    }
    // notice: icon + short text
    Face {
        on: island.view === "notice"
        Icon {
            id: noticeGlyph
            x: 14; anchors.verticalCenter: parent.verticalCenter
            name: island.noticeIcon; size: 18; stroke: 2
            color: island.noticeTint
        }
        Label {
            id: noticeLabel
            x: 42; anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 340)
            elide: Text.ElideRight
            text: island.noticeText
            color: island.noticeTint
            font.pixelSize: 13; font.weight: Font.DemiBold
        }
    }
    // error
    Face {
        on: island.view === "error"
        Icon {
            x: 14; anchors.verticalCenter: parent.verticalCenter
            name: "warning"; size: 18; stroke: 2
            color: Theme.blatantBright
        }
        Label {
            id: errorLabel
            x: 42; anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 360)
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            text: island.errorText
            color: Theme.islandText
            font.pixelSize: 13; font.weight: Font.Medium
        }
    }
    // summary after a run
    Face {
        on: island.view === "summary"
        Rectangle {
            x: 14; anchors.verticalCenter: parent.verticalCenter
            width: 34; height: 34; radius: 17
            color: island.modeTint
            Icon { anchors.centerIn: parent; name: "check"; size: 18; stroke: 2.4; color: "#ffffff" }
        }
        Column {
            x: 62; anchors.verticalCenter: parent.verticalCenter
            Num { text: I18n.number(island.summaryClicks, 0); font.pixelSize: 20 }
            Label { text: I18n.t("live.clicks"); color: Theme.islandMuted; font.pixelSize: 11 }
        }
        Column {
            anchors.right: parent.right; anchors.rightMargin: 20
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
