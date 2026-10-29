import QtQuick
import QtQuick.Window
import FakeClicker

// One passive, per-pixel-alpha window. Never rebuild its native region while morphing.
Window {
    id: overlay
    objectName: "islandOverlay"
    property var engine
    property bool wanted: false
    property alias island: island
    width: 520
    height: 220
    color: "transparent"
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
           | Qt.WindowDoesNotAcceptFocus | Qt.WindowTransparentForInput | Qt.NoDropShadowWindowHint
    visible: false
    title: "Fake Clicker island"

    function place() {
        const target = engine && engine.targetWindow !== "" ? windowPicker.windowRect(engine.targetWindow) : Qt.rect(0, 0, 0, 0);
        if (target.width > 0) {
            x = Math.round(target.x + (target.width - width) / 2);
            y = Math.round(target.y + 10 - island.y);
            return;
        }
        const s = overlay.screen;
        if (!s) return;
        x = Math.round(s.virtualX + (s.width - width) / 2);
        y = Math.round(s.virtualY + 10 - island.y);
    }
    Timer {
        interval: 100; repeat: true
        running: overlay.visible && overlay.wanted && overlay.engine && overlay.engine.targetWindow !== ""
        onTriggered: overlay.place()
    }
    onWantedChanged: {
        if (wanted) place();
        // Handoff is atomic: no second fading copy above the main-window island.
        visible = wanted;
        if (visible) windowEffects.makePassive(overlay);
    }
    onVisibleChanged: if (visible) windowEffects.makePassive(overlay)
    DynamicIsland {
        id: island
        objectName: "overlayIsland"
        overlay: true
        engine: overlay.engine
        hidden: !overlay.wanted
        presentsEvents: overlay.wanted
        x: island.snap((parent.width - width) / 2)
        // Reserve alpha padding for smooth edges; never clip the capsule at the native top edge.
        y: island.snap(16)
    }
}
