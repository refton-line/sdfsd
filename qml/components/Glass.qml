import QtQuick
import QtQuick.Shapes
import CClicker

// Liquid Glass surface. Theme.glass blends it into an opaque iOS 14-style card:
// translucent fill, top sheen, a two-sided specular rim and a soft contact shadow.
Item {
    id: glass
    property real radius: Theme.radiusLarge
    property color tint: "transparent"
    property real elevation: 1
    property bool interactive: false
    property real lightX: width * 0.3
    property real lightY: 0
    property bool lit: false
    property real fillOpacity: 1

    BorderImage {
        // shadow.png: 48px rounded rect with a 40px soft falloff on every side.
        x: -40 + 3; y: -40 + 3 + 5 * glass.elevation
        width: parent.width + 80 - 6; height: parent.height + 80 - 6
        source: "qrc:/qt/qml/CClicker/assets/shadow.png"
        border { left: 56; right: 56; top: 56; bottom: 56 }
        opacity: glass.elevation <= 0 ? 0 : (0.10 + 0.22 * Theme.glass) * Math.min(1.5, glass.elevation)
        visible: opacity > 0.01 && width >= 112 && height >= 112
    }
    Rectangle {
        id: body
        anchors.fill: parent
        radius: glass.radius
        color: Theme.surface
        opacity: glass.fillOpacity
        border.width: 1
        border.color: Theme.edge
    }
    Rectangle {
        anchors.fill: parent
        radius: glass.radius
        color: glass.tint
        visible: glass.tint.a > 0
    }
    // Sheen: the upper body catches light, the base keeps a little thickness.
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: glass.radius - 1
        opacity: Theme.glass
        visible: opacity > 0.01
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.42) }
            GradientStop { position: 0.38; color: Qt.rgba(1, 1, 1, 0.06) }
            GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0.16) }
        }
    }
    // Pointer light for interactive glass.
    Item {
        anchors.fill: parent
        visible: glass.interactive && Theme.glass > 0.01
        opacity: glass.lit ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: glass.lightX; centerY: glass.lightY
                    focalX: centerX; focalY: centerY
                    centerRadius: Math.max(glass.width, glass.height) * 0.7
                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.55 * Theme.glass) }
                    GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
                }
                PathRectangle { width: glass.width; height: glass.height; radius: glass.radius }
            }
        }
    }
    // Specular rim: bright at the top-left, fading, then catching again at the bottom-right.
    Shape {
        anchors.fill: parent
        opacity: Theme.glass
        visible: opacity > 0.01
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "transparent"
            fillRule: ShapePath.OddEvenFill
            fillGradient: LinearGradient {
                x1: 0; y1: 0; x2: glass.width; y2: glass.height
                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.98) }
                GradientStop { position: 0.32; color: Qt.rgba(1, 1, 1, 0.28) }
                GradientStop { position: 0.7; color: Qt.rgba(1, 1, 1, 0.12) }
                GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0.75) }
            }
            PathRectangle { x: 0; y: 0; width: glass.width; height: glass.height; radius: glass.radius }
            PathRectangle { x: 1.2; y: 1.2; width: glass.width - 2.4; height: glass.height - 2.4; radius: Math.max(0, glass.radius - 1.2) }
        }
    }
}
