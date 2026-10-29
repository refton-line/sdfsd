import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtCore
import FakeClicker
import "components"

ApplicationWindow {
    id: win
    objectName: "mainWindow"
    visible: true
    title: "Fake Clicker"
    readonly property real fit: Math.min(1, (Screen.desktopAvailableWidth - 48) / Theme.baseWidth, (Screen.desktopAvailableHeight - 48) / Theme.baseHeight)
    width: uiCapture ? Theme.baseWidth : Math.round(Theme.baseWidth * fit)
    height: uiCapture ? Theme.baseHeight : Math.round(Theme.baseHeight * fit)
    minimumWidth: Math.min(960, width)
    minimumHeight: Math.min(640, height)
    color: Theme.canvas
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowMinMaxButtonsHint | Qt.WindowSystemMenuHint

    Settings {
        id: prefs
        category: "ui"
        property string language: "en"
        property bool islandOverlay: true
    }

    property real reveal: 0           // 0 → 1 once loading is done: the interface fades in
    property real farewell: 0         // 0 → 1 on close: everything fades out
    property real pacing: 0           // the loading bar never fills faster than this
    property bool chomped: false      // the skull finished its two bites
    property bool launched: false
    property bool exiting: false
    property bool allowClose: false
    property int currentPage: 0
    property real languageFade: 1
    property string pendingLanguage: ""
    readonly property bool maximized: visibility === Window.Maximized
    readonly property bool engineActive: clickEngine.active
    property bool lingering: false
    onActiveChanged: Theme.animating = active || uiCapture

    function launch() {
        if (launched || exiting || !startup.done || !chomped || pacing < 1)
            return;
        launched = true;
        launchAnimation.start();
    }
    function setLanguage(code) {
        if (code === I18n.language || languageSwap.running)
            return;
        pendingLanguage = code;
        languageSwap.start();
    }
    function setIslandOverlay(value) {
        prefs.islandOverlay = !!value;
    }
    // Native commands so Windows plays its own minimize/maximize/restore animations.
    function toggleMaximized() {
        if (!windowEffects.toggleMaximize(win)) {
            if (maximized) showNormal(); else showMaximized();
        }
    }
    function minimizeWindow() {
        if (!windowEffects.minimize(win))
            showMinimized();
    }

    Component.onCompleted: {
        I18n.language = prefs.language === "ru" ? "ru" : "en";
        Theme.animating = true;
        startup.start();
    }
    // The intro starts on the first presented frame, so a slow first render never eats the bite.
    property bool introStarted: false
    onFrameSwapped: if (!introStarted) { introStarted = true; introAnimation.start(); }
    onClosing: function(event) {
        // Input stops before any animation; Alt+F4 takes the same path.
        clickEngine.setReady(false);
        clickEngine.stop();
        if (allowClose) {
            event.accepted = true;
            return;
        }
        event.accepted = false;
        if (!exiting) {
            exiting = true;
            introAnimation.stop();
            launchAnimation.stop();
            closeAnimation.start();
        }
    }

    Connections { target: startup; function onChanged() { win.launch(); } }
    Shortcut { sequence: "Escape"; enabled: island.pinned && Theme.modals === 0; onActivated: island.pinned = false }

    // Launch: the skull fades in and bites twice while the loading bar fills, then the splash
    // steps aside and the interface fades in. About one second in total.
    ParallelAnimation {
        id: introAnimation
        NumberAnimation { target: splash; property: "opacity"; from: 0; to: 1; duration: 140 * motionScale; easing.type: Easing.OutCubic }
        NumberAnimation { target: win; property: "pacing"; from: 0; to: 1; duration: 900 * motionScale; easing.type: Easing.InOutQuad }
        SequentialAnimation {
            PauseAnimation { duration: 160 * motionScale }
            ScriptAction { script: splash.chomp() }
        }
        onFinished: win.launch()
    }
    SequentialAnimation {
        id: launchAnimation
        ParallelAnimation {
            NumberAnimation { target: splash; property: "opacity"; to: 0; duration: 200 * motionScale; easing.type: Easing.OutCubic }
            SequentialAnimation {
                PauseAnimation { duration: 60 * motionScale }
                NumberAnimation { target: win; property: "reveal"; to: 1; duration: 260 * motionScale; easing.type: Easing.OutCubic }
            }
        }
        ScriptAction { script: { island.booting = false; clickEngine.setReady(true); } }
    }
    // Close: a short fade, then the window goes.
    SequentialAnimation {
        id: closeAnimation
        ScriptAction { script: { island.hidden = true; overlay.wanted = false; } }
        NumberAnimation { target: win; property: "farewell"; to: 1; duration: 150 * motionScale; easing.type: Easing.InCubic }
        // The overlay is a second native window; take it down before the last window closes.
        ScriptAction { script: { overlay.visible = false; win.allowClose = true; win.close(); } }
    }
    SequentialAnimation {
        id: languageSwap
        NumberAnimation { target: win; property: "languageFade"; to: 0; duration: 110; easing.type: Easing.InQuad }
        ScriptAction {
            script: {
                I18n.language = win.pendingLanguage;
                prefs.language = win.pendingLanguage;
                if (!island.expanded) island.inform("globe", I18n.t("settings.language"), win.pendingLanguage === "ru" ? "Русский" : "English", "");
            }
        }
        NumberAnimation { target: win; property: "languageFade"; to: 1; duration: 180; easing.type: Easing.OutCubic }
    }

    readonly property int engineMode: clickEngine.mode
    onEngineModeChanged: if (launched && !island.expanded) island.inform(engineMode === 1 ? "bolt" : "hand", I18n.t("mode"), I18n.t(engineMode === 1 ? "mode.blatant" : "mode.legit"), engineMode === 1 ? "blatant" : "legit")
    readonly property string engineError: clickEngine.error
    onEngineErrorChanged: {
        // Resolve visibility after active/lingering bindings have settled, then deliver only once.
        Qt.callLater(function() {
            if (win.engineError !== "") {
                const owner = overlay.wanted ? overlay.island : island;
                owner.showError(I18n.msg(win.engineError));
            }
        });
    }
    Connections {
        target: configs
        function onNoticed(code, ok) {
            island.notify(ok ? "checkCircle" : "warning", I18n.msg(code), ok ? Theme.islandText : Theme.dangerText);
        }
    }
    onEngineActiveChanged: if (!engineActive && launched) { lingering = true; lingerTimer.restart(); }
    Timer { id: lingerTimer; interval: 3400; onTriggered: win.lingering = false }

    IslandOverlay {
        id: overlay
        engine: clickEngine
        wanted: prefs.islandOverlay && win.launched && !win.exiting && !win.active && (clickEngine.active || win.lingering)
    }
    WindowSheet {
        id: windowSheet
        engine: clickEngine
        roomWidth: win.width - 48
        roomHeight: win.height - 40
    }
    // The island reports every real change: what changed, then the new value.
    QtObject {
        id: watch
        readonly property bool live: win.launched && !win.exiting
        function say(icon, label, value, tone) { if (live && !island.expanded) island.inform(icon, label, value, tone); }
        readonly property double cps: clickEngine.cps
        readonly property int button: clickEngine.mouseButton
        readonly property int variance: clickEngine.variance
        readonly property int hold: clickEngine.holdMs
        readonly property int duration: clickEngine.durationSec
        readonly property double count: clickEngine.countLimit
        readonly property int delay: clickEngine.launchDelaySec
        readonly property string startKey: clickEngine.startLabel
        readonly property string stopKey: clickEngine.stopLabel
        readonly property string target: clickEngine.targetWindow
        readonly property bool overlayOn: prefs.islandOverlay
        onCpsChanged: say("gauge", I18n.t("section.rate"), I18n.rate(cps) + " " + I18n.t("cps"))
        onButtonChanged: say("mouse", I18n.t("button"), I18n.t("button." + button))
        onVarianceChanged: say("wave", I18n.t("variance"), I18n.t("variance." + variance))
        onHoldChanged: say("hold", I18n.t("hold"), hold === 0 ? I18n.t("hold.instant") : hold + " " + I18n.t("ms"))
        onDurationChanged: say("hourglass", I18n.t("limit.time"), duration === 0 ? I18n.t("limit.none") : I18n.number(duration, 0) + " " + I18n.t("sec"))
        onCountChanged: say("hash", I18n.t("limit.clicks"), count === 0 ? I18n.t("limit.none") : I18n.number(count, 0))
        onDelayChanged: say("timer", I18n.t("keys.countdown"), delay + " " + I18n.t("sec"))
        onStartKeyChanged: say("play", I18n.t("keys.start"), startKey, "key")
        onStopKeyChanged: say("stop", I18n.t("keys.stop"), stopKey, "key")
        onTargetChanged: say("target", I18n.t("target"), target === "" ? I18n.t("target.any") : clickEngine.targetTitle)
        onOverlayOnChanged: say(overlayOn ? "overlay" : "overlayOff", I18n.t("look.island"), I18n.t(overlayOn ? "on" : "off"), overlayOn ? "on" : "off")
    }
    KeyboardSheet {
        id: keyboard
        engine: clickEngine
        roomWidth: win.width - 48
        roomHeight: win.height - 40
    }

    readonly property var navItems: [
        { text: I18n.t("nav.clicker"), icon: "cursor" },
        { text: I18n.t("nav.hotkeys"), icon: "keyboard" },
        { text: I18n.t("nav.profiles"), icon: "stack" },
        { text: I18n.t("nav.settings"), icon: "sliders" }
    ]

    Item {
        id: scene
        anchors.fill: parent
        opacity: 1 - win.farewell

        // Title bar: brand on the left, the island in the middle, window controls on the right.
        Item {
            id: titleBar
            width: parent.width
            height: Theme.titleBar
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onPressed: win.startSystemMove()
                onDoubleClicked: win.toggleMaximized()
            }
            Row {
                id: brandRow
                x: 22
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                opacity: win.reveal
                SkullMark {
                    id: brand
                    objectName: "brand"
                    size: 28
                    anchors.verticalCenter: parent.verticalCenter
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "FAKE CLICKER"
                    font.pixelSize: 13
                    font.weight: Font.Black
                    font.letterSpacing: 1.8
                }
            }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                opacity: win.reveal
                AppButton { kind: "plain"; compact: true; width: 36; height: 32; iconName: "winMin"; iconSize: 15; Accessible.name: I18n.t("win.minimize"); onClicked: win.minimizeWindow() }
                AppButton { objectName: "maximizeButton"; kind: "plain"; compact: true; width: 36; height: 32; iconName: win.maximized ? "winRestore" : "winMax"; iconSize: 15; Accessible.name: I18n.t(win.maximized ? "win.restore" : "win.maximize"); onClicked: win.toggleMaximized() }
                AppButton {
                    objectName: "closeButton"
                    kind: hovered ? "danger" : "plain"
                    compact: true
                    width: 36; height: 32; iconName: "winClose"; iconSize: 15
                    Accessible.name: I18n.t("win.close")
                    onClicked: win.close()
                }
            }
        }

        Sidebar {
            id: sidebar
            y: Theme.titleBar
            height: parent.height - y
            opacity: win.reveal * win.languageFade
            items: win.navItems
            currentIndex: win.currentPage
            engine: clickEngine
            onActivated: index => win.currentPage = index
        }

        Item {
            id: content
            x: Theme.sidebarWidth
            y: Theme.titleBar + Math.round(8 * (1 - win.reveal))
            width: parent.width - x - 20
            height: parent.height - Theme.titleBar - 20
            opacity: win.reveal * win.languageFade
            PageFrame {
                index: 0; current: win.currentPage; title: I18n.t("nav.clicker")
                ClickerPage { anchors.fill: parent; engine: clickEngine; windowSheet: windowSheet }
            }
            PageFrame {
                index: 1; current: win.currentPage; title: I18n.t("nav.hotkeys")
                HotkeysPage { anchors.fill: parent; engine: clickEngine; keyboard: keyboard }
            }
            PageFrame {
                index: 2; current: win.currentPage; title: I18n.t("nav.profiles")
                ProfilesPage { anchors.fill: parent; engine: clickEngine; store: configs }
            }
            PageFrame {
                index: 3; current: win.currentPage; title: I18n.t("nav.settings")
                SettingsPage {
                    anchors.fill: parent
                    language: I18n.language
                    islandOverlay: prefs.islandOverlay
                    onLanguageRequested: code => win.setLanguage(code)
                    onIslandOverlayRequested: value => win.setIslandOverlay(value)
                }
            }
        }

        // Startup failure
        Panel {
            visible: startup.error !== ""
            anchors.centerIn: parent
            width: 420; height: 230
            Column {
                anchors.centerIn: parent
                width: parent.width - 56
                spacing: 14
                Icon { name: "warning"; size: 28; color: Theme.dangerText }
                Label { text: I18n.t("boot.failed"); font.pixelSize: Theme.title; font.weight: Font.Bold }
                Label { width: parent.width; wrapMode: Text.WordWrap; text: I18n.msg(startup.error); color: Theme.muted }
                AppButton { kind: "primary"; iconName: "reset"; text: I18n.t("boot.retry"); onClicked: startup.start() }
            }
        }

        DynamicIsland {
            id: island
            objectName: "island"
            engine: clickEngine
            booting: true
            visible: startup.error === "" && !overlay.wanted
            presentsEvents: !overlay.wanted
            x: island.snap((parent.width - width) / 2)
            y: island.snap(9)
        }
    }

    // Visibility comes from the splash's own opacity: an Item's `visible` already folds in its
    // parent's, so binding the container to splash.visible would keep both hidden forever.
    Item {
        anchors.fill: parent
        opacity: 1 - win.farewell
        visible: splash.opacity > 0.001 && startup.error === ""
        Splash {
            id: splash
            anchors.fill: parent
            opacity: 0
            progress: Math.min(startup.progress / 100, win.pacing)
            onChompFinished: { win.chomped = true; win.launch(); }
        }
    }

    // Pages crossfade quickly; the outgoing page leaves faster than the new one arrives.
    component PageFrame: Item {
        id: frame
        property int index: 0
        property int current: 0
        property string title
        default property alias page: body.data
        readonly property bool active: index === current
        anchors.fill: parent
        opacity: active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: frame.active ? Theme.base : Theme.fast; easing.type: Easing.OutCubic } }
        visible: opacity > 0.001
        enabled: active
        Label {
            y: 4
            text: frame.title
            font.pixelSize: Theme.pageTitle
            font.weight: Font.ExtraBold
            font.letterSpacing: -0.2
            font.capitalization: Font.AllUppercase
        }
        Item {
            id: body
            y: Theme.pageHeader
            width: parent.width
            height: parent.height - y
        }
    }

    // Frameless resize edges.
    Repeater {
        model: [
            { e: Qt.LeftEdge, c: Qt.SizeHorCursor }, { e: Qt.RightEdge, c: Qt.SizeHorCursor },
            { e: Qt.TopEdge, c: Qt.SizeVerCursor }, { e: Qt.BottomEdge, c: Qt.SizeVerCursor },
            { e: Qt.LeftEdge | Qt.TopEdge, c: Qt.SizeFDiagCursor }, { e: Qt.RightEdge | Qt.BottomEdge, c: Qt.SizeFDiagCursor },
            { e: Qt.RightEdge | Qt.TopEdge, c: Qt.SizeBDiagCursor }, { e: Qt.LeftEdge | Qt.BottomEdge, c: Qt.SizeBDiagCursor }
        ]
        MouseArea {
            required property var modelData
            readonly property bool onLeft: modelData.e & Qt.LeftEdge
            readonly property bool onRight: modelData.e & Qt.RightEdge
            readonly property bool onTop: modelData.e & Qt.TopEdge
            readonly property bool onBottom: modelData.e & Qt.BottomEdge
            readonly property bool corner: (onLeft || onRight) && (onTop || onBottom)
            x: onRight ? win.width - (corner ? 8 : 5) : onLeft ? 0 : 8
            y: onBottom ? win.height - (corner ? 8 : 5) : onTop ? 0 : 8
            width: onLeft || onRight ? (corner ? 8 : 5) : win.width - 16
            height: onTop || onBottom ? (corner ? 8 : 4) : win.height - 16
            enabled: !win.maximized
            hoverEnabled: true
            cursorShape: modelData.c
            onPressed: win.startSystemResize(modelData.e)
        }
    }
}
