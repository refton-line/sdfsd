import QtQuick
import QtQuick.Window
import QtQuick.Effects

// Renders the app icon from shaders/mark.frag so the icon matches the in-app mark exactly.
// Usage: qml RenderIcon.qml -- <mark.frag.qsb> <output dir>
Window {
    id: w
    width: 1100; height: 1100
    visible: true
    color: "transparent"
    readonly property var args: Qt.application.arguments
    readonly property string shader: args[args.length - 2]
    readonly property string out: args[args.length - 1]
    readonly property var sizes: [1024, 256, 128, 64, 48, 32, 24, 16]

    // What the glass half of the tile refracts: grey-white with graphite and white light.
    Item {
        id: scene
        width: 1024; height: 1024
        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: "#f2f3f6" } GradientStop { position: 1; color: "#c9cdd5" } } }
        Rectangle { x: -260; y: 560; width: 700; height: 700; radius: 350; color: "#3a3d44"; opacity: 0.75 }
        Rectangle { x: -120; y: -220; width: 620; height: 620; radius: 310; color: "#ffffff" }
        Rectangle { x: 260; y: 330; width: 360; height: 360; radius: 180; color: "#9aa0ab"; opacity: 0.7 }
        Repeater { model: 3; Rectangle { x: 80 + index * 150; y: -100; width: 6; height: 1300; color: "#ffffff"; opacity: 0.6; rotation: 24 } }
    }
    ShaderEffectSource { id: sharpTex; sourceItem: scene; hideSource: true; visible: false }
    MultiEffect { id: blur; width: 1024; height: 1024; source: sharpTex; blurEnabled: true; blur: 1; blurMax: 64; autoPaddingEnabled: false; visible: false }
    ShaderEffectSource { id: frostTex; sourceItem: blur; visible: false; hideSource: true }

    Repeater {
        id: icons
        model: w.sizes
        ShaderEffect {
            required property int modelData
            width: modelData; height: modelData
            visible: false
            property size itemSize: Qt.size(width, height)
            property rect area: Qt.rect(0, 0, 1024, 1024)
            property size backdropSize: Qt.size(1024, 1024)
            property real split: 0.5
            property real progress: modelData <= 32 ? 0 : 1
            property real time: 1.05
            property real tile: 1
            property real hasBackdrop: 1
            property vector4d ink: Qt.vector4d(0.114, 0.114, 0.122, 1)
            property var sharp: sharpTex
            property var frosted: frostTex
            fragmentShader: "file://" + w.shader
        }
    }
    property int done: 0
    Timer {
        interval: 600; running: true
        onTriggered: {
            for (let i = 0; i < icons.count; ++i) {
                const item = icons.itemAt(i);
                item.visible = true;
                const size = item.modelData;
                item.grabToImage(r => {
                    r.saveToFile(w.out + "/icon-" + size + ".png");
                    if (++w.done === icons.count) Qt.quit();
                }, Qt.size(size, size));
            }
        }
    }
}
