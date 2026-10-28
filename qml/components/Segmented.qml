import QtQuick
import QtQuick.Templates as T
import CClicker

// Segmented control. The selection is a glass lens that springs between segments and
// stretches while it travels, like a drop of liquid.
Item {
    id: seg
    property var options: []           // [{ text, icon }]
    property int currentIndex: 0
    property real iconSize: 16
    property color accent: Theme.ink
    signal activated(int index)
    implicitHeight: 40
    implicitWidth: 300
    opacity: enabled ? 1 : 0.45
    readonly property real cell: options.length ? width / options.length : width
    readonly property real target: cell * currentIndex

    property real lensX: target
    Behavior on lensX { SpringAnimation { spring: Theme.springStiff; damping: Theme.springDamp; epsilon: 0.05 } }
    readonly property real travel: Math.min(cell * 0.35, Math.abs(target - lensX) * 0.45)

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.well
    }
    Glass {
        x: seg.lensX + 3 - seg.travel / 2
        y: 3 + seg.travel * 0.06
        width: seg.cell - 6 + seg.travel
        height: parent.height - 6 - seg.travel * 0.12
        radius: height / 2
        elevation: 0.5
        fillOpacity: 1
        visible: seg.options.length > 0 && seg.currentIndex >= 0
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
                checkable: false
                Accessible.role: Accessible.RadioButton
                Accessible.name: modelData.text
                Accessible.checked: seg.currentIndex === index
                onClicked: if (seg.currentIndex !== index) seg.activated(index)
                Keys.onLeftPressed: if (index > 0) { seg.activated(index - 1); buttons.itemAt(index - 1).forceActiveFocus(); }
                Keys.onRightPressed: if (index < seg.options.length - 1) { seg.activated(index + 1); buttons.itemAt(index + 1).forceActiveFocus(); }
                readonly property bool selected: seg.currentIndex === index
                contentItem: Item {
                    scale: option.pressed ? 0.94 : 1
                    Behavior on scale { SpringAnimation { spring: 5; damping: 0.32; epsilon: 0.001 } }
                    Row {
                        anchors.centerIn: parent
                        spacing: 7
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !!option.modelData.icon
                            name: option.modelData.icon || ""
                            size: seg.iconSize
                            color: option.selected ? (option.modelData.tint || seg.accent) : Theme.muted
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: option.modelData.text
                            font.pixelSize: Theme.body - 1
                            font.weight: option.selected ? Font.DemiBold : Font.Medium
                            color: option.selected ? Theme.ink : Theme.muted
                            Behavior on color { ColorAnimation { duration: Theme.base } }
                        }
                    }
                }
                background: Rectangle {
                    radius: height / 2
                    color: "transparent"
                    border.width: option.visualFocus ? 2 : 0
                    border.color: Theme.focusRing
                }
            }
        }
    }
}
