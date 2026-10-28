pragma Singleton
import QtQuick

// Single source of visual tokens. Palette: getdesign.md "Apple" (parchment #f5f5f7, ink #1d1d1f,
// muted #7a7a7a, chip #d2d2d7, focus #0071e3) and "Mobbin" (field #f0f0f0, hairline #e0e0e0,
// faint #adadad). Status tints are the iOS system colours.
Item {
    id: theme

    // "glass" = translucent Liquid Glass, "solid" = opaque iOS 14-style surfaces.
    property string material: "glass"
    // Animated 0..1 blend between the two materials, so switching morphs instead of snapping.
    property real glass: material === "glass" ? 1 : 0
    // Open modal sheets; the window content blurs while this is non-zero.
    property int modals: 0
    property bool animateGlass: false
    Behavior on glass { enabled: theme.animateGlass; NumberAnimation { duration: 700; easing.type: Easing.InOutCubic } }

    // Neutrals
    readonly property color ink: "#1d1d1f"
    readonly property color inkSoft: "#3a3a3c"
    readonly property color muted: "#7a7a7a"
    readonly property color faint: "#adadad"
    readonly property color canvas: "#f5f5f7"
    readonly property color pearl: "#fafafc"
    readonly property color white: "#ffffff"
    readonly property color field: "#f0f0f0"
    readonly property color hairline: "#e0e0e0"
    readonly property color chip: Qt.rgba(0.824, 0.824, 0.843, 0.64)
    readonly property color focusRing: "#0071e3"
    readonly property color island: "#000000"
    readonly property color islandRaised: "#272729"
    readonly property color islandText: "#f5f5f7"
    readonly property color islandMuted: "#8e8e93"

    // Status (light UI / on the black island)
    readonly property color legit: "#34c759"
    readonly property color legitBright: "#30d158"
    readonly property color blatant: "#ff3b30"
    readonly property color blatantBright: "#ff453a"
    readonly property color arming: "#ff9500"
    readonly property color armingBright: "#ff9f0a"
    readonly property color danger: "#ff3b30"
    function modeColor(mode) { return mode === 1 ? blatant : legit; }
    function modeBright(mode) { return mode === 1 ? blatantBright : legitBright; }

    // Surfaces, interpolated by `glass`
    readonly property color backdrop: Qt.rgba(0.949, 0.949, 0.969, 1) // #f2f2f7, iOS grouped background
    readonly property color surface: Qt.rgba(1, 1, 1, 1 - 0.56 * glass)
    readonly property color surfaceStrong: Qt.rgba(1, 1, 1, 1 - 0.32 * glass)
    readonly property color well: Qt.rgba(0.463, 0.463, 0.502, 0.08 + 0.02 * glass)
    readonly property color rim: Qt.rgba(1, 1, 1, 0.85 * glass)
    readonly property color edge: Qt.rgba(0, 0, 0, 0.05 + 0.03 * (1 - glass))
    readonly property color pressedTint: Qt.rgba(0, 0, 0, 0.06)
    readonly property color hoverTint: Qt.rgba(1, 1, 1, 0.5)

    // Type (Inter, bundled; tabular figures for numbers)
    readonly property string sans: "Inter"
    readonly property int display: 56
    readonly property int title: 22
    readonly property int headline: 15
    readonly property int body: 14
    readonly property int small: 12
    readonly property int caption: 11

    // Geometry
    readonly property int radiusSmall: 10
    readonly property int radius: 14
    readonly property int radiusLarge: 22
    readonly property int radiusXL: 28
    readonly property int gutter: 16
    readonly property int sidebarWidth: 208
    readonly property int topBar: 60
    readonly property int baseWidth: 1080
    readonly property int baseHeight: 700

    // Motion. Springs give the liquid overshoot; durations are for fades and colour.
    readonly property int fast: 140
    readonly property int base: 240
    readonly property int slow: 420
    readonly property int pageOut: 150
    readonly property int pageIn: 420
    readonly property real springStiff: 4.2
    readonly property real springDamp: 0.34
    readonly property real springSoft: 2.6
    readonly property real springSoftDamp: 0.26
}
