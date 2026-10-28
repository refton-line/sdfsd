import QtQuick
import QtQuick.Window
import CClicker

// The island above other windows while clicking in a game or app. The window is clipped to
// the capsule every frame of its animation and never takes focus or mouse input.
Window {
    id: overlay
    property var engine
    property bool wanted: false
    property alias island: island
    width: 460
    height: 120
    color: "transparent"
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus | Qt.NoDropShadowWindowHint
    visible: false
    title: "C clicker island"

    function place() {
        const s = overlay.screen;
        if (!s) return;
        x = s.virtualX + (s.width - width) / 2;
        y = s.virtualY + 10;
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
