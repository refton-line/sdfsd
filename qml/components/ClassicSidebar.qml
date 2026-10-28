import QtQuick
import QtQuick.Templates as T
import LightClicker

// iPadOS 14-style sidebar: blue line icons, a filled blue selection.
Rectangle {
    id: bar
    property int currentIndex: 0
    property var items: []
    property real reveal: 1
    signal activated(int index)
    color: "#ffffff"
    Rectangle { anchors.right: parent.right; width: 0.5; height: parent.height; color: "#c6c6c8" }

    // The logo sits above the list: Main.qml's launch mark lands here.
    Item {
        id: list
        x: 10; y: 112
        width: parent.width - 20
        height: bar.items.length * 46
        Rectangle {
            id: selection
            width: parent.width; height: 42
            radius: 10
            color: "#007aff"
            y: bar.currentIndex * 46
            Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        }
        Repeater {
            id: rows
            model: bar.items
            T.AbstractButton {
                id: row
                required property int index
                required property var modelData
                objectName: "nav" + index
                y: index * 46
                width: list.width; height: 42
                hoverEnabled: true
                focusPolicy: Qt.StrongFocus
                Accessible.role: Accessible.PageTab
                Accessible.name: modelData.text
                readonly property bool selected: bar.currentIndex === index
                onClicked: bar.activated(index)
                Keys.onUpPressed: if (index > 0) { bar.activated(index - 1); rows.itemAt(index - 1).forceActiveFocus(); }
                Keys.onDownPressed: if (index < bar.items.length - 1) { bar.activated(index + 1); rows.itemAt(index + 1).forceActiveFocus(); }
                readonly property real local: Math.max(0, Math.min(1, bar.reveal * (bar.items.length + 2) - index))
                opacity: local
                background: Rectangle {
                    radius: 10
                    color: !row.selected && (row.pressed || row.hovered) ? Theme.fill : "transparent"
                    border.width: row.visualFocus ? 2 : 0
                    border.color: Theme.focusRing
                }
                contentItem: Item {
                    Icon {
                        id: rowIcon
                        x: 12; anchors.verticalCenter: parent.verticalCenter
                        name: row.modelData.icon
                        size: 21
                        color: row.selected ? "#ffffff" : "#007aff"
                    }
                    Label {
                        anchors.left: rowIcon.right; anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.text
                        font.pixelSize: 15
                        font.weight: row.selected ? Font.DemiBold : Font.Normal
                        color: row.selected ? "#ffffff" : Theme.ink
                    }
                }
            }
        }
    }
}
