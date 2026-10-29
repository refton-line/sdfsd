import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T
import FakeClicker

// Graphite sheet over a darkened window. Fades in with a short rise; fades out faster.
T.Popup {
    id: sheet
    parent: Overlay.overlay
    x: Math.round(((parent ? parent.width : 0) - width) / 2)
    y: Math.round(((parent ? parent.height : 0) - height) / 2 + rise)
    property real rise: 0
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
        color: Qt.rgba(0, 0, 0, 0.72)
        Behavior on opacity { NumberAnimation { duration: Theme.base } }
    }
    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.base; easing.type: Easing.OutCubic }
            NumberAnimation { property: "rise"; from: 10; to: 0; duration: Theme.slow; easing.type: Easing.OutCubic }
        }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: Theme.fast; easing.type: Easing.InCubic }
    }
    background: Rectangle {
        radius: 18
        color: Theme.panel
        border.width: 1
        border.color: Theme.hairlineStrong
    }
}
