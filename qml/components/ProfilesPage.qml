import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Templates as T
import CClicker

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
        spacing: 10
        TextBox {
            id: query
            objectName: "configSearch"
            width: parent.width - importButton.width - folderButton.width - saveButton.width - 30
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

    Card {
        id: listCard
        title: Theme.isGlass ? "" : I18n.t("nav.profiles")
        y: toolbar.height + Theme.gap
        width: parent.width
        height: parent.height - y
        ListView {
            id: list
            objectName: "configList"
            anchors.fill: parent
            anchors.margins: Theme.isGlass ? 10 : 0
            clip: true
            spacing: Theme.isGlass ? 4 : 0
            model: page.store.profiles
            boundsBehavior: Flickable.StopAtBounds
            add: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.slow }
                    NumberAnimation { property: "scale"; from: 0.94; to: 1; duration: 460; easing.type: Easing.OutBack }
                }
            }
            displaced: Transition { SpringAnimation { property: "y"; spring: 4; damping: 0.34 } }
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            delegate: T.AbstractButton {
                id: row
                required property var modelData
                required property int index
                objectName: "profile_" + modelData.id
                width: list.width
                height: Theme.isGlass ? 66 : 60
                hoverEnabled: true
                focusPolicy: Qt.StrongFocus
                Accessible.name: modelData.name
                readonly property bool selected: page.selectedId === modelData.id
                readonly property bool showActions: (hovered || selected || visualFocus) && modelData.valid
                onClicked: { page.selectedId = modelData.id; page.selectedName = modelData.name; }
                onDoubleClicked: if (modelData.valid && !page.engine.active) page.store.apply(modelData.id)
                // Rows cascade in when the page opens.
                opacity: 0
                Component.onCompleted: rowIn.start()
                SequentialAnimation {
                    id: rowIn
                    PauseAnimation { duration: Math.min(row.index, 10) * 30 }
                    NumberAnimation { target: row; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
                }
                background: Rectangle {
                    radius: Theme.isGlass ? 18 : row.index === 0 || row.index === list.count - 1 ? 10 : 0
                    color: Theme.isGlass ? (row.selected ? Qt.rgba(1, 1, 1, 0.8) : row.hovered ? Qt.rgba(1, 1, 1, 0.45) : "transparent")
                                         : row.selected ? "#d1d1d6" : row.hovered ? "#f2f2f7" : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                    border.width: row.visualFocus ? 2 : Theme.isGlass && row.selected ? 1 : 0
                    border.color: row.visualFocus ? Theme.focusRing : Theme.hairline
                    Rectangle {
                        visible: !Theme.isGlass && row.index < list.count - 1
                        x: 70; anchors.bottom: parent.bottom
                        width: parent.width - x; height: 1
                        color: Theme.separator
                    }
                }
                contentItem: Item {
                    Rectangle {
                        id: tile
                        x: 10; anchors.verticalCenter: parent.verticalCenter
                        width: Theme.isGlass ? 42 : 36; height: width; radius: Theme.isGlass ? 13 : 8
                        color: !row.modelData.valid ? Theme.well : Theme.modeColor(row.modelData.mode === "blatant" ? 1 : 0)
                        Icon {
                            anchors.centerIn: parent
                            name: !row.modelData.valid ? "warning" : row.modelData.mode === "blatant" ? "bolt" : "hand"
                            size: 22; stroke: 2
                            color: row.modelData.valid ? "#ffffff" : Theme.danger
                        }
                    }
                    Column {
                        anchors.left: tile.right; anchors.leftMargin: 14
                        anchors.right: actions.left; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
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
                                height: 20; radius: 10
                                width: badgeText.implicitWidth + 16
                                color: Qt.rgba(0.204, 0.78, 0.349, 0.16)
                                Label { id: badgeText; anchors.centerIn: parent; text: I18n.t("profiles.active"); color: "#248a3d"; font.pixelSize: Theme.caption; font.weight: Font.DemiBold }
                            }
                        }
                        Label {
                            width: parent.width
                            elide: Text.ElideRight
                            text: row.modelData.valid
                                  ? I18n.t(row.modelData.mode === "blatant" ? "mode.blatant" : "mode.legit") + " · " + I18n.rate(row.modelData.cps) + " " + I18n.t("cps")
                                  : I18n.t("profiles.invalid") + " · " + I18n.msg(row.modelData.error)
                            color: row.modelData.valid ? Theme.muted : Theme.danger
                            font.pixelSize: Theme.small
                        }
                    }
                    Row {
                        id: actions
                        anchors.right: parent.right; anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        opacity: row.showActions ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: Theme.base } }
                        property real slide: row.showActions ? 0 : 16
                        Behavior on slide { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
                        transform: Translate { x: actions.slide }
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
                                kind: index === 0 ? "primary" : index === 4 && !Theme.isGlass ? "danger" : "normal"
                                iconName: modelData.icon; iconSize: 16
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
                        anchors.right: parent.right; anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 34; height: 34
                        iconName: "trash"; iconSize: 16
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
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.slow } }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 64; height: 64; radius: Theme.isGlass ? 20 : 14
                color: Theme.well
                Icon { anchors.centerIn: parent; name: page.store.searchQuery !== "" ? "search" : "stack"; size: 30; color: Theme.muted }
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
                font.pixelSize: Theme.title; font.weight: Font.DemiBold
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
                width: 48; height: 48; radius: Theme.isGlass ? 16 : 12
                color: Qt.rgba(1, 0.231, 0.188, 0.12)
                Icon { anchors.centerIn: parent; name: "trash"; size: 24; color: Theme.danger }
            }
            Label { text: I18n.t("profiles.deleteTitle"); font.pixelSize: Theme.title; font.weight: Font.DemiBold }
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
