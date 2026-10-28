import QtQuick
import QtQuick.Shapes
import QtQuick.Templates as T
import CClicker

Item {
    id: page
    property string material: "glass"
    property bool islandOverlay: true
    signal materialRequested(string value)
    signal islandOverlayRequested(bool value)

    Glass {
        id: materialCard
        width: parent.width
        height: 330
        Icon { x: 24; y: 24; name: "drop"; size: 20; color: Theme.inkSoft }
        Label { x: 56; y: 25; text: I18n.t("look.material"); font.pixelSize: Theme.headline; font.weight: Font.DemiBold }
        Row {
            x: 20; y: 68
            spacing: 16
            Repeater {
                model: [
                    { key: "glass", icon: "sparkle", title: "look.glass", sub: "look.glass.sub" },
                    { key: "solid", icon: "square", title: "look.solid", sub: "look.solid.sub" }
                ]
                T.AbstractButton {
                    id: option
                    required property var modelData
                    required property int index
                    objectName: "material_" + modelData.key
                    readonly property bool selected: page.material === modelData.key
                    width: (materialCard.width - 56) / 2
                    height: 240
                    hoverEnabled: true
                    focusPolicy: Qt.StrongFocus
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: I18n.t(modelData.title)
                    Accessible.checked: selected
                    onClicked: page.materialRequested(modelData.key)
                    scale: pressed ? 0.98 : 1
                    Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
                    background: Rectangle {
                        radius: 24
                        color: "transparent"
                        border.width: option.selected ? 2.5 : option.visualFocus ? 2 : 1
                        border.color: option.selected ? Theme.ink : option.visualFocus ? Theme.focusRing : Theme.hairline
                        Behavior on border.color { ColorAnimation { duration: Theme.base } }
                    }
                    contentItem: Item {
                        // Fixed miniatures of each material, independent of the current one.
                        Rectangle {
                            id: preview
                            x: 8; y: 8
                            width: parent.width - 16; height: 160
                            radius: 18
                            clip: true
                            color: option.modelData.key === "glass" ? "#e9ebf0" : "#f2f2f7"
                            Shape {
                                anchors.fill: parent
                                visible: option.modelData.key === "glass"
                                preferredRendererType: Shape.CurveRenderer
                                ShapePath {
                                    strokeColor: "transparent"
                                    fillGradient: RadialGradient {
                                        centerX: preview.width * 0.25; centerY: preview.height * 0.2
                                        focalX: centerX; focalY: centerY; centerRadius: preview.width * 0.5
                                        GradientStop { position: 0; color: "#ffffff" }
                                        GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
                                    }
                                    PathRectangle { width: preview.width; height: preview.height }
                                }
                                ShapePath {
                                    strokeColor: "transparent"
                                    fillGradient: RadialGradient {
                                        centerX: preview.width * 0.85; centerY: preview.height * 0.9
                                        focalX: centerX; focalY: centerY; centerRadius: preview.width * 0.55
                                        GradientStop { position: 0; color: Qt.rgba(0.62, 0.68, 0.79, 0.9) }
                                        GradientStop { position: 1; color: Qt.rgba(0.62, 0.68, 0.79, 0) }
                                    }
                                    PathRectangle { width: preview.width; height: preview.height }
                                }
                            }
                            Rectangle {
                                x: 22; y: 24
                                width: parent.width - 44; height: parent.height - 48
                                radius: 16
                                color: option.modelData.key === "glass" ? Qt.rgba(1, 1, 1, 0.45) : "#ffffff"
                                border.width: 1
                                border.color: option.modelData.key === "glass" ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(0, 0, 0, 0.06)
                                Rectangle {
                                    visible: option.modelData.key === "glass"
                                    anchors.fill: parent; anchors.margins: 1; radius: 15
                                    gradient: Gradient {
                                        GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.55) }
                                        GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0) }
                                    }
                                }
                                Rectangle { x: 16; y: 18; width: 30; height: 30; radius: 10; color: Theme.ink }
                                Rectangle { x: 58; y: 22; width: parent.width * 0.38; height: 8; radius: 4; color: Qt.rgba(0, 0, 0, 0.75) }
                                Rectangle { x: 58; y: 36; width: parent.width * 0.26; height: 6; radius: 3; color: Qt.rgba(0, 0, 0, 0.25) }
                                Rectangle {
                                    x: 16; anchors.bottom: parent.bottom; anchors.bottomMargin: 14
                                    width: parent.width - 32; height: 22; radius: 11
                                    color: option.modelData.key === "glass" ? Qt.rgba(1, 1, 1, 0.6) : "#f2f2f7"
                                    border.width: option.modelData.key === "glass" ? 1 : 0
                                    border.color: Qt.rgba(1, 1, 1, 0.9)
                                }
                            }
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 8; width: 64; height: 16; radius: 8; color: "#000000"
                            }
                        }
                        Row {
                            x: 16; y: preview.y + preview.height + 16
                            spacing: 10
                            Icon { anchors.verticalCenter: parent.verticalCenter; name: option.modelData.icon; size: 20; color: Theme.ink }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Label { text: I18n.t(option.modelData.title); font.pixelSize: Theme.headline; font.weight: Font.DemiBold }
                                Label { text: I18n.t(option.modelData.sub); font.pixelSize: Theme.small; color: Theme.muted }
                            }
                        }
                        Rectangle {
                            anchors.right: parent.right; anchors.rightMargin: 16
                            y: preview.y + preview.height + 22
                            width: 26; height: 26; radius: 13
                            color: option.selected ? Theme.ink : "transparent"
                            border.width: option.selected ? 0 : 1.5
                            border.color: Theme.faint
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
    Glass {
        y: materialCard.height + Theme.gutter
        width: parent.width
        height: 76
        Rectangle {
            x: 20; anchors.verticalCenter: parent.verticalCenter
            width: 40; height: 40; radius: 13; color: "#000000"
            Icon { anchors.centerIn: parent; name: "island"; size: 22; color: "#ffffff" }
        }
        Label {
            x: 76; anchors.verticalCenter: parent.verticalCenter
            text: I18n.t("look.island")
            font.pixelSize: Theme.body; font.weight: Font.Medium
        }
        Toggle {
            objectName: "islandOverlayToggle"
            anchors.right: parent.right; anchors.rightMargin: 22
            anchors.verticalCenter: parent.verticalCenter
            checked: page.islandOverlay
            Accessible.name: I18n.t("look.island")
            onToggled: page.islandOverlayRequested(checked)
        }
    }
}
