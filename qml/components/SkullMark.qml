import QtQuick
import QtQuick.Window
import FakeClicker

// Fake Clicker mark: a skull over two crossed bones. The jaw is a separate layer: `jaw` opens the
// mouth (0 closed, 1 open) and chomp() snaps it shut twice, like a bite. Jaw and cranium carry
// their own black backing, so the open mouth stays black instead of showing the bones.
Item {
    id: mark
    property real size: 28
    property real jaw: 0
    signal chompFinished()
    width: size
    height: size

    readonly property real pixelRatio: Math.max(1, Screen.devicePixelRatio)
    readonly property size raster: Qt.size(Math.ceil(size * pixelRatio), Math.ceil(size * pixelRatio))
    readonly property string base: "qrc:/qt/qml/FakeClicker/assets/logo/"

    function chomp() { bite.restart(); }

    // All parts share one 128×128 artboard, so they stack without offsets.
    Image {
        anchors.fill: parent
        source: mark.base + "bones.svg"
        sourceSize: mark.raster
        smooth: true
    }
    Image {
        width: mark.size; height: mark.size
        y: mark.jaw * mark.size * 0.075
        source: mark.base + "jaw.svg"
        sourceSize: mark.raster
        smooth: true
    }
    Image {
        width: mark.size; height: mark.size
        y: -mark.jaw * mark.size * 0.012
        source: mark.base + "cranium.svg"
        sourceSize: mark.raster
        smooth: true
    }

    SequentialAnimation {
        id: bite
        NumberAnimation { target: mark; property: "jaw"; to: 1; duration: 130 * motionScale; easing.type: Easing.OutQuad }
        NumberAnimation { target: mark; property: "jaw"; to: 0; duration: 85 * motionScale; easing.type: Easing.InQuad }
        PauseAnimation { duration: 70 * motionScale }
        NumberAnimation { target: mark; property: "jaw"; to: 1; duration: 130 * motionScale; easing.type: Easing.OutQuad }
        NumberAnimation { target: mark; property: "jaw"; to: 0; duration: 85 * motionScale; easing.type: Easing.InQuad }
        ScriptAction { script: mark.chompFinished() }
    }
}
