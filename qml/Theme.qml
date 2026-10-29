pragma Singleton
import QtQuick

// Fake Clicker design tokens. One dark theme, pure monochrome: the interface is black, graphite
// and white, and colour appears only where it carries state — Legit is Nike Success green,
// Blatant is Nike Sale red. References: projectreal.gg (black canvas, graphite panels, hairline
// edges, white pill CTAs, Geist) and getdesign.md/nike (ink/stone/ash greys, #1EAA52, #D30005).
QtObject {
    property int modals: 0
    // False while the window is inactive: live animations pause to save power.
    property bool animating: true

    // Surfaces, darkest to lightest
    readonly property color canvas: "#000000"
    readonly property color panel: "#0B0B0B"
    readonly property color raised: "#121212"
    readonly property color control: "#181818"
    readonly property color controlHover: "#202020"
    readonly property color controlActive: "#2A2A2A"
    readonly property color hairline: "#1C1C1C"
    readonly property color hairlineStrong: "#2C2C2C"

    // Text
    readonly property color ink: "#FFFFFF"
    readonly property color inkSoft: "#C9C9CB"
    readonly property color muted: "#8E8E91"
    readonly property color faint: "#5C5C5F"
    readonly property color inverse: "#0A0A0A"

    // State: the only colours in the interface
    readonly property color legit: "#1EAA52"
    readonly property color blatant: "#D30005"
    readonly property color danger: "#D30005"
    // Lifted red for small text and glyphs on black, where #D30005 is too dim to read.
    readonly property color dangerText: "#FF4D52"
    function modeColor(mode) { return mode === 1 ? blatant : legit; }
    function tint(color, alpha) { return Qt.rgba(color.r, color.g, color.b, alpha); }

    readonly property color focusRing: Qt.rgba(1, 1, 1, 0.6)
    readonly property color selection: Qt.rgba(1, 1, 1, 0.28)

    // Dynamic Island
    readonly property color island: "#0A0A0A"
    readonly property color islandEdge: "#262626"
    readonly property color islandControl: "#1B1B1B"
    readonly property color islandControlHover: "#262626"
    readonly property color islandText: "#FFFFFF"
    readonly property color islandMuted: "#8E8E91"

    // Type: Geist for text, Geist Mono for captions, units and key caps
    readonly property string sans: "Geist"
    readonly property string mono: "Geist Mono"
    readonly property int display: 64
    readonly property int pageTitle: 26
    readonly property int title: 20
    readonly property int headline: 15
    readonly property int body: 14
    readonly property int small: 12
    readonly property int caption: 11

    // Geometry
    readonly property real radius: 14
    readonly property real controlRadius: 10
    readonly property real smallRadius: 6
    readonly property int rowHeight: 52
    readonly property int gap: 12
    readonly property int pad: 20
    readonly property int titleBar: 56
    readonly property int sidebarWidth: 208
    readonly property int pageHeader: 52
    readonly property int baseWidth: 1080
    readonly property int baseHeight: 700

    // Motion: short and eased. No springs, bounces or overshoot anywhere.
    readonly property int fast: 110
    readonly property int base: 160
    readonly property int slow: 240
}
