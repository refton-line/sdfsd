import QtQuick
import QtQuick.Templates as T
import FakeClicker

// Language, the island overlay and version. The app has a single dark theme, so there is no
// appearance setting.
Item {
    id: page
    property string language: "en"
    property bool islandOverlay: true
    signal languageRequested(string code)
    signal islandOverlayRequested(bool value)

    readonly property real columnWidth: Math.min(width, 640)

    Column {
        width: page.columnWidth
        spacing: Theme.gap

        Panel {
            title: I18n.t("settings.language")
            width: parent.width
            height: headerHeight + languages.height + 8
            Column {
                id: languages
                x: 6; width: parent.width - 12
                spacing: 2
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
                        width: languages.width
                        height: 54
                        hoverEnabled: true
                        focusPolicy: Qt.StrongFocus
                        Accessible.role: Accessible.RadioButton
                        Accessible.name: modelData.name
                        Accessible.checked: selected
                        onClicked: if (!selected) page.languageRequested(modelData.code)
                        background: Rectangle {
                            radius: Theme.controlRadius
                            color: option.selected ? Theme.control : option.hovered ? Theme.raised : "transparent"
                            border.width: option.visualFocus ? 2 : option.selected ? 1 : 0
                            border.color: option.visualFocus ? Theme.focusRing : Theme.hairlineStrong
                        }
                        contentItem: Item {
                            KeyCap {
                                id: mark
                                x: 14; anchors.verticalCenter: parent.verticalCenter
                                size: 28
                                width: 36
                                text: option.modelData.mark
                                textColor: option.selected ? Theme.ink : Theme.muted
                            }
                            Label {
                                anchors.left: mark.right; anchors.leftMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                text: option.modelData.name
                                font.pixelSize: Theme.headline
                                font.weight: option.selected ? Font.DemiBold : Font.Medium
                                color: option.selected ? Theme.ink : Theme.inkSoft
                            }
                            // Radio: a white ring that fills when chosen.
                            Rectangle {
                                anchors.right: parent.right; anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20; height: 20; radius: 10
                                color: option.selected ? Theme.ink : "transparent"
                                border.width: option.selected ? 0 : 1.5
                                border.color: Theme.faint
                                Rectangle {
                                    anchors.centerIn: parent
                                    visible: option.selected
                                    width: 8; height: 8; radius: 4
                                    color: Theme.inverse
                                }
                            }
                        }
                    }
                }
            }
        }

        Panel {
            title: I18n.t("settings.island")
            width: parent.width
            height: headerHeight + Theme.rowHeight + 4
            SettingRow {
                icon: page.islandOverlay ? "overlay" : "overlayOff"
                title: I18n.t("look.island")
                last: true
                AppSwitch {
                    objectName: "islandOverlaySwitch"
                    anchors.verticalCenter: parent.verticalCenter
                    checked: page.islandOverlay
                    Accessible.name: I18n.t("look.island")
                    onToggled: { page.islandOverlayRequested(checked); checked = Qt.binding(() => page.islandOverlay); }
                }
            }
        }

        Panel {
            title: I18n.t("settings.about")
            width: parent.width
            height: headerHeight + 76
            SkullMark {
                id: aboutMark
                x: Theme.pad; y: 6
                size: 52
            }
            Column {
                anchors.left: aboutMark.right; anchors.leftMargin: 16
                anchors.verticalCenter: aboutMark.verticalCenter
                spacing: 5
                Label {
                    text: "FAKE CLICKER"
                    font.pixelSize: 16; font.weight: Font.Black
                    font.letterSpacing: 2
                }
                Label {
                    text: I18n.t("about.version") + " " + Qt.application.version + "  ·  " + I18n.t("about.build")
                    color: Theme.muted
                    font.family: Theme.mono
                    font.pixelSize: Theme.small
                }
            }
        }
    }
}
