import QtQuick
import QtQuick.Templates as T
import FakeClicker

// Left navigation under the title bar, with the active hotkeys pinned to the bottom.
Item {
    id: bar
    property var items: []              // [{ text, icon }]
    property int currentIndex: 0
    property var engine
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
                onClicked: if (!selected) bar.activated(index)
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

    Column {
        x: 24
        width: parent.width - 48
        anchors.bottom: parent.bottom; anchors.bottomMargin: 22
        spacing: 10
        Caption { text: I18n.t("nav.hotkeys") }
        Repeater {
            model: bar.engine ? [{ key: bar.engine.startLabel, title: I18n.t("keys.start") }, { key: bar.engine.stopLabel, title: I18n.t("keys.stop") }] : []
            Row {
                required property var modelData
                spacing: 10
                width: parent.width
                KeyCap {
                    id: cap
                    text: modelData.key
                    size: 22
                    width: Math.min(implicitWidth, 96)
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - cap.width - 10
                    elide: Text.ElideRight
                    text: modelData.title
                    color: Theme.muted
                    font.pixelSize: Theme.small
                }
            }
        }
        Item { width: 1; height: 6 }
        Label {
            text: "v" + Qt.application.version
            color: Theme.faint
            font.family: Theme.mono
            font.pixelSize: Theme.caption
        }
    }
}
