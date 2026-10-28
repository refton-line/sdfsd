import QtQuick
import QtQuick.Templates as T
import CClicker

// Floating glass navigation. The selected item is a glass lens that springs and stretches
// between rows, carrying the item's tint.
Glass {
    id: bar
    property int currentIndex: 0
    property var items: []          // [{ text, icon }]
    property real reveal: 1         // launch sequence 0..1
    signal activated(int index)
    radius: Theme.radiusXL
    readonly property int rowHeight: 46
    readonly property int inset: 14

    property real lensY: inset + currentIndex * (rowHeight + 4)
    Behavior on lensY { SpringAnimation { spring: Theme.springStiff; damping: Theme.springDamp; epsilon: 0.05 } }
    readonly property real target: inset + currentIndex * (rowHeight + 4)
    readonly property real travel: Math.min(rowHeight * 0.7, Math.abs(target - lensY) * 0.5)

    Glass {
        x: 10 + bar.travel * 0.04
        y: bar.lensY - bar.travel / 2
        width: parent.width - 20 - bar.travel * 0.08
        height: bar.rowHeight + bar.travel
        radius: 16
        elevation: 0.7
        fillOpacity: 1
        opacity: bar.reveal
    }
    Column {
        x: 10; y: bar.inset
        width: parent.width - 20
        spacing: 4
        Repeater {
            id: rows
            model: bar.items
            T.AbstractButton {
                id: row
                required property int index
                required property var modelData
                width: parent.width
                height: bar.rowHeight
                hoverEnabled: true
                focusPolicy: Qt.StrongFocus
                objectName: "nav" + index
                Accessible.role: Accessible.PageTab
                Accessible.name: modelData.text
                readonly property bool selected: bar.currentIndex === index
                onClicked: bar.activated(index)
                Keys.onUpPressed: if (index > 0) { bar.activated(index - 1); rows.itemAt(index - 1).forceActiveFocus(); }
                Keys.onDownPressed: if (index < bar.items.length - 1) { bar.activated(index + 1); rows.itemAt(index + 1).forceActiveFocus(); }
                // Staggered entrance.
                readonly property real local: Math.max(0, Math.min(1, bar.reveal * (bar.items.length + 2) - index))
                opacity: local
                transform: Translate { x: -14 * (1 - row.local) }
                background: Rectangle {
                    radius: 16
                    color: !row.selected && row.hovered ? Theme.well : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                    border.width: row.visualFocus ? 2 : 0
                    border.color: Theme.focusRing
                }
                contentItem: Item {
                    scale: row.pressed ? 0.96 : 1
                    Behavior on scale { SpringAnimation { spring: 5; damping: 0.32; epsilon: 0.001 } }
                    Rectangle {
                        id: badge
                        x: 8; anchors.verticalCenter: parent.verticalCenter
                        width: 30; height: 30; radius: 9
                        color: row.selected ? Theme.ink : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.base } }
                        Icon {
                            anchors.centerIn: parent
                            name: row.modelData.icon
                            size: 18
                            color: row.selected ? "#ffffff" : Theme.inkSoft
                        }
                    }
                    Label {
                        anchors.left: badge.right; anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.text
                        font.pixelSize: Theme.body
                        font.weight: row.selected ? Font.DemiBold : Font.Medium
                        color: row.selected ? Theme.ink : Theme.inkSoft
                    }
                }
            }
        }
    }
}
