import QtQuick
import QtQuick.Templates as T
import FakeClicker

// Graphite track with a lighter thumb that eases between segments.
Item {
    id: seg
    property var options: []           // [{ text, icon, tint }]
    property int currentIndex: 0
    property real iconSize: 15
    signal activated(int index)
    implicitHeight: 36
    implicitWidth: 300
    opacity: enabled ? 1 : 0.4
    readonly property real cell: options.length ? width / options.length : width

    Rectangle {
        anchors.fill: parent
        radius: Theme.controlRadius
        color: Theme.raised
        border.width: 1
        border.color: Theme.hairline
    }
    Rectangle {
        visible: seg.currentIndex >= 0 && seg.options.length > 0
        x: seg.cell * Math.max(0, seg.currentIndex) + 3
        Behavior on x { NumberAnimation { duration: Theme.base; easing.type: Easing.OutCubic } }
        y: 3
        width: seg.cell - 6; height: seg.height - 6
        radius: Theme.controlRadius - 3
        color: Theme.controlActive
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.06)
    }
    Row {
        anchors.fill: parent
        Repeater {
            id: buttons
            model: seg.options
            T.AbstractButton {
                id: option
                required property int index
                required property var modelData
                width: seg.cell
                height: seg.height
                hoverEnabled: true
                focusPolicy: Qt.StrongFocus
                Accessible.role: Accessible.RadioButton
                Accessible.name: modelData.text
                Accessible.checked: seg.currentIndex === index
                onClicked: if (seg.currentIndex !== index) seg.activated(index)
                Keys.onLeftPressed: if (index > 0) { seg.activated(index - 1); buttons.itemAt(index - 1).forceActiveFocus(); }
                Keys.onRightPressed: if (index < seg.options.length - 1) { seg.activated(index + 1); buttons.itemAt(index + 1).forceActiveFocus(); }
                readonly property bool selected: seg.currentIndex === index
                contentItem: Item {
                    Row {
                        anchors.centerIn: parent
                        spacing: 7
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !!option.modelData.icon
                            name: option.modelData.icon || ""
                            size: seg.iconSize
                            color: option.selected ? (option.modelData.tint || Theme.ink) : Theme.muted
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: option.modelData.text
                            font.pixelSize: 13
                            font.weight: option.selected ? Font.DemiBold : Font.Medium
                            color: option.selected ? Theme.ink : option.hovered ? Theme.inkSoft : Theme.muted
                        }
                    }
                }
                background: Rectangle {
                    radius: Theme.controlRadius - 3
                    color: "transparent"
                    border.width: option.visualFocus ? 2 : 0
                    border.color: Theme.focusRing
                }
            }
        }
    }
}
