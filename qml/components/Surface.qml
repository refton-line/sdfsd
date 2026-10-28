import QtQuick
import LightClicker

// Card background for either material: a Liquid Glass panel or an opaque iOS 14 cell group.
Item {
    id: surface
    property real radius: Theme.cardRadius
    property bool floating: false
    property real tintAlpha: 0.36
    property real frost: 1
    property real magnify: 0
    property real elevation: 1
    property color solidColor: Theme.cell
    property bool solidShadow: false

    BorderImage {
        // shadow.png: 48 px rounded rect with a 40 px soft falloff.
        visible: surface.elevation > 0 && (Theme.isGlass || surface.solidShadow) && surface.width >= 40 && surface.height >= 40
        x: -37; y: -37 + 6 * surface.elevation
        width: parent.width + 74; height: parent.height + 74
        source: "qrc:/qt/qml/LightClicker/assets/shadow.png"
        border { left: 56; right: 56; top: 56; bottom: 56 }
        opacity: Theme.isGlass ? 0.26 * Math.min(1.6, surface.elevation) : 0.16
    }
    Loader {
        anchors.fill: parent
        active: Theme.isGlass
        sourceComponent: GlassSurface {
            radius: surface.radius
            floating: surface.floating
            frost: surface.frost
            magnify: surface.magnify
            tintColor: Qt.rgba(1, 1, 1, surface.tintAlpha)
        }
    }
    Rectangle {
        anchors.fill: parent
        visible: !Theme.isGlass
        radius: surface.radius
        color: surface.solidColor
    }
}
