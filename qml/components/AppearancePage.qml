import QtQuick
import QtQuick.Shapes
import QtQuick.Templates as T
import LightClicker

Item {
    id: page
    property string material: "glass"
    property bool islandOverlay: true
    // x/y: pointer position in window coordinates, the origin of the switch animation.
    signal materialRequested(string value, real x, real y)
    signal islandOverlayRequested(bool value)

    Card {
        id: materialCard
        icon: "drop"
        width: parent.width
        height: headerHeight + 300
        Row {
            x: Theme.isGlass ? 18 : 14; y: Theme.isGlass ? 18 : 14
            spacing: 14
            Repeater {
                model: [
                    { key: "glass", icon: "sparkle", title: "look.glass" },
                    { key: "solid", icon: "square", title: "look.solid" }
                ]
                T.AbstractButton {
                    id: option
                    required property var modelData
                    required property int index
                    objectName: "material_" + modelData.key
                    readonly property bool selected: page.material === modelData.key
                    width: (materialCard.width - (Theme.isGlass ? 36 : 28) - 14) / 2
                    height: 272
                    hoverEnabled: true
                    focusPolicy: Qt.StrongFocus
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: I18n.t(modelData.title)
                    Accessible.checked: selected
                    onClicked: {
                        const p = option.mapToItem(null, option.width / 2, 90);
                        page.materialRequested(modelData.key, p.x, p.y);
                    }
                    scale: Theme.isGlass && pressed ? 0.98 : 1
                    Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
                    background: Rectangle {
                        radius: Theme.isGlass ? 24 : 12
                        color: "transparent"
                        border.width: option.selected ? 2.5 : option.visualFocus ? 2 : 1
                        border.color: option.selected ? Theme.accent : option.visualFocus ? Theme.focusRing : Theme.isGlass ? Qt.rgba(1, 1, 1, 0.8) : Theme.separator
                    }
                    contentItem: Item {
                        // Fixed miniatures of each material, independent of the current one.
                        Rectangle {
                            id: preview
                            x: 8; y: 8
                            width: parent.width - 16; height: 180
                            radius: Theme.isGlass ? 18 : 8
                            clip: true
                            color: option.modelData.key === "glass" ? "#e2e4e9" : "#f2f2f7"
                            // Glass miniature: wallpaper, frosted panels with rims, floating bar.
                            Item {
                                anchors.fill: parent
                                visible: option.modelData.key === "glass"
                                Rectangle { x: -40; y: -50; width: 220; height: 220; radius: 110; color: "#ffffff"; opacity: 0.9 }
                                Rectangle { x: parent.width * 0.42; y: 60; width: 170; height: 170; radius: 85; color: "#4a4e57"; opacity: 0.45 }
                                Rectangle { x: parent.width * 0.75; y: -30; width: 140; height: 140; radius: 70; color: "#8d939e"; opacity: 0.55 }
                                Repeater {
                                    model: [
                                        { x: 0.06, y: 0.16, w: 0.52, h: 0.5 },
                                        { x: 0.62, y: 0.16, w: 0.32, h: 0.5 }
                                    ]
                                    Rectangle {
                                        required property var modelData
                                        x: preview.width * modelData.x; y: preview.height * modelData.y
                                        width: preview.width * modelData.w; height: preview.height * modelData.h
                                        radius: 14
                                        color: Qt.rgba(1, 1, 1, 0.42)
                                        border.width: 1.2
                                        border.color: Qt.rgba(1, 1, 1, 0.95)
                                        Rectangle {
                                            anchors.fill: parent; anchors.margins: 1; radius: 13
                                            gradient: Gradient {
                                                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.6) }
                                                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0) }
                                            }
                                        }
                                    }
                                }
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom; anchors.bottomMargin: 10
                                    width: parent.width * 0.5; height: 24; radius: 12
                                    color: Qt.rgba(1, 1, 1, 0.5)
                                    border.width: 1.2; border.color: Qt.rgba(1, 1, 1, 0.95)
                                    Rectangle { x: 4; y: 3; width: parent.width / 4; height: 18; radius: 9; color: Qt.rgba(1, 1, 1, 0.85) }
                                }
                            }
                            // Solid miniature: white sidebar with a blue selection, grouped cells.
                            Item {
                                anchors.fill: parent
                                visible: option.modelData.key === "solid"
                                Rectangle {
                                    width: parent.width * 0.3; height: parent.height
                                    color: "#ffffff"
                                    Rectangle { x: 8; y: 14; width: parent.width * 0.6; height: 8; radius: 2; color: "#1d1d1f" }
                                    Repeater {
                                        model: 4
                                        Rectangle {
                                            required property int index
                                            x: 6; y: 34 + index * 22
                                            width: parent.width - 12; height: 18; radius: 5
                                            color: index === 0 ? "#007aff" : "transparent"
                                            Rectangle { x: 6; y: 5; width: 8; height: 8; radius: 2; color: index === 0 ? "#ffffff" : "#007aff" }
                                            Rectangle { x: 20; y: 7; width: parent.width * 0.45; height: 4; radius: 2; color: index === 0 ? "#ffffff" : "#8e8e93" }
                                        }
                                    }
                                }
                                Repeater {
                                    model: [{ y: 22, rows: 2 }, { y: 96, rows: 3 }]
                                    Item {
                                        required property var modelData
                                        x: preview.width * 0.36; y: modelData.y
                                        width: preview.width * 0.58; height: modelData.rows * 20
                                        Rectangle { x: 4; y: -10; width: 40; height: 4; radius: 2; color: "#8e8e93" }
                                        Rectangle { anchors.fill: parent; radius: 6; color: "#ffffff" }
                                        Repeater {
                                            model: parent.modelData.rows
                                            Item {
                                                required property int index
                                                y: index * 20; width: parent.width; height: 20
                                                Rectangle { x: 6; y: 5; width: 10; height: 10; radius: 3; color: "#8e8e93" }
                                                Rectangle { x: 22; y: 8; width: parent.width * 0.4; height: 4; radius: 2; color: "#3a3a3c" }
                                                Rectangle { x: 22; anchors.bottom: parent.bottom; width: parent.width - 22; height: 0.5; color: "#c6c6c8"; visible: index < parent.parent.modelData.rows - 1 }
                                            }
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 6; width: 54; height: 14; radius: 7; color: "#000000"
                            }
                        }
                        Row {
                            x: 16; y: preview.y + preview.height + 18
                            spacing: 10
                            Icon { anchors.verticalCenter: parent.verticalCenter; name: option.modelData.icon; size: 20; color: Theme.ink }
                            Label { anchors.verticalCenter: parent.verticalCenter; text: I18n.t(option.modelData.title); font.pixelSize: Theme.headline; font.weight: Font.DemiBold }
                        }
                        Item {
                            anchors.right: parent.right; anchors.rightMargin: 16
                            y: preview.y + preview.height + 16
                            width: 26; height: 26
                            Fill { anchors.fill: parent; radius: 13; color: option.selected ? Theme.accent : "transparent" }
                            Rectangle {
                                anchors.fill: parent; radius: 13
                                visible: !option.selected
                                color: "transparent"
                                border.width: 1.5
                                border.color: "#c7c7cc"
                            }
                            Icon {
                                anchors.centerIn: parent
                                name: "check"; size: 15; stroke: 2.4; color: "#ffffff"
                                scale: option.selected ? 1 : 0
                                Behavior on scale { SpringAnimation { spring: 5; damping: 0.28; epsilon: 0.001 } }
                            }
                        }
                    }
                }
            }
        }
    }
    Card {
        y: materialCard.height + Theme.gap
        width: parent.width
        height: headerHeight + Theme.rowHeight + (Theme.isGlass ? 18 : 0)
        Cell {
            y: Theme.isGlass ? 9 : 0
            icon: "island"
            tileColor: "#000000"
            title: I18n.t("look.island")
            last: true
            AppSwitch {
                objectName: "islandOverlayToggle"
                anchors.verticalCenter: parent.verticalCenter
                checked: page.islandOverlay
                Accessible.name: I18n.t("look.island")
                onToggled: page.islandOverlayRequested(checked)
            }
        }
    }
}
