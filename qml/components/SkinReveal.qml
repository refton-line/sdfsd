import QtQuick
import QtQuick.Window
import CClicker

// Material switch: snapshot the current look, apply the new material underneath, then wash the
// old look away in a circle that grows from the pointer with a bright liquid front
// (shaders/reveal.frag).
ShaderEffect {
    id: reveal
    property var snapshot: shot
    readonly property size itemSize: Qt.size(Math.max(1, width), Math.max(1, height))
    property vector2d center: Qt.vector2d(width / 2, height / 2)
    property real reach: 0
    property real band: 64
    readonly property real farthest: Math.sqrt(width * width + height * height) + band
    readonly property bool running: phase > 0
    property int phase: 0             // 0 idle, 1 capturing, 2 revealing
    property int frames: 0
    property var apply: null
    visible: phase > 0
    fragmentShader: "qrc:/shaders/reveal.frag.qsb"

    ShaderEffectSource { id: shot; live: false; visible: false; sourceItem: null }

    function begin(target, x, y, change) {
        if (phase !== 0) {
            change();
            return;
        }
        apply = change;
        center = Qt.vector2d(x, y);
        reach = farthest;           // fully transparent while the snapshot is taken
        shot.sourceItem = target;
        shot.scheduleUpdate();
        frames = 0;
        phase = 1;
    }
    Connections {
        target: reveal.Window.window
        function onFrameSwapped() {
            if (reveal.phase !== 1 || ++reveal.frames < 2)
                return;
            reveal.reach = 0;
            reveal.phase = 2;
            const change = reveal.apply;
            reveal.apply = null;
            change();
            wave.start();
        }
    }
    NumberAnimation {
        id: wave
        target: reveal; property: "reach"
        from: 0; to: reveal.farthest
        duration: 950; easing.type: Easing.InOutCubic
        onFinished: { reveal.phase = 0; shot.sourceItem = null; }
    }
}
