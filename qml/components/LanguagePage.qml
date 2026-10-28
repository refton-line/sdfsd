import QtQuick
import QtQuick.Templates as T
import CClicker

Item {
    id: page
    property string language: "en"
    signal languageRequested(string code)

    Card {
        title: Theme.isGlass ? "" : I18n.t("nav.language")
        width: parent.width
        height: headerHeight + list.height + (Theme.isGlass ? 20 : 0)
        Column {
            id: list
            y: Theme.isGlass ? 10 : 0
            width: parent.width
            Repeater {
                model: [
                    { code: "en", name: "English", mark: "EN" },
                    { code: "ru", name: "Русский", mark: "RU" }
                ]
                T.AbstractButton {
                    id: option
                    required property var modelData
                    required property int index
                    objectName: "language_" + modelData.code
                    readonly property bool selected: page.language === modelData.code
                    x: Theme.isGlass ? 10 : 0
                    width: list.width - 2 * x
                    height: Theme.isGlass ? 72 : 56
                    hoverEnabled: true
                    focusPolicy: Qt.StrongFocus
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: modelData.name
                    Accessible.checked: selected
                    onClicked: if (!selected) page.languageRequested(modelData.code)
                    scale: Theme.isGlass && pressed ? 0.985 : 1
                    Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
                    background: Rectangle {
                        radius: Theme.isGlass ? 20 : option.index === 0 ? 10 : 0
                        color: Theme.isGlass ? (option.selected ? Qt.rgba(1, 1, 1, 0.78) : option.hovered ? Qt.rgba(1, 1, 1, 0.4) : "transparent")
                                             : option.pressed ? "#d1d1d6" : option.hovered ? "#f2f2f7" : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                        border.width: option.visualFocus ? 2 : Theme.isGlass && option.selected ? 1 : 0
                        border.color: option.visualFocus ? Theme.focusRing : Theme.hairline
                        Rectangle {
                            visible: !Theme.isGlass && option.index === 0
                            x: 62; anchors.bottom: parent.bottom
                            width: parent.width - x; height: 1
                            color: Theme.separator
                        }
                    }
                    contentItem: Item {
                        Rectangle {
                            id: mark
                            x: Theme.isGlass ? 14 : 16; anchors.verticalCenter: parent.verticalCenter
                            width: Theme.isGlass ? 46 : 32; height: width; radius: Theme.isGlass ? 15 : 8
                            color: option.selected ? Theme.accent : Theme.isGlass ? Theme.well : "#8e8e93"
                            Behavior on color { ColorAnimation { duration: Theme.base } }
                            Label {
                                anchors.centerIn: parent
                                text: option.modelData.mark
                                color: option.selected || !Theme.isGlass ? "#ffffff" : Theme.inkSoft
                                font.pixelSize: Theme.isGlass ? 15 : 12; font.weight: Font.Bold
                            }
                        }
                        Column {
                            anchors.left: mark.right; anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Label { text: option.modelData.name; font.pixelSize: Theme.isGlass ? 17 : 15; font.weight: Theme.isGlass ? Font.DemiBold : Font.Normal }
                            // The language's name in the current UI language, when it differs.
                            Label {
                                text: I18n.t("lang." + option.modelData.code)
                                visible: text !== option.modelData.name
                                color: Theme.muted
                                font.pixelSize: Theme.small
                            }
                        }
                        // Glass: radio disc. Solid: iOS checkmark.
                        Rectangle {
                            visible: Theme.isGlass
                            anchors.right: parent.right; anchors.rightMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
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
                        Icon {
                            visible: !Theme.isGlass && option.selected
                            anchors.right: parent.right; anchors.rightMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            name: "check"; size: 18; stroke: 2.4; color: "#007aff"
                        }
                    }
                }
            }
        }
    }
}
