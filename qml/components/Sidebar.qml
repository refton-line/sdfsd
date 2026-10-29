import QtQuick
import QtQuick.Templates as T
import FakeClicker

// Left navigation under the title bar.
Item {
    id: bar
    property var items: []              // [{ text, icon }]
    property int currentIndex: 0
    signal activated(int index)
    width: Theme.sidebarWidth

    Column {
        x: 12; y: 6
        width: parent.width - 24
        spacing: 2
        Repeater {
            model: bar.items
            T.AbstractButton {
                id: item
                required property var modelData
                required property int index
                objectName: "nav" + index
                width: parent.width; height: 40
                hoverEnabled: true
                focusPolicy: Qt.StrongFocus
                readonly property bool selected: bar.currentIndex === index
                Accessible.role: Accessible.PageTab
                Accessible.name: modelData.text
                onClicked: if (!selected) { sounds.play("tap"); bar.activated(index); }
                background: Rectangle {
                    radius: Theme.controlRadius
                    color: item.selected ? Theme.control : item.hovered ? Theme.panel : "transparent"
                    border.width: item.selected ? 1 : 0
                    border.color: Theme.hairlineStrong
                    Rectangle {
                        anchors.fill: parent; anchors.margins: -2
                        radius: Theme.controlRadius + 2
                        color: "transparent"
                        visible: item.visualFocus
                        border.width: 2; border.color: Theme.focusRing
                    }
                }
                contentItem: Item {
                    Icon {
                        x: 12; anchors.verticalCenter: parent.verticalCenter
                        name: item.modelData.icon; size: 18
                        color: item.selected ? Theme.ink : item.hovered ? Theme.inkSoft : Theme.muted
                    }
                    Label {
                        x: 42; anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - x - 8
                        elide: Text.ElideRight
                        text: item.modelData.text
                        font.pixelSize: Theme.body
                        font.weight: item.selected ? Font.DemiBold : Font.Medium
                        color: item.selected ? Theme.ink : item.hovered ? Theme.inkSoft : Theme.muted
                    }
                }
            }
        }
    }

}
