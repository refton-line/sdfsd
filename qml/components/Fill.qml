import QtQuick
import LightClicker

// Drop-in for a filled Rectangle. Solid: exactly that rectangle. Glass: Liquid Glass tinted with
// the same colour, so selections, tiles, chips and wells stay glass too. Opaque colours become
// strongly tinted glass; faint ones (fills, wells) are strengthened so the tint still reads.
Item {
    id: fill
    property color color: "transparent"
    property real radius: 0
    property bool inset: false
    property bool floating: false
    property bool detached: false
    property real strength: 0.74          // tint alpha used for opaque colours
    property real frost: 1
    property real magnify: 0

    Loader {
        anchors.fill: parent
        active: Theme.isGlass && fill.color.a > 0.001
        sourceComponent: GlassSurface {
            radius: fill.radius
            floating: fill.floating
            detached: fill.detached
            inset: fill.inset
            frost: fill.frost
            magnify: fill.magnify
            rim: fill.inset ? 0.4 : 0.85
            dispersion: fill.inset ? 0.5 : 1.2
            tintColor: Qt.rgba(fill.color.r, fill.color.g, fill.color.b,
                               fill.color.a > 0.98 ? fill.strength
                               : fill.color.a < 0.3 ? fill.color.a * (fill.inset ? 1.0 : 2.0) : fill.color.a)
        }
    }
    Rectangle {
        anchors.fill: parent
        visible: !Theme.isGlass
        radius: fill.radius
        color: fill.color
    }
}
