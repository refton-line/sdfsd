import QtQuick
import LightClicker

// Real Liquid Glass: refracts and frosts what lies behind (shaders/glass.frag). `floating`
// surfaces sample the whole stage (content included), others only the wallpaper. `detached`
// glass (the overlay window) has no backdrop and is drawn from its tint and lighting alone.
// `inset` glass is a recessed well: the bezel is lit from below and shadowed on top.
ShaderEffect {
    id: glass
    property real radius: 24
    property bool floating: false
    property real bezel: Math.min(22, Math.min(width, height) * 0.32)
    property real refraction: Math.min(16, Math.min(width, height) * 0.22)
    property real frost: 1
    property real rim: 0.85
    property real dispersion: 1.2
    property color tintColor: Qt.rgba(1, 1, 1, 0.4)
    property real magnify: 0
    property real shade: 0.10
    property bool detached: false
    property bool inset: false

    readonly property vector4d tint: Qt.vector4d(tintColor.r, tintColor.g, tintColor.b, tintColor.a)
    readonly property vector2d light: Qt.vector2d(-0.55, -0.83)
    readonly property size itemSize: Qt.size(Math.max(1, width), Math.max(1, height))
    property rect area: Qt.rect(0, 0, width, height)
    readonly property size backdropSize: Theme.backdropRoot ? Qt.size(Math.max(1, Theme.backdropRoot.width), Math.max(1, Theme.backdropRoot.height)) : Qt.size(1, 1)
    readonly property var sharpSource: floating ? Theme.stageTexture : Theme.wallTexture
    readonly property real hasBackdrop: !detached && sharpSource ? 1 : 0
    property var sharp: hasBackdrop > 0 ? sharpSource : placeholder
    property var frosted: hasBackdrop > 0 ? (floating ? Theme.stageFrostTexture : Theme.wallFrostTexture) : placeholder
    fragmentShader: "qrc:/shaders/glass.frag.qsb"

    // Bound when there is no backdrop so the samplers always have a texture provider.
    Item { id: placeholder; width: 2; height: 2; visible: false; layer.enabled: true }

    function track() {
        if (Theme.backdropRoot && !detached)
            area = mapToItem(Theme.backdropRoot, Qt.rect(0, 0, width, height));
    }
    Component.onCompleted: track()
    onWidthChanged: track()
    onHeightChanged: track()
    // Ancestors move during transitions; follow them every frame while anything animates.
    FrameAnimation { running: glass.visible && Theme.animating && Theme.backdropRoot !== null; onTriggered: glass.track() }
}
