import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T
import CClicker

// Glass: a floating glass sheet that springs in over a blurred window.
// Solid: an iOS 14 card that slides up over a dimmed window.
T.Popup {
    id: sheet
    parent: Overlay.overlay
    x: Math.round(((parent ? parent.width : 0) - width) / 2)
    y: Math.round(((parent ? parent.height : 0) - height) / 2 + drop)
    property real drop: 0
    modal: true
    focus: true
    padding: 24
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset, contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset, contentHeight + topPadding + bottomPadding)
    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside
    property bool counted: false
    onAboutToShow: if (!counted) { counted = true; Theme.modals += 1; }
    onAboutToHide: if (counted) { counted = false; Theme.modals -= 1; }
    T.Overlay.modal: Rectangle {
        color: Theme.isGlass ? Qt.rgba(0.96, 0.96, 0.98, 0.18) : Qt.rgba(0, 0, 0, 0.32)
        Behavior on opacity { NumberAnimation { duration: 220 } }
    }
    property Transition glassIn: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.86; to: 1; duration: 520; easing.type: Easing.OutBack; easing.overshoot: 1.7 }
            NumberAnimation { property: "drop"; from: 0; to: 0; duration: 1 }
        }
    }
    property Transition glassOut: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; to: 0; duration: 150; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; to: 0.92; duration: 170; easing.type: Easing.InCubic }
        }
    }
    property Transition solidIn: Transition {
        ParallelAnimation {
            NumberAnimation { property: "drop"; from: 90; to: 0; duration: 360; easing.type: Easing.OutCubic }
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
            NumberAnimation { property: "scale"; from: 1; to: 1; duration: 1 }
        }
    }
    property Transition solidOut: Transition {
        ParallelAnimation {
            NumberAnimation { property: "drop"; to: 70; duration: 240; easing.type: Easing.InCubic }
            NumberAnimation { property: "opacity"; to: 0; duration: 220 }
        }
    }
    enter: Theme.isGlass ? glassIn : solidIn
    exit: Theme.isGlass ? glassOut : solidOut
    background: Surface {
        radius: Theme.isGlass ? 36 : 14
        floating: true
        elevation: 2.4
        tintAlpha: 0.66
        solidShadow: true
    }
}
