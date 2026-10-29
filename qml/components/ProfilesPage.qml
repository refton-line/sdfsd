import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Templates as T
import FakeClicker

Item {
    id: page
    property var engine
    property var store
    property string selectedId: ""
    property string selectedName: ""

    Component.onCompleted: { store.searchQuery = ""; store.refresh(); }

    Row {
        id: toolbar
        width: parent.width
        spacing: 8
        TextBox {
            id: query
            objectName: "configSearch"
            width: parent.width - importButton.width - folderButton.width - saveButton.width - 3 * parent.spacing
            iconName: "search"
            placeholderText: I18n.t("profiles.search")
            onTextEdited: page.store.searchQuery = text
        }
        AppButton {
            id: importButton
            objectName: "importConfig"
            width: query.height; height: query.height
            iconName: "importTray"
            Accessible.name: I18n.t("profiles.import")
            onClicked: importDialog.open()
        }
        AppButton {
            id: folderButton
            objectName: "openConfigFolder"
            width: query.height; height: query.height
            iconName: "folder"
            Accessible.name: I18n.t("profiles.folder")
            onClicked: page.store.openFolder()
        }
        AppButton {
            id: saveButton
            objectName: "saveConfig"
            height: query.height
            kind: "primary"
            iconName: "plus"
            text: I18n.t("profiles.save")
            onClicked: { nameDialog.renaming = false; nameField.text = ""; nameDialog.open(); }
        }
    }

    Panel {
        id: listCard
        y: toolbar.height + Theme.gap
        width: parent.width
        height: parent.height - y
        ListView {
            id: list
            objectName: "configList"
            anchors.fill: parent
            anchors.margins: 6
            clip: true
            spacing: 2
            model: page.store.profiles
            boundsBehavior: Flickable.StopAtBounds
            add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.base } }
            displaced: Transition { NumberAnimation { property: "y"; duration: Theme.base; easing.type: Easing.OutCubic } }
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.controlActive }
            }
            delegate: T.AbstractButton {
                id: row
                required property var modelData
                required property int index
                objectName: "profile_" + modelData.id
                width: list.width
                height: 62
                hoverEnabled: true
                focusPolicy: Qt.StrongFocus
                Accessible.name: modelData.name
                readonly property bool selected: page.selectedId === modelData.id
                readonly property bool showActions: (hovered || selected || visualFocus) && modelData.valid
                readonly property int mode: modelData.mode === "blatant" ? 1 : 0
                onClicked: { page.selectedId = modelData.id; page.selectedName = modelData.name; }
                onDoubleClicked: if (modelData.valid && !page.engine.active) page.store.apply(modelData.id)
                background: Rectangle {
                    radius: Theme.controlRadius
                    color: row.selected ? Theme.control : row.hovered ? Theme.raised : "transparent"
                    border.width: row.visualFocus ? 2 : row.selected ? 1 : 0
                    border.color: row.visualFocus ? Theme.focusRing : Theme.hairlineStrong
                }
                contentItem: Item {
                    Rectangle {
                        id: tile
                        x: 12; anchors.verticalCenter: parent.verticalCenter
                        width: 38; height: 38; radius: Theme.controlRadius
                        color: !row.modelData.valid ? Theme.tint(Theme.danger, 0.12) : Theme.tint(Theme.modeColor(row.mode), 0.14)
                        border.width: 1
                        border.color: !row.modelData.valid ? Theme.tint(Theme.danger, 0.4) : Theme.tint(Theme.modeColor(row.mode), 0.4)
                        Icon {
                            anchors.centerIn: parent
                            name: !row.modelData.valid ? "warning" : row.mode === 1 ? "bolt" : "hand"
                            size: 19; stroke: 2
                            color: !row.modelData.valid ? Theme.dangerText : Theme.modeColor(row.mode)
                        }
                    }
                    Column {
                        anchors.left: tile.right; anchors.leftMargin: 14
                        anchors.right: actions.left; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Row {
                            spacing: 8
                            width: parent.width
                            Label {
                                text: row.modelData.name
                                width: Math.min(implicitWidth, parent.width - (activeBadge.visible ? activeBadge.width + 8 : 0))
                                elide: Text.ElideRight
                                font.pixelSize: Theme.headline; font.weight: Font.DemiBold
                            }
                            Rectangle {
                                id: activeBadge
                                visible: row.modelData.active
                                anchors.verticalCenter: parent.verticalCenter
                                height: 18; radius: 9
                                width: badgeText.implicitWidth + 14
                                color: Theme.ink
                                Label {
                                    id: badgeText
                                    anchors.centerIn: parent
                                    text: I18n.t("profiles.active")
                                    color: Theme.inverse
                                    font.family: Theme.mono
                                    font.pixelSize: 10; font.weight: Font.DemiBold
                                    font.capitalization: Font.AllUppercase
                                    font.letterSpacing: 0.6
                                }
                            }
                        }
                        Label {
                            width: parent.width
                            elide: Text.ElideRight
                            text: row.modelData.valid
                                  ? I18n.t(row.mode === 1 ? "mode.blatant" : "mode.legit") + "  ·  " + I18n.rate(row.modelData.cps) + " " + I18n.t("cps")
                                  : I18n.t("profiles.invalid") + " · " + I18n.msg(row.modelData.error)
                            color: row.modelData.valid ? Theme.muted : Theme.dangerText
                            font.pixelSize: Theme.small
                        }
                    }
                    Row {
                        id: actions
                        anchors.right: parent.right; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        opacity: row.showActions ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                        Repeater {
                            model: [
                                { icon: "check", tip: "profiles.apply", name: "applyConfig" },
                                { icon: "pencil", tip: "profiles.rename", name: "renameConfig" },
                                { icon: "duplicate", tip: "profiles.duplicate", name: "duplicateConfig" },
                                { icon: "exportTray", tip: "profiles.export", name: "exportConfig" },
                                { icon: "trash", tip: "profiles.delete", name: "deleteConfig" }
                            ]
                            AppButton {
                                required property var modelData
                                required property int index
                                objectName: modelData.name
                                width: 34; height: 34
                                kind: index === 0 ? "primary" : "normal"
                                iconName: modelData.icon; iconSize: 15
                                Accessible.name: I18n.t(modelData.tip)
                                enabled: index !== 0 || !page.engine.active
                                onClicked: {
                                    page.selectedId = row.modelData.id;
                                    page.selectedName = row.modelData.name;
                                    switch (index) {
                                    case 0: page.store.apply(row.modelData.id); break;
                                    case 1: nameDialog.renaming = true; nameField.text = row.modelData.name; nameDialog.open(); break;
                                    case 2: page.store.duplicate(row.modelData.id); break;
                                    case 3: exportDialog.open(); break;
                                    case 4: deleteDialog.open(); break;
                                    }
                                }
                            }
                        }
                    }
                    AppButton {
                        visible: !row.modelData.valid && (row.hovered || row.selected)
                        anchors.right: parent.right; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 34; height: 34
                        iconName: "trash"; iconSize: 15
                        Accessible.name: I18n.t("profiles.delete")
                        onClicked: { page.selectedId = row.modelData.id; page.selectedName = row.modelData.name; deleteDialog.open(); }
                    }
                }
            }
        }
        Column {
            anchors.centerIn: parent
            spacing: 14
            visible: page.store.profiles.length === 0
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 60; height: 60; radius: 16
                color: Theme.raised
                border.width: 1
                border.color: Theme.hairlineStrong
                Icon { anchors.centerIn: parent; name: page.store.searchQuery !== "" ? "search" : "stack"; size: 26; color: Theme.muted }
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: I18n.t(page.store.searchQuery !== "" ? "profiles.noResults" : "profiles.empty")
                color: Theme.muted
                font.pixelSize: Theme.headline; font.weight: Font.DemiBold
            }
        }
    }

    FileDialog {
        id: importDialog
        title: I18n.t("profiles.import")
        nameFilters: [I18n.t("profiles.filter")]
        onAccepted: page.store.importFile(selectedFile)
    }
    FileDialog {
        id: exportDialog
        title: I18n.t("profiles.export")
        fileMode: FileDialog.SaveFile
        defaultSuffix: "json"
        nameFilters: [I18n.t("profiles.filter")]
        onAccepted: page.store.exportFile(page.selectedId, selectedFile)
    }
    ModalSheet {
        id: nameDialog
        objectName: "configNameDialog"
        property bool renaming: false
        width: 440
        onOpened: nameField.forceActiveFocus()
        contentItem: Column {
            spacing: 20
            Label {
                text: I18n.t(nameDialog.renaming ? "profiles.renameTitle" : "profiles.saveTitle")
                font.pixelSize: Theme.title; font.weight: Font.Bold
            }
            TextBox {
                id: nameField
                objectName: "profileNameField"
                width: parent.width
                maximumLength: 64
                placeholderText: I18n.t("profiles.name")
                Accessible.name: I18n.t("profiles.name")
                onAccepted: confirmName.clicked()
            }
            Row {
                anchors.right: parent.right
                spacing: 10
                AppButton { text: I18n.t("cancel"); onClicked: nameDialog.close() }
                AppButton {
                    id: confirmName
                    objectName: "confirmSaveConfig"
                    kind: "primary"
                    text: I18n.t(nameDialog.renaming ? "profiles.rename" : "profiles.save.short")
                    enabled: nameField.text.trim().length > 0
                    onClicked: {
                        const ok = nameDialog.renaming ? page.store.rename(page.selectedId, nameField.text) : page.store.saveNew(nameField.text);
                        if (ok) nameDialog.close();
                    }
                }
            }
        }
    }
    ModalSheet {
        id: deleteDialog
        objectName: "deleteConfigDialog"
        width: 420
        contentItem: Column {
            spacing: 16
            Rectangle {
                width: 44; height: 44; radius: 12
                color: Theme.tint(Theme.danger, 0.14)
                border.width: 1
                border.color: Theme.tint(Theme.danger, 0.4)
                Icon { anchors.centerIn: parent; name: "trash"; size: 20; color: Theme.dangerText }
            }
            Label { text: I18n.t("profiles.deleteTitle"); font.pixelSize: Theme.title; font.weight: Font.Bold }
            Label { width: parent.width; text: page.selectedName; elide: Text.ElideRight; color: Theme.muted; font.pixelSize: Theme.headline }
            Row {
                anchors.right: parent.right
                spacing: 10
                AppButton { text: I18n.t("cancel"); onClicked: deleteDialog.close() }
                AppButton {
                    objectName: "confirmDeleteConfig"
                    kind: "danger"
                    iconName: "trash"
                    text: I18n.t("profiles.delete")
                    onClicked: if (page.store.remove(page.selectedId)) { page.selectedId = ""; deleteDialog.close(); }
                }
            }
        }
    }
}
