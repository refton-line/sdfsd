import QtQuick
import QtQuick.Window
import FakeClicker

// Exact-DPI CPU SVG rasterisation. No CurveRenderer, SVG arc tessellation or texture atlas.
Item {
    id: icon
    property string name
    property color color: Theme.ink
    property real size: 20
    property real stroke: 1.8
    implicitWidth: size
    implicitHeight: size
    readonly property real pixelRatio: Screen.devicePixelRatio
    Image {
        objectName: icon.name === "stop" ? "stopGlyph" : "crispGlyph"
        anchors.fill: parent
        source: icon.name === "" ? "" : "image://crispicons/" + encodeURIComponent(icon.name)
                + "?color=" + encodeURIComponent(String(icon.color)) + "&stroke=" + icon.stroke
        sourceSize: Qt.size(Math.max(1, Math.round(width * icon.pixelRatio)), Math.max(1, Math.round(height * icon.pixelRatio)))
        asynchronous: false
        cache: true
        smooth: true
        mipmap: false
    }
}
