import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T
import LightClicker

// Target picker in the style of a screen-share window picker: live thumbnails of open windows,
// plus "Any window" (click whatever is in front when the countdown ends).
ModalSheet {
    id: sheet
    objectName: "windowSheet"
    property var engine
    property real roomWidth: 1000
    property real roomHeight: 700
    property int serial: 0
    readonly property int columns: 3
    readonly property real tileWidth: Math.floor((width - 48 - (columns - 1) * 14) / columns)
    readonly property real tileHeight: Math.round(tileWidth * 9 / 16) + 34
    width: Math.min(roomWidth, 820)
    padding: 24

    function choose() {
        if (engine.active) return;
        windowPicker.refresh();
        serial += 1;
        open();
    }
    Timer { interval: 1500; repeat: true; running: sheet.visible; onTriggered: sheet.serial += 1 }

    contentItem: Item {
        implicitHeight: header.height + 18 + Math.min(scroller.contentHeight, sheet.roomHeight - 200)
        Item {
            id: header
            width: parent.width; height: 36
            Icon { anchors.verticalCenter: parent.verticalCenter; name: "target"; size: 22; color: Theme.ink }
            Label {
                x: 34; anchors.verticalCenter: parent.verticalCenter
                text: I18n.t("target.title")
                font.pixelSize: Theme.title; font.weight: Font.DemiBold
            }
            AppButton {
                objectName: "windowRefresh"
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                compact: true; iconName: "reset"
                Accessible.name: I18n.t("target.refresh")
                onClicked: { windowPicker.refresh(); sheet.serial += 1; }
            }
        }
        Flickable {
            id: scroller
            y: header.height + 18
            width: parent.width
            height: parent.height - y
            clip: true
            contentHeight: grid.height
            boundsBehavior: Flickable.StopAtBounds
            Grid {
                id: grid
                columns: sheet.columns
                spacing: 14
                Repeater {
                    model: [{ id: "", title: I18n.t("target.any"), any: true }].concat(windowPicker.windows)
                    T.AbstractButton {
                        id: tile
                        required property var modelData
                        required property int index
                        objectName: "windowTile" + index
                        width: sheet.tileWidth; height: sheet.tileHeight
                        hoverEnabled: true
                        focusPolicy: Qt.StrongFocus
                        Accessible.name: modelData.title
                        readonly property bool selected: sheet.engine.targetWindow === modelData.id
                        onClicked: { sheet.engine.setTarget(modelData.id, modelData.title); sheet.close(); }
                        scale: Theme.isGlass && pressed ? 0.96 : 1
                        Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
                        contentItem: Item {
                            Item {
                                id: preview
                                width: parent.width; height: parent.height - 34
                                Fill {
                                    anchors.fill: parent
                                    radius: Theme.isGlass ? 16 : 10
                                    inset: true
                                    color: Theme.well
                                }
                                Image {
                                    anchors.fill: parent; anchors.margins: 6
                                    visible: !tile.modelData.any && !tile.modelData.minimized
                                    source: visible ? "image://windows/" + tile.modelData.id + "/" + sheet.serial : ""
                                    sourceSize: Qt.size(480, 270)
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: false
                                    smooth: true; mipmap: true
                                }
                                Icon {
                                    anchors.centerIn: parent
                                    visible: tile.modelData.any || tile.modelData.minimized
                                    name: tile.modelData.any ? "cursor" : "winMin"
                                    size: 30; color: Theme.muted
                                }
                                Rectangle {
                                    anchors.fill: parent; anchors.margins: -3
                                    radius: (Theme.isGlass ? 16 : 10) + 3
                                    color: "transparent"
                                    border.width: tile.selected || tile.visualFocus ? 2.5 : tile.hovered ? 1.5 : 0
                                    border.color: tile.visualFocus ? Theme.focusRing : Theme.isGlass ? Theme.ink : "#007aff"
                                }
                            }
                            Label {
                                y: preview.height + 9
                                width: parent.width
                                text: tile.modelData.title
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: 13
                                font.weight: tile.selected ? Font.DemiBold : Font.Medium
                            }
                        }
                        background: Item {}
                    }
                }
            }
        }
    }
}
