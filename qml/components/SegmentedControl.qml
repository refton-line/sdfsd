import QtQuick
import QtQuick.Templates as T
import LightClicker

// Glass: a glass lens springs between segments and stretches with its speed.
// Solid: the iOS 13/14 control, a white thumb that eases across a grey track.
Item {
    id: seg
    property var options: []           // [{ text, icon, tint }]
    property int currentIndex: 0
    property real iconSize: 15
    signal activated(int index)
    implicitHeight: Theme.isGlass ? 38 : 32
    implicitWidth: 300
    opacity: enabled ? 1 : 0.45
    readonly property real cell: options.length ? width / options.length : width
    readonly property real target: cell * Math.max(0, currentIndex)

    property real lensX: target
    Behavior on lensX {
        enabled: Theme.isGlass
        SpringAnimation { spring: Theme.springStiff; damping: Theme.springDamp; epsilon: 0.05 }
    }
    property real thumbX: target
    Behavior on thumbX {
        enabled: !Theme.isGlass
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }
    readonly property real travel: Math.min(cell * 0.4, Math.abs(target - lensX) * 0.5)

    Fill {
        anchors.fill: parent
        radius: Theme.isGlass ? height / 2 : 9
        inset: true
        color: Theme.well
    }
    // Solid separators between unselected neighbours
    Repeater {
        model: Theme.isGlass ? 0 : Math.max(0, seg.options.length - 1)
        Rectangle {
            required property int index
            x: seg.cell * (index + 1) - 0.5
            y: 8; width: 1; height: seg.height - 16
            color: Qt.rgba(0.557, 0.557, 0.576, 0.3)
            opacity: index === seg.currentIndex || index + 1 === seg.currentIndex ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
    Surface {
        visible: Theme.isGlass && seg.currentIndex >= 0 && seg.options.length > 0
        x: seg.lensX + 3 - seg.travel / 2
        y: 3 + seg.travel * 0.05
        width: seg.cell - 6 + seg.travel
        height: seg.height - 6 - seg.travel * 0.1
        radius: height / 2
        elevation: 0.5
        tintAlpha: 0.62 - 0.4 * Math.min(1, seg.travel / 30)
        magnify: 0.06 * Math.min(1, seg.travel / 30)
    }
    Rectangle {
        visible: !Theme.isGlass && seg.currentIndex >= 0 && seg.options.length > 0
        x: seg.thumbX + 2; y: 2
        width: seg.cell - 4; height: seg.height - 4
        radius: 7
        color: "#ffffff"
        border.width: 0.5
        border.color: Qt.rgba(0, 0, 0, 0.04)
        Rectangle { anchors.fill: parent; anchors.topMargin: 2; anchors.bottomMargin: -2; radius: 7; color: Qt.rgba(0, 0, 0, 0.06); z: -1 }
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
                    scale: Theme.isGlass && option.pressed ? 0.93 : 1
                    opacity: !Theme.isGlass && option.pressed && !option.selected ? 0.5 : 1
                    Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
                    Row {
                        anchors.centerIn: parent
                        spacing: 6
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
                            font.pixelSize: Theme.isGlass ? 13 : 13
                            font.weight: option.selected ? Font.DemiBold : Font.Medium
                            color: option.selected ? Theme.ink : Theme.isGlass ? Theme.muted : Theme.inkSoft
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
