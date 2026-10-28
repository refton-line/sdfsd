import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Effects
import QtCore
import LightClicker
import "components"

ApplicationWindow {
    id: win
    objectName: "mainWindow"
    visible: true
    title: "Light clicker"
    readonly property real fit: Math.min(1, (Screen.desktopAvailableWidth - 48) / Theme.baseWidth, (Screen.desktopAvailableHeight - 48) / Theme.baseHeight)
    width: uiCapture ? Theme.baseWidth : Math.round(Theme.baseWidth * fit)
    height: uiCapture ? Theme.baseHeight : Math.round(Theme.baseHeight * fit)
    minimumWidth: Math.min(980, width)
    minimumHeight: Math.min(660, height)
    color: Theme.isGlass ? "#e4e6eb" : Theme.groupedBackground
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowMinMaxButtonsHint | Qt.WindowSystemMenuHint

    Settings {
        id: prefs
        category: "ui"
        property string language: "en"
        property string material: "glass"
        property bool islandOverlay: true
    }

    property real reveal: 0           // 0 → 1 on launch, back to 0 on close
    property real brandFly: 0         // the loading mark flying from the centre to its place
    property real appear: 0           // launch intro: wallpaper and star fade in from the plain window
    property real loadRamp: 0         // paces the star's loading fill so it never jumps
    property real drain: 0            // close: the star's ink half empties again
    property real farewell: 0         // close: star and wallpaper fade back to the plain window
    property bool folded: false       // UI folded away for minimize; unfolds when the window returns
    // Maximize/restore morph: the UI, laid out for the new size, starts where the old window was.
    property rect morphFrom: Qt.rect(0, 0, 0, 0)
    property real morph: 1
    property bool morphPending: false
    readonly property real morphE: 1 - morph
    readonly property real morphSx: morphFrom.width > 0 ? 1 + (morphFrom.width / Math.max(1, width) - 1) * morphE : 1
    readonly property real morphSy: morphFrom.height > 0 ? 1 + (morphFrom.height / Math.max(1, height) - 1) * morphE : 1
    readonly property real morphDx: morphFrom.width > 0 ? (morphFrom.x - x) * morphE : 0
    readonly property real morphDy: morphFrom.height > 0 ? (morphFrom.y - y) * morphE : 0
    property bool launched: false
    property bool minimumElapsed: false
    property bool exiting: false
    property bool allowClose: false
    property int currentPage: 0
    property real languageFade: 1
    property string pendingLanguage: ""
    property real blurAmount: Theme.modals > 0 && Theme.isGlass ? 0.65 : 0
    Behavior on blurAmount { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
    readonly property bool maximized: visibility === Window.Maximized
    readonly property bool engineActive: clickEngine.active
    property bool lingering: false
    onActiveChanged: Theme.animating = active || uiCapture

    function launch() {
        if (launched || exiting || !startup.done || !minimumElapsed)
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
    // The whole app changes material: snapshot, switch underneath, wash the old look away from x/y.
    function setMaterial(value, x, y) {
        if (Theme.material === value || skinReveal.running)
            return;
        const apply = () => {
            Theme.material = value;
            prefs.material = value;
            island.notify(value === "glass" ? "sparkle" : "square", I18n.t(value === "glass" ? "look.glass" : "look.solid"), Theme.islandText);
        };
        if (!launched) {
            apply();
            return;
        }
        skinReveal.begin(scene, x === undefined ? width / 2 : x, y === undefined ? height / 2 : y, apply);
    }
    // Smoothstep of v over [a, a + length]: staggered parts ease in and out on their own.
    function span(v, a, length) {
        const t = Math.max(0, Math.min(1, (v - a) / length));
        return t * t * (3 - 2 * t);
    }
    function toggleMaximized() {
        morphAnimation.stop();
        morphFrom = Qt.rect(x, y, width, height);
        morph = 0;
        morphPending = true;
        morphFallback.restart();
        if (maximized) showNormal(); else showMaximized();
    }
    function beginMorph() {
        morphPending = false;
        morphFallback.stop();
        morphAnimation.restart();
    }
    // The UI sinks toward the taskbar first; the star stays, so the taskbar preview shows the logo.
    function minimizeAnimated() {
        if (exiting || minimizeAnimation.running)
            return;
        if (!launched) {
            showMinimized();
            return;
        }
        minimizeAnimation.start();
    }
    onWidthChanged: if (morphPending) beginMorph()
    onHeightChanged: if (morphPending) beginMorph()
    onVisibilityChanged: function() {
        if (folded && !minimizeAnimation.running && win.visibility !== Window.Minimized && win.visibility !== Window.Hidden)
            unfold();
    }
    function unfold() {
        folded = false;
        unfoldFallback.stop();
        unfoldAnimation.restart();
    }

    Component.onCompleted: {
        I18n.language = prefs.language === "ru" ? "ru" : "en";
        Theme.material = prefs.material === "solid" ? "solid" : "glass";
        Theme.backdropRoot = stage;
        Theme.wallTexture = wallTex;
        Theme.wallFrostTexture = wallFrostTex;
        Theme.stageTexture = stageTex;
        Theme.stageFrostTexture = stageFrostTex;
        Theme.animating = true;
        introAnimation.start();
        startup.start();
        minimumTimer.start();
    }
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
            launchAnimation.stop();
            closeAnimation.start();
        }
    }

    Timer { id: minimumTimer; interval: 1150 * motionScale; onTriggered: { win.minimumElapsed = true; win.launch(); } }
    Connections { target: startup; function onChanged() { win.launch(); } }
    Shortcut { sequence: "Escape"; enabled: island.pinned && Theme.modals === 0; onActivated: island.pinned = false }

    // Launch: the plain window warms up into the wallpaper while the star fades in and fills. Every
    // stage starts slowly (in-out curves), so nothing snaps at the start.
    ParallelAnimation {
        id: introAnimation
        NumberAnimation { target: win; property: "appear"; to: 1; duration: 720 * motionScale; easing.type: Easing.InOutSine }
        SequentialAnimation {
            PauseAnimation { duration: 240 * motionScale }
            NumberAnimation { target: win; property: "loadRamp"; to: 1; duration: 860 * motionScale; easing.type: Easing.InOutSine }
        }
    }
    SequentialAnimation {
        id: launchAnimation
        ParallelAnimation {
            NumberAnimation { target: win; property: "brandFly"; to: 1; duration: 860 * motionScale; easing.type: Easing.InOutCubic }
            SequentialAnimation {
                PauseAnimation { duration: 260 * motionScale }
                NumberAnimation { target: win; property: "reveal"; to: 1; duration: 1100 * motionScale; easing.type: Easing.InOutCubic }
            }
            SequentialAnimation {
                PauseAnimation { duration: 520 * motionScale }
                ScriptAction { script: island.booting = false }
            }
        }
        ScriptAction { script: clickEngine.setReady(true) }
    }
    // Close mirrors the launch: the UI folds away, the star flies back to the centre, its ink drains
    // from the top, then star and wallpaper fade into the plain window, which closes.
    SequentialAnimation {
        id: closeAnimation
        ScriptAction { script: { island.hidden = true; overlay.wanted = false; } }
        ParallelAnimation {
            NumberAnimation { target: win; property: "reveal"; to: 0; duration: 420 * motionScale; easing.type: Easing.InOutCubic }
            NumberAnimation { target: win; property: "morph"; to: 1; duration: 200 * motionScale }
            SequentialAnimation {
                PauseAnimation { duration: 140 * motionScale }
                NumberAnimation { target: win; property: "brandFly"; to: 0; duration: 500 * motionScale; easing.type: Easing.InOutCubic }
            }
            SequentialAnimation {
                PauseAnimation { duration: 380 * motionScale }
                NumberAnimation { target: win; property: "drain"; to: 1; duration: 300 * motionScale; easing.type: Easing.InOutSine }
            }
        }
        NumberAnimation { target: win; property: "farewell"; to: 1; duration: 260 * motionScale; easing.type: Easing.InCubic }
        // The overlay is a second native window; take it down before the last window closes.
        ScriptAction { script: { overlay.visible = false; win.allowClose = true; win.close(); } }
    }
    SequentialAnimation {
        id: minimizeAnimation
        ScriptAction { script: { win.folded = true; island.hidden = true; } }
        NumberAnimation { target: win; property: "reveal"; to: 0; duration: 300 * motionScale; easing.type: Easing.InCubic }
        ScriptAction { script: { win.showMinimized(); unfoldFallback.restart(); } }
    }
    SequentialAnimation {
        id: unfoldAnimation
        ScriptAction { script: island.hidden = false }
        NumberAnimation { target: win; property: "reveal"; to: 1; duration: 640 * motionScale; easing.type: Easing.InOutCubic }
    }
    // Without a window manager honouring the request the window never minimizes: unfold again.
    Timer { id: unfoldFallback; interval: 700 * motionScale; onTriggered: if (win.folded && win.visibility !== Window.Minimized) win.unfold() }
    NumberAnimation {
        id: morphAnimation
        target: win; property: "morph"; to: 1; duration: 440 * motionScale
        easing.type: Easing.BezierSpline; easing.bezierCurve: [0.25, 0.1, 0.25, 1, 1, 1]
    }
    // The window state did not change (or no window manager): drop the morph without a jump.
    Timer { id: morphFallback; interval: 500 * motionScale; onTriggered: { if (win.morphPending) { win.morphPending = false; win.morph = 1; } } }
    SequentialAnimation {
        id: languageSwap
        NumberAnimation { target: win; property: "languageFade"; to: 0; duration: 140; easing.type: Easing.InQuad }
        ScriptAction {
            script: {
                I18n.language = win.pendingLanguage;
                prefs.language = win.pendingLanguage;
                island.notify("globe", win.pendingLanguage === "ru" ? "Русский" : "English", Theme.islandText);
            }
        }
        NumberAnimation { target: win; property: "languageFade"; to: 1; duration: 340; easing.type: Easing.OutCubic }
    }

    readonly property int engineMode: clickEngine.mode
    onEngineModeChanged: if (launched && !island.expanded) island.notify(engineMode === 1 ? "bolt" : "hand", I18n.t(engineMode === 1 ? "mode.blatant" : "mode.legit"), Theme.modeBright(engineMode))
    readonly property string engineError: clickEngine.error
    onEngineErrorChanged: if (engineError !== "") { island.showError(I18n.msg(engineError)); overlay.island.showError(I18n.msg(engineError)); }
    Connections {
        target: configs
        function onNoticed(code, ok) {
            island.notify(ok ? "checkCircle" : "warning", I18n.msg(code), ok ? Theme.legitBright : Theme.blatantBright);
        }
    }
    onEngineActiveChanged: if (!engineActive && launched) { lingering = true; lingerTimer.restart(); }
    Timer { id: lingerTimer; interval: 3400; onTriggered: win.lingering = false }

    IslandOverlay {
        id: overlay
        engine: clickEngine
        wanted: prefs.islandOverlay && win.launched && !win.exiting && !win.active && (clickEngine.active || win.lingering)
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
        { text: I18n.t("nav.appearance"), icon: "drop" },
        { text: I18n.t("nav.language"), icon: "globe" }
    ]
    readonly property real stageProgress: span(reveal, 0.28, 0.6)

    Item {
        id: scene
        anchors.fill: parent
        layer.enabled: win.blurAmount > 0.001
        layer.effect: MultiEffect { blurEnabled: true; blurMax: 48; blur: win.blurAmount; saturation: 0.1 }

        // Everything glass may refract: wallpaper and pages.
        Item {
            id: stage
            anchors.fill: parent
            Wallpaper {
                id: wallpaper
                anchors.fill: parent
                running: Theme.animating && !win.exiting
            }
            // The plain window colour over the wallpaper: lifts during the intro, returns on close.
            Rectangle {
                anchors.fill: parent
                color: win.color
                opacity: 1 - win.span(win.appear, 0, 1) * (1 - win.farewell)
                visible: opacity > 0.001
            }
            Item {
                id: content
                x: Theme.isGlass ? 24 : Theme.sidebarWidth + 24
                y: Theme.titleBar + 4 + 26 * (1 - win.stageProgress)
                width: parent.width - x - 24
                height: parent.height - Theme.titleBar - 4 - (Theme.isGlass ? Theme.tabBarSpace : 24)
                opacity: win.stageProgress * win.languageFade
                scale: Theme.isGlass ? 0.965 + 0.035 * win.stageProgress : 1
                transform: [
                    Scale { origin.x: -content.x; origin.y: -content.y; xScale: win.morphSx; yScale: win.morphSy },
                    Translate { x: win.morphDx; y: win.morphDy }
                ]
                PageFrame {
                    index: 0; current: win.currentPage
                    ClickerPage { anchors.fill: parent; engine: clickEngine }
                }
                PageFrame {
                    index: 1; current: win.currentPage
                    HotkeysPage { anchors.fill: parent; engine: clickEngine; keyboard: keyboard }
                }
                PageFrame {
                    index: 2; current: win.currentPage
                    ProfilesPage { anchors.fill: parent; engine: clickEngine; store: configs }
                }
                PageFrame {
                    index: 3; current: win.currentPage
                    AppearancePage {
                        anchors.fill: parent
                        material: Theme.material
                        islandOverlay: prefs.islandOverlay
                        onMaterialRequested: (value, x, y) => win.setMaterial(value, x, y)
                        onIslandOverlayRequested: value => prefs.islandOverlay = value
                    }
                }
                PageFrame {
                    index: 4; current: win.currentPage
                    LanguagePage {
                        anchors.fill: parent
                        language: I18n.language
                        onLanguageRequested: code => win.setLanguage(code)
                    }
                }
            }
        }

        // Backdrop textures for GlassSurface; only alive in the glass material.
        ShaderEffectSource { id: wallTex; sourceItem: Theme.isGlass ? wallpaper : null; visible: false }
        MultiEffect {
            id: wallBlur
            width: stage.width; height: stage.height
            visible: Theme.isGlass
            source: wallTex
            autoPaddingEnabled: false
            blurEnabled: true; blur: 1; blurMax: 64
        }
        ShaderEffectSource {
            id: wallFrostTex
            sourceItem: Theme.isGlass ? wallBlur : null
            hideSource: true; visible: false
            textureSize: Qt.size(Math.max(1, stage.width / 3), Math.max(1, stage.height / 3))
        }
        ShaderEffectSource { id: stageTex; sourceItem: Theme.isGlass ? stage : null; visible: false }
        MultiEffect {
            id: stageBlur
            width: stage.width; height: stage.height
            visible: Theme.isGlass
            source: stageTex
            autoPaddingEnabled: false
            blurEnabled: true; blur: 1; blurMax: 48
        }
        ShaderEffectSource {
            id: stageFrostTex
            sourceItem: Theme.isGlass ? stageBlur : null
            hideSource: true; visible: false
            textureSize: Qt.size(Math.max(1, stage.width / 3), Math.max(1, stage.height / 3))
        }

        // Everything above the stage. It shares the content's maximize/restore morph.
        Item {
            id: chrome
            anchors.fill: parent
            transform: [
                Scale { xScale: win.morphSx; yScale: win.morphSy },
                Translate { x: win.morphDx; y: win.morphDy }
            ]
            // Navigation: a floating glass tab bar, or an iOS 14 sidebar.
            ClassicSidebar {
                id: sidebar
                visible: !Theme.isGlass
                readonly property real local: win.span(win.reveal, 0.12, 0.55)
                x: -40 * (1 - local)
                width: Theme.sidebarWidth
                height: parent.height
                opacity: local
                reveal: win.span(win.reveal, 0.2, 0.7) * win.languageFade
                currentIndex: win.currentPage
                items: win.navItems
                onActivated: index => win.currentPage = index
            }
            LiquidTabBar {
                visible: Theme.isGlass
                readonly property real local: win.span(win.reveal, 0.15, 0.6)
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height - height - 20 + 50 * (1 - local)
                opacity: local
                reveal: win.span(win.reveal, 0.25, 0.7) * win.languageFade
                currentIndex: win.currentPage
                items: win.navItems
                onActivated: index => win.currentPage = index
            }

            // Title bar: drag, maximize on double-click, window controls.
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
                    anchors.right: parent.right; anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.isGlass ? 8 : 2
                    opacity: win.span(win.reveal, 0.45, 0.4)
                    AppButton { kind: Theme.isGlass ? "normal" : "plain"; compact: true; width: 34; height: 34; iconName: "winMin"; iconSize: 16; Accessible.name: I18n.t("win.minimize"); onClicked: win.minimizeAnimated() }
                    AppButton { objectName: "maximizeButton"; kind: Theme.isGlass ? "normal" : "plain"; compact: true; width: 34; height: 34; iconName: win.maximized ? "winRestore" : "winMax"; iconSize: 16; Accessible.name: I18n.t(win.maximized ? "win.restore" : "win.maximize"); onClicked: win.toggleMaximized() }
                    AppButton {
                        objectName: "closeButton"
                        kind: hovered ? "danger" : Theme.isGlass ? "normal" : "plain"
                        compact: true
                        width: 34; height: 34; iconName: "winClose"; iconSize: 16
                        Accessible.name: I18n.t("win.close")
                        onClicked: win.close()
                    }
                }
            }

            // Startup failure
            Card {
                visible: startup.error !== ""
                anchors.centerIn: parent
                width: 420; height: 230
                Column {
                    anchors.centerIn: parent
                    width: parent.width - 56
                    spacing: 14
                    Icon { name: "warning"; size: 30; color: Theme.danger }
                    Label { text: I18n.t("boot.failed"); font.pixelSize: Theme.title; font.weight: Font.DemiBold }
                    Label { width: parent.width; wrapMode: Text.WordWrap; text: I18n.msg(startup.error); color: Theme.muted }
                    AppButton { kind: "primary"; iconName: "reset"; text: I18n.t("boot.retry"); onClicked: startup.start() }
                }
            }

            // The island grows out of the title bar once the star is on its way.
            DynamicIsland {
                id: island
                objectName: "island"
                engine: clickEngine
                booting: true
                visible: startup.error === ""
                x: (parent.width - width) / 2
                y: 11
            }

            // Launch: the split star loads in the middle (its ink half fills with startup progress), then flies
            // into the title bar (glass) or the sidebar (solid) and stays there as the logo.
            AppMark {
                id: brand
                objectName: "brand"
                visible: startup.error === ""
                readonly property real fly: win.brandFly
                readonly property real homeSize: Theme.isGlass ? 34 : 44
                readonly property real homeX: Theme.isGlass ? 22 : 24 + sidebar.x
                readonly property real homeY: Theme.isGlass ? (Theme.titleBar - homeSize) / 2 : 44
                size: 128 + (homeSize - 128) * fly
                x: (win.width - size) / 2 + (homeX - (win.width - size) / 2) * fly
                y: (win.height - size) / 2 + (homeY - (win.height - size) / 2) * fly
                progress: Math.min(bootRing.value, win.loadRamp) * (1 - win.drain)
                readonly property real appearE: win.span(win.appear, 0.1, 0.9)
                scale: (0.86 + 0.14 * appearE) * (1 - 0.18 * win.farewell)
                opacity: appearE * (1 - win.farewell)
                QtObject {
                    id: bootRing
                    property real value: startup.progress / 100
                    Behavior on value { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
                }
            }
        }
    }

    SkinReveal {
        id: skinReveal
        anchors.fill: parent
    }

    // Glass pages lift and settle on springs; solid pages slide like an iOS 14 push.
    component PageFrame: Item {
        id: frame
        property int index: 0
        property int current: 0
        readonly property bool active: index === current
        property real shift: active ? 0 : index < current ? -1 : 1
        Behavior on shift { SpringAnimation { spring: Theme.isGlass ? 3.0 : 5; damping: Theme.isGlass ? 0.36 : 1; epsilon: 0.002 } }
        anchors.fill: parent
        opacity: active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: frame.active ? 360 : 140; easing.type: frame.active ? Easing.OutCubic : Easing.InCubic } }
        visible: opacity > 0.001
        enabled: active
        transform: [
            Translate { x: Theme.isGlass ? 0 : frame.shift * 48; y: Theme.isGlass ? frame.shift * 24 : 0 },
            Scale {
                origin.x: frame.width / 2; origin.y: frame.height / 2
                xScale: Theme.isGlass ? 1 - 0.035 * Math.abs(frame.shift) : 1
                yScale: xScale
            }
        ]
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
