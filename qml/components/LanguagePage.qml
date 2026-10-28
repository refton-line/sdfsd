import QtQuick
import QtQuick.Templates as T
import CClicker

Item {
    id: page
    property string language: "en"
    signal languageRequested(string code)

    Glass {
        width: parent.width
        height: list.height + 40
        Column {
            id: list
            x: 12; y: 20
            width: parent.width - 24
            spacing: 6
            Repeater {
                model: [
                    { code: "en", name: "English", mark: "EN" },
                    { code: "ru", name: "Русский", mark: "RU" }
                ]
                T.AbstractButton {
                    id: option
                    required property var modelData
                    objectName: "language_" + modelData.code
                    readonly property bool selected: page.language === modelData.code
                    width: list.width
                    height: 72
                    hoverEnabled: true
                    focusPolicy: Qt.StrongFocus
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: modelData.name
                    Accessible.checked: selected
                    onClicked: if (!selected) page.languageRequested(modelData.code)
                    scale: pressed ? 0.985 : 1
                    Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
                    background: Rectangle {
                        radius: 20
                        color: option.selected ? Qt.rgba(1, 1, 1, 0.78) : option.hovered ? Qt.rgba(1, 1, 1, 0.4) : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.base } }
                        border.width: option.visualFocus ? 2 : option.selected ? 1 : 0
                        border.color: option.visualFocus ? Theme.focusRing : Theme.hairline
                    }
                    contentItem: Item {
                        Rectangle {
                            id: mark
                            x: 14; anchors.verticalCenter: parent.verticalCenter
                            width: 46; height: 46; radius: 15
                            color: option.selected ? Theme.ink : Theme.well
                            Behavior on color { ColorAnimation { duration: Theme.base } }
                            Label {
                                anchors.centerIn: parent
                                text: option.modelData.mark
                                color: option.selected ? "#ffffff" : Theme.inkSoft
                                font.pixelSize: 15; font.weight: Font.Bold
                            }
                        }
                        Column {
                            anchors.left: mark.right; anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Label { text: option.modelData.name; font.pixelSize: 17; font.weight: Font.DemiBold }
                            // The language's name in the current UI language, when it differs.
                            Label {
                                text: I18n.t("lang." + option.modelData.code)
                                visible: text !== option.modelData.name
                                color: Theme.muted
                                font.pixelSize: Theme.small
                            }
                        }
                        Rectangle {
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
                    }
                }
            }
        }
    }
}
