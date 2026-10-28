import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Effects
import QtCore
import CClicker
import "components"

ApplicationWindow {
    id: win
    objectName: "mainWindow"
    visible: true
    title: "C clicker"
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
        island.booting = false;
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
    function toggleMaximized() { if (maximized) showNormal(); else showMaximized(); }

    Component.onCompleted: {
        I18n.language = prefs.language === "ru" ? "ru" : "en";
        Theme.material = prefs.material === "solid" ? "solid" : "glass";
        Theme.backdropRoot = stage;
        Theme.wallTexture = wallTex;
        Theme.wallFrostTexture = wallFrostTex;
        Theme.stageTexture = stageTex;
        Theme.stageFrostTexture = stageFrostTex;
        Theme.animating = true;
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

    Timer { id: minimumTimer; interval: 900; onTriggered: { win.minimumElapsed = true; win.launch(); } }
    Connections { target: startup; function onChanged() { win.launch(); } }
    Shortcut { sequence: "Escape"; enabled: island.pinned && Theme.modals === 0; onActivated: island.pinned = false }

    SequentialAnimation {
        id: launchAnimation
        NumberAnimation { target: win; property: "reveal"; to: 1; duration: 1100; easing.type: Easing.OutCubic }
        ScriptAction { script: clickEngine.setReady(true) }
    }
    SequentialAnimation {
        id: closeAnimation
        ScriptAction { script: { island.hidden = true; overlay.wanted = false; } }
        NumberAnimation { target: win; property: "reveal"; to: 0; duration: 380; easing.type: Easing.InCubic }
        NumberAnimation { target: stage; property: "opacity"; to: 0; duration: 160 }
        // The overlay is a second native window; take it down before the last window closes.
        ScriptAction { script: { overlay.visible = false; win.allowClose = true; win.close(); } }
    }
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
    readonly property real stageProgress: Math.max(0, Math.min(1, (reveal - 0.28) / 0.6))

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
            Item {
                id: content
                x: Theme.isGlass ? 24 : Theme.sidebarWidth + 24
                y: Theme.titleBar + 4 + 26 * (1 - win.stageProgress)
                width: parent.width - x - 24
                height: parent.height - Theme.titleBar - 4 - (Theme.isGlass ? Theme.tabBarSpace : 24)
                opacity: win.stageProgress * win.languageFade
                scale: Theme.isGlass ? 0.965 + 0.035 * win.stageProgress : 1
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

        // Navigation: a floating glass tab bar, or an iOS 14 sidebar.
        ClassicSidebar {
            visible: !Theme.isGlass
            readonly property real local: Math.max(0, Math.min(1, (win.reveal - 0.12) / 0.55))
            x: -40 * (1 - local)
            width: Theme.sidebarWidth
            height: parent.height
            opacity: local
            reveal: Math.max(0, Math.min(1, (win.reveal - 0.2) / 0.7)) * win.languageFade
            currentIndex: win.currentPage
            items: win.navItems
            onActivated: index => win.currentPage = index
        }
        LiquidTabBar {
            visible: Theme.isGlass
            readonly property real local: Math.max(0, Math.min(1, (win.reveal - 0.15) / 0.6))
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - height - 20 + 50 * (1 - local)
            opacity: local
            reveal: Math.max(0, Math.min(1, (win.reveal - 0.25) / 0.7)) * win.languageFade
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
                visible: Theme.isGlass
                x: 22; anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                opacity: Math.max(0, Math.min(1, (win.reveal - 0.35) / 0.4))
                AppMark { size: 28; draw: Math.max(0, Math.min(1, (win.reveal - 0.3) / 0.5)); anchors.verticalCenter: parent.verticalCenter }
                Label { text: I18n.t("app"); font.pixelSize: 14; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
            }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.isGlass ? 8 : 2
                opacity: Math.max(0, Math.min(1, (win.reveal - 0.45) / 0.4))
                AppButton { kind: Theme.isGlass ? "normal" : "plain"; compact: true; width: 34; height: 34; iconName: "winMin"; iconSize: 16; Accessible.name: I18n.t("win.minimize"); onClicked: win.showMinimized() }
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

        // The island boots in the middle of the window, then rises into the title bar.
        DynamicIsland {
            id: island
            objectName: "island"
            engine: clickEngine
            booting: true
            bootProgress: bootRing.value
            visible: startup.error === ""
            x: (parent.width - width) / 2
            property real rise: win.launched ? 1 : 0
            Behavior on rise { SpringAnimation { spring: 2.6; damping: 0.3; epsilon: 0.001 } }
            y: (win.height / 2 - 21) * (1 - rise) + 11 * rise
            QtObject {
                id: bootRing
                property real value: startup.progress / 100
                Behavior on value { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
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
