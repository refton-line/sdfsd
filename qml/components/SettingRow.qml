import QtQuick
import FakeClicker

// One row inside a Panel: glyph, title and a trailing control, divided by an inset hairline.
Item {
    id: row
    property string icon
    property string title
    property bool last: false
    default property alias trailing: slot.data
    width: parent ? parent.width : 0
    height: Theme.rowHeight

    Icon {
        visible: row.icon !== ""
        x: Theme.pad; anchors.verticalCenter: parent.verticalCenter
        name: row.icon; size: 18
        color: Theme.muted
    }
    Label {
        x: row.icon === "" ? Theme.pad : Theme.pad + 30
        anchors.verticalCenter: parent.verticalCenter
        text: row.title
        color: Theme.inkSoft
        font.pixelSize: Theme.body; font.weight: Font.Medium
    }
    Item {
        id: slot
        anchors.right: parent.right
        anchors.rightMargin: Theme.pad - 4
        width: childrenRect.width
        height: parent.height
    }
    Rectangle {
        visible: !row.last
        x: Theme.pad
        anchors.bottom: parent.bottom
        width: parent.width - 2 * Theme.pad
        height: 1
        color: Theme.hairline
    }
}
