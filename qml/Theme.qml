pragma Singleton
import QtQuick

// Visual tokens for both materials. "glass" is Liquid Glass (refraction shader, floating tab bar,
// springs); "solid" is an iOS 14-style app (opaque grouped lists, sidebar, eased motion).
// Palette: getdesign.md "Apple" (#1d1d1f, #f5f5f7, #7a7a7a, #d2d2d7, #0071e3, #272729) and
// "Mobbin" (#f0f0f0, #e0e0e0, #adadad); status and iOS 14 tints are the iOS system colours.
Item {
    id: theme

    property string material: "glass"
    readonly property bool isGlass: material === "glass"
    property int modals: 0
    // False while the window is inactive: continuous motion pauses to save power.
    property bool animating: true

    // Backdrop textures for GlassSurface, provided by Main.qml.
    property Item backdropRoot: null
    property var wallTexture: null
    property var wallFrostTexture: null
    property var stageTexture: null
    property var stageFrostTexture: null

    // Neutrals
    readonly property color ink: "#1d1d1f"
    readonly property color inkSoft: "#3a3a3c"
    readonly property color muted: isGlass ? "#6e6e73" : "#8a8a8e"
    readonly property color faint: "#adadad"
    readonly property color canvas: "#f5f5f7"
    readonly property color white: "#ffffff"
    readonly property color field: "#f0f0f0"
    readonly property color hairline: "#e0e0e0"
    readonly property color separator: isGlass ? Qt.rgba(0, 0, 0, 0.07) : "#e0e0e5"
    readonly property color groupedBackground: "#f2f2f7"
    readonly property color cell: "#ffffff"
    readonly property color fill: Qt.rgba(0.463, 0.463, 0.502, 0.12)
    readonly property color fillStrong: Qt.rgba(0.463, 0.463, 0.502, 0.2)
    readonly property color well: isGlass ? Qt.rgba(0.463, 0.463, 0.502, 0.14) : fill
    readonly property color focusRing: "#0071e3"

    // Accent: monochrome on glass, iOS 14 system blue on solid.
    readonly property color accent: isGlass ? ink : "#007aff"
    readonly property color accentSoft: isGlass ? Qt.rgba(0.114, 0.114, 0.122, 0.08) : Qt.rgba(0, 0.478, 1, 0.12)

    readonly property color island: "#000000"
    readonly property color islandRaised: "#272729"
    readonly property color islandControl: "#2c2c2e"
    readonly property color islandText: "#f5f5f7"
    readonly property color islandMuted: "#8e8e93"

    readonly property color legit: "#34c759"
    readonly property color legitBright: "#30d158"
    readonly property color blatant: "#ff3b30"
    readonly property color blatantBright: "#ff453a"
    readonly property color arming: "#ff9500"
    readonly property color armingBright: "#ff9f0a"
    readonly property color danger: "#ff3b30"
    function modeColor(mode) { return mode === 1 ? blatant : legit; }
    function modeBright(mode) { return mode === 1 ? blatantBright : legitBright; }

    // Type
    readonly property string sans: "Inter"
    readonly property int display: 60
    readonly property int title: 22
    readonly property int headline: 15
    readonly property int body: 14
    readonly property int small: 12
    readonly property int caption: 11

    // Geometry
    readonly property real cardRadius: isGlass ? 30 : 10
    readonly property real rowHeight: isGlass ? 54 : 46
    readonly property real gap: isGlass ? 14 : 22
    readonly property real cardPadding: isGlass ? 20 : 16
    readonly property int titleBar: 60
    readonly property int sidebarWidth: 252
    readonly property int tabBarSpace: 100
    readonly property int baseWidth: 1080
    readonly property int baseHeight: 700

    // Motion: springs for glass, iOS 14 ease-out curves for solid.
    readonly property int fast: 140
    readonly property int base: 240
    readonly property int slow: 420
    readonly property real springStiff: 4.2
    readonly property real springDamp: 0.34
}
