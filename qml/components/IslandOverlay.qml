import QtQuick
import QtQuick.Window
import LightClicker

// The island above other windows while clicking in a game or app. The window is clipped to
// the capsule every frame of its animation and never takes focus or mouse input.
Window {
    id: overlay
    objectName: "islandOverlay"
    property var engine
    property bool wanted: false
    property alias island: island
    width: 520
    height: 220
    color: "transparent"
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus | Qt.NoDropShadowWindowHint
    visible: false
    title: "Light clicker island"

    // Top centre of the chosen window when there is one, otherwise of the screen.
    function place() {
        const target = engine && engine.targetWindow !== "" ? windowPicker.windowRect(engine.targetWindow) : Qt.rect(0, 0, 0, 0);
        if (target.width > 0) {
            x = Math.round(target.x + (target.width - width) / 2);
            y = target.y + 10;
            return;
        }
        const s = overlay.screen;
        if (!s) return;
        x = s.virtualX + (s.width - width) / 2;
        y = s.virtualY + 10;
    }
    Timer {
        // Follow the chosen window while it moves.
        interval: 250; repeat: true
        running: overlay.visible && overlay.wanted && overlay.engine && overlay.engine.targetWindow !== ""
        onTriggered: overlay.place()
    }
    function updateMask() {
        windowEffects.setRoundedMask(overlay, island.x, island.y, island.width, island.height, Math.min(island.height / 2, 34));
    }
    onWantedChanged: {
        if (wanted) {
            place();
            visible = true;
            windowEffects.makePassive(overlay);
        }
        island.hidden = !wanted;
    }
    Timer {
        // Hide the native window only after the capsule has collapsed.
        interval: 420
        running: !overlay.wanted && overlay.visible
        onTriggered: if (!overlay.wanted) overlay.visible = false
    }
    DynamicIsland {
        id: island
        overlay: true
        engine: overlay.engine
        hidden: true
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        onWidthChanged: overlay.updateMask()
        onHeightChanged: overlay.updateMask()
        onXChanged: overlay.updateMask()
    }
}
