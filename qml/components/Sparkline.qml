import QtQuick
import QtQuick.Shapes
import LightClicker

// Recent measured rate. Samples arrive every 100 ms while running; the line keeps its last shape.
Item {
    id: spark
    property var samples: []
    property real ceiling: 1
    property color tint: Theme.ink
    readonly property int capacity: 80
    function push(v) {
        const next = samples.slice(Math.max(0, samples.length - capacity + 1));
        next.push(Math.max(0, v));
        samples = next;
    }
    function reset() { samples = []; }
    readonly property real peak: Math.max(ceiling, Math.max.apply(null, samples.concat([0.0001]))) * 1.18
    readonly property var points: {
        const out = [];
        const n = samples.length;
        for (let i = 0; i < n; ++i)
            out.push([width * (i + capacity - n) / (capacity - 1), height - 2 - (height - 4) * samples[i] / peak]);
        return out;
    }
    readonly property string line: points.length > 1 ? "M " + points.map(p => p[0].toFixed(1) + " " + p[1].toFixed(1)).join(" L ") : ""
    readonly property string area: points.length > 1 ? line + " L " + points[points.length - 1][0].toFixed(1) + " " + height + " L " + points[0][0].toFixed(1) + " " + height + " Z" : ""
    Shape {
        anchors.fill: parent
        visible: spark.points.length > 1
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: 0; x2: 0; y2: spark.height
                GradientStop { position: 0; color: Qt.rgba(spark.tint.r, spark.tint.g, spark.tint.b, 0.22) }
                GradientStop { position: 1; color: Qt.rgba(spark.tint.r, spark.tint.g, spark.tint.b, 0) }
            }
            PathSvg { path: spark.area }
        }
        ShapePath {
            strokeColor: spark.tint
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: spark.line }
        }
    }
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width; height: 1
        color: Theme.hairline
        opacity: 0.6
    }
}
