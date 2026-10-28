import QtQuick
import QtQuick.Shapes
import CClicker
import "Icons.js" as Icons

// Vector icon tinted at runtime; strokes stay crisp at any size.
Item {
    id: icon
    property string name
    property color color: Theme.ink
    property real size: 20
    property real stroke: 1.8
    readonly property var glyph: Icons.get(name)
    implicitWidth: size
    implicitHeight: size
    Behavior on color { ColorAnimation { duration: Theme.base } }
    Shape {
        width: 24; height: 24
        anchors.centerIn: parent
        scale: icon.size / 24
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: icon.glyph.d ? icon.color : "transparent"
            strokeWidth: icon.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: icon.glyph.d || "" }
        }
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: icon.glyph.f ? icon.color : "transparent"
            PathSvg { path: icon.glyph.f || "" }
        }
    }
}
