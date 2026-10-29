import QtQuick
import FakeClicker

// Flat graphite panel with a hairline edge and an optional caption in its top-left corner.
Rectangle {
    id: panel
    property string title
    default property alias content: body.data
    readonly property real headerHeight: title === "" ? 0 : 46
    readonly property real pad: Theme.pad
    color: Theme.panel
    radius: Theme.radius
    border.width: 1
    border.color: Theme.hairline

    Caption {
        visible: panel.title !== ""
        x: panel.pad; y: 20
        text: panel.title
    }
    // Optional trailing header content (status, counters), aligned with the caption.
    property alias actions: headerRight.data
    Item {
        id: headerRight
        anchors.right: parent.right; anchors.rightMargin: panel.pad
        y: 14
        width: childrenRect.width
        height: 20
    }
    Item {
        id: body
        y: panel.headerHeight
        width: parent.width
        height: parent.height - y
    }
}
