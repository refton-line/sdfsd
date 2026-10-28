import QtQuick
import CClicker

// Section container. Glass: a floating glass panel with an inline title. Solid: an iOS 14
// inset grouped section with an uppercase header above a white rounded group.
Item {
    id: card
    property string title
    property string icon
    property real tintAlpha: 0.36
    default property alias content: body.data
    readonly property real headerHeight: title === "" ? 0 : Theme.isGlass ? 50 : 30
    readonly property real pad: Theme.cardPadding

    Label {
        visible: !Theme.isGlass && card.title !== ""
        x: 16; y: 6
        text: card.title.toLocaleUpperCase()
        color: Theme.muted
        font.pixelSize: 12; font.weight: Font.Medium
        font.letterSpacing: 0.3
    }
    Surface {
        y: Theme.isGlass ? 0 : card.headerHeight
        width: parent.width
        height: parent.height - y
        tintAlpha: card.tintAlpha
    }
    Row {
        visible: Theme.isGlass && card.title !== ""
        x: 22; y: 18
        spacing: 9
        Icon { visible: card.icon !== ""; name: card.icon; size: 17; color: Theme.inkSoft; anchors.verticalCenter: parent.verticalCenter }
        Label { text: card.title; font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.inkSoft; anchors.verticalCenter: parent.verticalCenter }
    }
    Item {
        id: body
        y: card.headerHeight
        width: parent.width
        height: parent.height - y
    }
}
