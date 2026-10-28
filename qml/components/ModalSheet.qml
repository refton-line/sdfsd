import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T
import CClicker

// Centered glass sheet. Opening blurs the window behind it (Theme.modals); it springs in
// slightly oversized and settles, and leaves by sinking and fading.
T.Popup {
    id: sheet
    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    focus: true
    padding: 24
    // Templates carry no implicit size; size from content like the stock styles do.
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset, contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset, contentHeight + topPadding + bottomPadding)
    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside
    property bool counted: false
    onAboutToShow: if (!counted) { counted = true; Theme.modals += 1; }
    onAboutToHide: if (counted) { counted = false; Theme.modals -= 1; }
    Overlay.modal: Rectangle {
        color: Qt.rgba(0.11, 0.11, 0.12, 0.08 + 0.14 * (1 - Theme.glass))
        Behavior on opacity { NumberAnimation { duration: Theme.base } }
    }
    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: 460; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; to: 0; duration: 150; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; to: 0.95; duration: 170; easing.type: Easing.InCubic }
        }
    }
    background: Glass {
        radius: Theme.radiusXL
        elevation: 2
        Rectangle { anchors.fill: parent; radius: parent.radius; color: Qt.rgba(1, 1, 1, 0.42 * Theme.glass) }
    }
}
