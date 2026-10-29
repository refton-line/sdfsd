import QtQuick
import QtQuick.Templates as T
import FakeClicker

// Language, window frame, island overlay, interface sounds and version, in two columns. The app
// has a single dark theme, so there is no appearance setting.
Item {
    id: page
    property string language: "en"
    property bool systemFrame: true
    property bool islandOverlay: true
    property bool soundsOn: true
    property int soundVolume: 70
    signal languageRequested(string code)
    signal systemFrameRequested(bool value)
    signal islandOverlayRequested(bool value)
    signal soundsRequested(bool value)
    signal soundVolumeRequested(int value)

    readonly property real columnWidth: (width - Theme.gap) / 2

    Row {
        spacing: Theme.gap
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
                            height: 50
                            hoverEnabled: true
                            focusPolicy: Qt.StrongFocus
                            Accessible.role: Accessible.RadioButton
                            Accessible.name: modelData.name
                            Accessible.checked: selected
                            onClicked: if (!selected) { sounds.play("select"); page.languageRequested(modelData.code); }
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
                title: I18n.t("settings.window")
                width: parent.width
                height: headerHeight + Theme.rowHeight + 4
                SettingRow {
                    icon: "winMax"
                    title: I18n.t("look.frame")
                    last: true
                    AppSwitch {
                        objectName: "systemFrameSwitch"
                        anchors.verticalCenter: parent.verticalCenter
                        checked: page.systemFrame
                        Accessible.name: I18n.t("look.frame")
                        onToggled: { page.systemFrameRequested(checked); checked = Qt.binding(() => page.systemFrame); }
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
        }

        Column {
            width: page.columnWidth
            spacing: Theme.gap
            Panel {
                title: I18n.t("settings.sound")
                width: parent.width
                height: headerHeight + 2 * Theme.rowHeight + 4
                Column {
                    width: parent.width
                    SettingRow {
                        icon: page.soundsOn ? "volume" : "volumeOff"
                        title: I18n.t("sound.effects")
                        AppSwitch {
                            objectName: "soundsSwitch"
                            anchors.verticalCenter: parent.verticalCenter
                            audible: false
                            checked: page.soundsOn
                            Accessible.name: I18n.t("sound.effects")
                            // Turning sounds off still clicks; turning them on clicks once they are on.
                            onToggled: {
                                if (!checked) sounds.preview("switchOff");
                                page.soundsRequested(checked);
                                if (checked) sounds.play("switchOn");
                                checked = Qt.binding(() => page.soundsOn);
                            }
                        }
                    }
                    SettingRow {
                        icon: "wave"
                        title: I18n.t("sound.volume")
                        last: true
                        enabled: page.soundsOn
                        Stepper {
                            objectName: "soundVolume"
                            anchors.verticalCenter: parent.verticalCenter
                            width: 148
                            from: 10; to: 100; step: 10
                            unit: "%"
                            value: page.soundVolume
                            cue: ""
                            // The new level is heard right away.
                            onValueModified: v => { page.soundVolumeRequested(v); sounds.play("tap"); }
                        }
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
                    audible: true
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: aboutMark.chomp()
                    }
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
}
