import QtQuick
import QtQuick.Shapes
import CClicker

// Soft grey-white field with slowly drifting light. It is what the glass refracts; in the
// solid material it settles to the flat iOS grouped background.
Item {
    id: paper
    property bool running: true
    clip: true

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.tint(Theme.backdrop, Qt.rgba(0.93, 0.94, 0.96, 0.9 * Theme.glass)) }
            GradientStop { position: 1; color: Qt.tint(Theme.backdrop, Qt.rgba(0.87, 0.88, 0.91, 0.9 * Theme.glass)) }
        }
    }
    Repeater {
        model: [
            { c: Qt.rgba(1, 1, 1, 0.95), r: 0.55, x: 0.18, y: 0.10, dx: 0.10, dy: 0.08, t: 23000 },
            { c: Qt.rgba(0.72, 0.77, 0.86, 0.55), r: 0.50, x: 0.82, y: 0.22, dx: -0.12, dy: 0.10, t: 29000 },
            { c: Qt.rgba(0.80, 0.78, 0.76, 0.42), r: 0.45, x: 0.30, y: 0.92, dx: 0.14, dy: -0.06, t: 31000 },
            { c: Qt.rgba(0.62, 0.67, 0.76, 0.38), r: 0.40, x: 0.92, y: 0.88, dx: -0.10, dy: -0.12, t: 37000 },
            { c: Qt.rgba(1, 1, 1, 0.8), r: 0.32, x: 0.55, y: 0.50, dx: 0.08, dy: 0.10, t: 19000 }
        ]
        Shape {
            id: blob
            required property var modelData
            readonly property real size: Math.max(paper.width, paper.height) * modelData.r * 2
            property real phase: 0
            width: size; height: size
            x: paper.width * (modelData.x + modelData.dx * Math.sin(phase * Math.PI * 2)) - size / 2
            y: paper.height * (modelData.y + modelData.dy * Math.cos(phase * Math.PI * 2)) - size / 2
            opacity: Theme.glass
            visible: opacity > 0.01
            preferredRendererType: Shape.CurveRenderer
            NumberAnimation on phase {
                from: 0; to: 1; duration: blob.modelData.t
                loops: Animation.Infinite
                running: paper.running && Theme.glass > 0
            }
            ShapePath {
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: blob.size / 2; centerY: blob.size / 2
                    focalX: centerX; focalY: centerY
                    centerRadius: blob.size / 2
                    GradientStop { position: 0; color: blob.modelData.c }
                    GradientStop { position: 0.55; color: Qt.rgba(blob.modelData.c.r, blob.modelData.c.g, blob.modelData.c.b, blob.modelData.c.a * 0.35) }
                    GradientStop { position: 1; color: Qt.rgba(blob.modelData.c.r, blob.modelData.c.g, blob.modelData.c.b, 0) }
                }
                PathRectangle { width: blob.size; height: blob.size; radius: blob.size / 2 }
            }
        }
    }
}
