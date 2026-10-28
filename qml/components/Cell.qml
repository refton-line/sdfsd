import QtQuick
import CClicker

// One row inside a Card. Glass: monochrome glyph. Solid: iOS Settings-style grey tile and an
// inset separator.
Item {
    id: cell
    property string icon
    property string title
    property bool last: false
    property color tileColor: "#8e8e93"
    default property alias trailing: slot.data
    width: parent ? parent.width : 0
    height: Theme.rowHeight

    Rectangle {
        id: tile
        visible: !Theme.isGlass && cell.icon !== ""
        x: 16; anchors.verticalCenter: parent.verticalCenter
        width: 29; height: 29; radius: 7
        color: cell.tileColor
        Icon { anchors.centerIn: parent; name: cell.icon; size: 18; stroke: 2; color: "#ffffff" }
    }
    Icon {
        id: glyph
        visible: Theme.isGlass && cell.icon !== ""
        x: 22; anchors.verticalCenter: parent.verticalCenter
        name: cell.icon; size: 20
        color: Theme.inkSoft
    }
    Label {
        id: titleText
        x: cell.icon === "" ? (Theme.isGlass ? 22 : 16) : Theme.isGlass ? 56 : 58
        anchors.verticalCenter: parent.verticalCenter
        text: cell.title
        font.pixelSize: Theme.isGlass ? 14 : 15
        font.weight: Theme.isGlass ? Font.Medium : Font.Normal
    }
    Item {
        id: slot
        anchors.right: parent.right
        anchors.rightMargin: Theme.isGlass ? 16 : 14
        width: childrenRect.width
        height: parent.height
    }
    Rectangle {
        visible: !cell.last
        x: titleText.x
        anchors.bottom: parent.bottom
        width: parent.width - x
        height: 1
        color: Theme.separator
    }
}
