import QtQuick
import LightClicker

// Brand mark: a five-point star split down the middle into Liquid Glass and plain ink
// (shaders/mark.frag). `progress` fills the ink half from the bottom up (launch).
ShaderEffect {
    id: mark
    property real size: 28
    property real progress: 1
    property bool tile: false
    property real split: 0.5
    property color inkColor: Theme.ink
    width: size
    height: size


    readonly property size itemSize: Qt.size(Math.max(1, width), Math.max(1, height))
    property rect area: Qt.rect(0, 0, width, height)
    readonly property size backdropSize: Theme.backdropRoot ? Qt.size(Math.max(1, Theme.backdropRoot.width), Math.max(1, Theme.backdropRoot.height)) : Qt.size(1, 1)
    readonly property real hasBackdrop: Theme.isGlass && Theme.stageTexture ? 1 : 0
    readonly property vector4d ink: Qt.vector4d(inkColor.r, inkColor.g, inkColor.b, inkColor.a)
    property var sharp: hasBackdrop > 0 ? Theme.stageTexture : placeholder
    property var frosted: hasBackdrop > 0 ? Theme.stageFrostTexture : placeholder
    fragmentShader: "qrc:/shaders/mark.frag.qsb"

    Item { id: placeholder; width: 2; height: 2; visible: false; layer.enabled: true }

    function track() {
        if (Theme.backdropRoot)
            area = mapToItem(Theme.backdropRoot, Qt.rect(0, 0, width, height));
    }
    Component.onCompleted: track()
    onXChanged: track()
    onYChanged: track()
    onWidthChanged: track()
    FrameAnimation { running: mark.visible && Theme.animating && Theme.backdropRoot !== null; onTriggered: mark.track() }
}
