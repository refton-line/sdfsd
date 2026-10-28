import QtQuick
import QtQuick.Shapes
import CClicker

// Glass: a grey-white field with slowly orbiting light and graphite masses and a few thin
// silver arcs, enough structure for the glass to visibly bend and frost it.
// Solid: the flat iOS grouped background.
Item {
    id: paper
    property bool running: true
    clip: true

    Rectangle {
        anchors.fill: parent
        color: Theme.groupedBackground
        visible: !Theme.isGlass
    }
    Item {
        anchors.fill: parent
        visible: Theme.isGlass
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: "#f3f4f7" }
                GradientStop { position: 0.55; color: "#e4e6eb" }
                GradientStop { position: 1; color: "#d3d6dd" }
            }
        }
        Repeater {
            model: [
                { c: "#ffffff", a: 1.0, r: 0.42, x: 0.16, y: 0.12, dx: 0.10, dy: 0.07, t: 26000 },
                { c: "#2f3238", a: 0.72, r: 0.28, x: 0.30, y: 0.62, dx: 0.12, dy: 0.10, t: 31000 },
                { c: "#7d838f", a: 0.75, r: 0.34, x: 0.86, y: 0.30, dx: -0.10, dy: 0.12, t: 35000 },
                { c: "#ffffff", a: 0.95, r: 0.30, x: 0.70, y: 0.86, dx: -0.12, dy: -0.06, t: 23000 },
                { c: "#4b5059", a: 0.6, r: 0.22, x: 0.62, y: 0.18, dx: 0.08, dy: 0.10, t: 29000 },
                { c: "#b9bec8", a: 0.70, r: 0.28, x: 0.05, y: 0.92, dx: 0.10, dy: -0.08, t: 41000 }
            ]
            Shape {
                id: blob
                required property var modelData
                required property int index
                readonly property real size: Math.max(paper.width, paper.height) * modelData.r * 2
                property real phase: index / 6
                width: size; height: size
                x: paper.width * (modelData.x + modelData.dx * Math.sin(phase * Math.PI * 2)) - size / 2
                y: paper.height * (modelData.y + modelData.dy * Math.cos(phase * Math.PI * 2)) - size / 2
                preferredRendererType: Shape.CurveRenderer
                NumberAnimation on phase {
                    from: blob.index / 6; to: blob.index / 6 + 1; duration: blob.modelData.t
                    loops: Animation.Infinite
                    running: paper.running && Theme.isGlass
                }
                ShapePath {
                    strokeColor: "transparent"
                    fillGradient: RadialGradient {
                        centerX: blob.size / 2; centerY: blob.size / 2
                        focalX: centerX; focalY: centerY
                        centerRadius: blob.size / 2
                        GradientStop { position: 0; color: Qt.alpha(blob.modelData.c, blob.modelData.a) }
                        GradientStop { position: 0.5; color: Qt.alpha(blob.modelData.c, blob.modelData.a * 0.55) }
                        GradientStop { position: 1; color: Qt.alpha(blob.modelData.c, 0) }
                    }
                    PathRectangle { width: blob.size; height: blob.size; radius: blob.size / 2 }
                }
            }
        }
        // Thin silver arcs: refraction bends them visibly at every glass edge.
        Repeater {
            model: [
                { r: 0.55, x: 0.10, y: 1.05, w: 2.0, a: 0.75, s: 1 },
                { r: 0.72, x: 0.10, y: 1.05, w: 1.4, a: 0.55, s: 1 },
                { r: 0.40, x: 1.00, y: -0.05, w: 1.6, a: 0.6, s: -1 },
                { r: 0.62, x: 1.00, y: -0.05, w: 1.0, a: 0.45, s: -1 }
            ]
            Shape {
                id: arc
                required property var modelData
                readonly property real rad: Math.max(paper.width, paper.height) * modelData.r
                property real turn: 0
                x: paper.width * modelData.x - rad
                y: paper.height * modelData.y - rad
                width: rad * 2; height: rad * 2
                rotation: turn * arc.modelData.s
                preferredRendererType: Shape.CurveRenderer
                NumberAnimation on turn {
                    from: 0; to: 360; duration: 180000
                    loops: Animation.Infinite
                    running: paper.running && Theme.isGlass
                }
                ShapePath {
                    strokeWidth: arc.modelData.w
                    strokeColor: Qt.rgba(1, 1, 1, arc.modelData.a)
                    fillColor: "transparent"
                    PathAngleArc { centerX: arc.rad; centerY: arc.rad; radiusX: arc.rad - 2; radiusY: arc.rad - 2; startAngle: 0; sweepAngle: 300 }
                }
            }
        }
    }
}
