import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import "components"

Item {
    id: page
    property var controller: null
    property var settings: ({})
    property var languages: []
    property var rules: []
    property var folders: []
    property var exclusions: []
    property var updateInfo: ({})

    Component.onCompleted: refreshAll()
    Connections {
        target: controller
        function onSettingsChanged() { refreshSettings() }
        function onRulesChanged() { refreshRules(); refreshFolders() }
        function onCustomFoldersChanged() { refreshFolders() }
        function onExclusionsChanged() { refreshExclusions() }
        function onLanguageChanged() { refreshSettings(); refreshLanguages() }
        function onUpdateInfoChanged() { refreshUpdate() }
    }
    function refreshAll() { refreshSettings(); refreshLanguages(); refreshRules(); refreshFolders(); refreshExclusions(); refreshUpdate() }
    function refreshSettings() { if (controller) try { settings = JSON.parse(controller.settingsJson) } catch(e){} }
    function refreshLanguages() { if (controller) try { languages = JSON.parse(controller.languagesJson) } catch(e){} }
    function refreshRules() { if (controller) try { rules = JSON.parse(controller.rulesJson) } catch(e){} }
    function refreshFolders() { if (controller) try { folders = JSON.parse(controller.customFoldersJson) } catch(e){} }
    function refreshExclusions() { if (controller) try { exclusions = JSON.parse(controller.exclusionsJson) } catch(e){} }
    function refreshUpdate() { if (controller) try { updateInfo = JSON.parse(controller.updateInfoJson) } catch(e){} }

    Flickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + 48
        clip: true
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 36
            spacing: 18

            // ---------------------------------------------------------- General
            Card {
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16
                    SectionTitle { text: controller ? controller.translate("settings.general") : "" }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label { text: controller ? controller.translate("settings.language") : ""; color: Theme.text; font.family: Theme.fontFamily; font.bold: true; font.pixelSize: 12 }
                            Label { text: controller ? controller.translate("settings.languageHint") : ""; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10; wrapMode: Text.WordWrap }
                        }
                        ComboBox {
                            id: langCombo
                            Layout.preferredWidth: 230
                            model: languages
                            textRole: "name"
                            valueRole: "code"
                            currentIndex: {
                                var code = settings.language || "auto"
                                for (var i = 0; i < languages.length; i++) if (languages[i].code === code) return i
                                return 0
                            }
                            onActivated: controller.setLanguage(currentValue)
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label { text: controller ? controller.translate("settings.theme") : ""; color: Theme.text; font.family: Theme.fontFamily; font.bold: true; font.pixelSize: 12 }
                        }
                        Segmented {
                            id: themeSegment
                            model: [
                                {value: "system", label: controller ? controller.translate("settings.theme.system") : ""},
                                {value: "light", label: controller ? controller.translate("settings.theme.light") : ""},
                                {value: "dark", label: controller ? controller.translate("settings.theme.dark") : ""}
                            ]
                            current: settings.theme || "system"
                            onSelected: controller.setTheme(value)
                        }
                    }
                }
            }

            // ---------------------------------------------------------- Safety
            Card {
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16
                    SectionTitle { text: controller ? controller.translate("settings.safety") : "" }

                    SettingToggle {
                        Layout.fillWidth: true
                        title: controller ? controller.translate("settings.useTrash") : ""
                        hint: controller ? controller.translate("settings.useTrashHint") : ""
                        checked: settings.useTrash !== false
                        onToggled: controller.setUseTrash(value)
                    }
                    SettingToggle {
                        Layout.fillWidth: true
                        title: controller ? controller.translate("settings.confirm") : ""
                        hint: controller ? controller.translate("settings.confirmHint") : ""
                        checked: settings.confirm !== false
                        onToggled: controller.setConfirm(value)
                    }
                    SettingToggle {
                        Layout.fillWidth: true
                        title: controller ? controller.translate("settings.autoUpdate") : ""
                        checked: settings.autoUpdate !== false
                        onToggled: controller.setAutoUpdate(value)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label { text: controller ? controller.translate("settings.minAge") : ""; color: Theme.text; font.family: Theme.fontFamily; font.bold: true; font.pixelSize: 12 }
                            Label { text: controller ? controller.translate("settings.minAgeHint") : ""; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10; wrapMode: Text.WordWrap }
                        }
                        SpinBox {
                            id: ageSpin
                            from: 0; to: 365
                            value: settings.minAge || 0
                            width: 120
                            onValueModified: controller.setMinAge(value)
                        }
                    }
                }
            }

            // ---------------------------------------------------- Custom folders
            Card {
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 14
                    SectionTitle { text: controller ? controller.translate("settings.folders") : "" }
                    Label { text: controller ? controller.translate("settings.foldersHint") : ""; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10; wrapMode: Text.WordWrap }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        TextField {
                            id: folderPathField
                            Layout.fillWidth: true
                            height: 38
                            placeholderText: controller ? controller.translate("settings.path") : ""
                            color: Theme.text; placeholderTextColor: Theme.textFaint
                            background: Rectangle { radius: Theme.radiusSmall; color: Theme.surfaceAlt; border.color: Theme.border; border.width: 1 }
                        }
                        TextField {
                            id: patternField
                            Layout.preferredWidth: 90
                            height: 38
                            text: "*"
                            placeholderText: "*"
                            color: Theme.text
                            background: Rectangle { radius: Theme.radiusSmall; color: Theme.surfaceAlt; border.color: Theme.border; border.width: 1 }
                        }
                        Button {
                            id: addFolderBtn
                            height: 38
                            enabled: folderPathField.text.length > 0
                            background: Rectangle { radius: Theme.radiusSmall; color: enabled ? Theme.accent : Theme.textFaint }
                            contentItem: Label { text: "+"; color: "white"; font.pixelSize: 18; font.bold: true }
                            onClicked: {
                                if (controller.addCustomFolder(folderPathField.text, patternField.text, "custom", 0)) {
                                    folderPathField.text = ""
                                    patternField.text = "*"
                                }
                            }
                        }
                    }

                    Repeater {
                        model: folders
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            radius: Theme.radiusSmall
                            color: Theme.surfaceAlt
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10
                                Label { text: "▣"; color: Theme.accent; font.pixelSize: 13 }
                                Label {
                                    text: modelData.paths ? modelData.paths[0] : ""
                                    color: Theme.text; font.family: Theme.monoFamily; font.pixelSize: 10
                                    Layout.fillWidth: true; elide: Text.ElideMiddle
                                }
                                Button {
                                    flat: true; width: 30; height: 30
                                    background: Rectangle { radius: 8; color: Theme.red; opacity: 0.10 }
                                    contentItem: Label { text: "×"; color: Theme.red; font.pixelSize: 16; font.bold: true }
                                    onClicked: controller.removeCustomFolder(modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            // ---------------------------------------------------- Rules
            Card {
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 10
                    SectionTitle { text: controller ? controller.translate("settings.rules") : "" }
                    Label { text: controller ? controller.translate("settings.rulesHint") : ""; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10; wrapMode: Text.WordWrap }

                    Repeater {
                        model: rules
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Label { text: modelData.displayName || modelData.name; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11 }
                                Label { text: modelData.displayDescription || modelData.description; color: Theme.textFaint; font.family: Theme.fontFamily; font.pixelSize: 9; elide: Text.ElideRight; Layout.fillWidth: true }
                            }
                            Label {
                                text: modelData.displayCategory || ""
                                color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 9
                                Layout.preferredWidth: 90
                            }
                            Toggle {
                                checked: modelData.enabled
                                onToggled: controller.setRuleEnabled(modelData.id, value)
                            }
                        }
                    }
                }
            }

            // ---------------------------------------------------- Exclusions
            Card {
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 12
                    SectionTitle { text: controller ? controller.translate("settings.exclusions") : "" }
                    Label { text: controller ? controller.translate("settings.exclusionsHint") : ""; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10; wrapMode: Text.WordWrap }

                    RowLayout {
                        Layout.fillWidth: true
                        Button {
                            flat: true; height: 36
                            background: Rectangle { radius: Theme.radiusSmall; color: Theme.surfaceAlt }
                            contentItem: Label { text: "+ " + (controller ? controller.translate("settings.addExclusion") : ""); color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 11 }
                            onClicked: controller.addExclusion(exclusionField.text)
                        }
                        TextField {
                            id: exclusionField
                            Layout.fillWidth: true
                            height: 36
                            placeholderText: controller ? controller.translate("settings.path") : ""
                            color: Theme.text; placeholderTextColor: Theme.textFaint
                            background: Rectangle { radius: Theme.radiusSmall; color: Theme.surfaceAlt; border.color: Theme.border; border.width: 1 }
                        }
                    }
                    Repeater {
                        model: exclusions
                        delegate: Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 36
                            radius: Theme.radiusSmall; color: Theme.surfaceAlt
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 10
                                Label { text: modelData; color: Theme.textMuted; font.family: Theme.monoFamily; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideMiddle }
                                Button {
                                    flat: true; width: 26; height: 26
                                    background: Rectangle { radius: 7; color: Theme.red; opacity: 0.10 }
                                    contentItem: Label { text: "×"; color: Theme.red; font.pixelSize: 14 }
                                    onClicked: controller.removeExclusion(modelData)
                                }
                            }
                        }
                    }
                }
            }

            // ---------------------------------------------------- Updates
            Card {
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 12
                    SectionTitle { text: controller ? controller.translate("settings.updates") : "" }
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true
                            Label {
                                text: {
                                    if (updateInfo.error) return controller.translate("settings.updateFailed", updateInfo.error)
                                    if (updateInfo.available) return controller.translate("settings.updateAvailable", updateInfo.latest)
                                    return controller.translate("settings.upToDate")
                                }
                                color: updateInfo.available ? Theme.amber : Theme.text
                                font.family: Theme.fontFamily; font.pixelSize: 11; wrapMode: Text.WordWrap
                            }
                            Label { text: controller.appVersion; color: Theme.textFaint; font.family: Theme.fontFamily; font.pixelSize: 10 }
                        }
                        Button {
                            flat: true; height: 36
                            background: Rectangle { radius: Theme.radiusSmall; color: Theme.accent; opacity: 0.14 }
                            contentItem: Label { text: controller ? controller.translate("settings.checkNow") : ""; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 11 }
                            onClicked: controller.checkForUpdates()
                        }
                        Button {
                            visible: updateInfo.available === true
                            flat: true; height: 36
                            background: Rectangle { radius: Theme.radiusSmall; color: Theme.green; opacity: 0.14 }
                            contentItem: Label { text: controller ? controller.translate("settings.download") : ""; color: Theme.green; font.family: Theme.fontFamily; font.pixelSize: 11 }
                            onClicked: controller.openReleases()
                        }
                    }
                }
            }

            Button {
                Layout.alignment: Qt.AlignRight
                flat: true; height: 36
                background: Rectangle { radius: Theme.radiusSmall; color: Theme.red; opacity: 0.10 }
                contentItem: Label { text: controller ? controller.translate("settings.reset") : ""; color: Theme.red; font.family: Theme.fontFamily; font.pixelSize: 11 }
                onClicked: resetDialog.open()
            }
        }
    }

    Dialog {
        id: resetDialog
        anchors.centerIn: parent
        width: 380
        modal: true
        title: controller ? controller.translate("settings.reset") : ""
        standardButtons: Dialog.Cancel | Dialog.Ok
        background: Rectangle { color: Theme.surface; radius: Theme.radius; border.color: Theme.border; border.width: 1 }
        Label { anchors.fill: parent; anchors.margins: 20; text: controller ? controller.translate("settings.resetConfirm") : ""; color: Theme.textMuted; wrapMode: Text.WordWrap; font: Theme.fontBody }
        onAccepted: { controller.resetSettings(); refreshAll() }
    }
}
