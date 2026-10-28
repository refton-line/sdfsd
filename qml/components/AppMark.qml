import QtQuick
import QtQuick.Shapes
import CClicker

// Brand mark: a glass squircle holding an open "C" that ends in a click point.
Item {
    id: mark
    property real size: 28
    property real draw: 1      // 0..1 stroke reveal, used by the launch sequence
    implicitWidth: size
    implicitHeight: size
    Surface {
        anchors.fill: parent
        radius: mark.size * 0.3
        elevation: 0
        tintAlpha: 0.75
        solidColor: "#ffffff"
    }
    Rectangle {
        anchors.fill: parent
        radius: mark.size * 0.3
        color: "transparent"
        border.width: Theme.isGlass ? 0 : 0.5
        border.color: "#c6c6c8"
    }
    Shape {
        anchors.centerIn: parent
        width: 24; height: 24
        scale: mark.size / 24 * 0.8
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: Theme.ink
            strokeWidth: 3
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: 12; centerY: 12; radiusX: 7.2; radiusY: 7.2
                startAngle: -40; sweepAngle: -280 * mark.draw
            }
        }
        ShapePath {
            strokeColor: "transparent"
            fillColor: Theme.ink
            PathAngleArc {
                centerX: 12 + 7.2 * Math.cos(40 * Math.PI / 180) + 1.2
                centerY: 12 + 7.2 * Math.sin(40 * Math.PI / 180) + 1.2
                radiusX: 1.9 * mark.draw; radiusY: radiusX
                startAngle: 0; sweepAngle: 360
            }
        }
    }
}
