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
        contentHeight: contentColumn.height + Theme.pagePadding * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Theme.pagePadding
            anchors.rightMargin: Theme.pagePadding
            anchors.topMargin: Theme.pagePadding
            spacing: 16

            // ---------------------------------------------------------- General
            Card {
                Layout.fillWidth: true
                contentMargins: 24
                contentSpacing: 18
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 18
                    SectionTitle { text: controller ? controller.translate("settings.general") : "" }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Label { text: controller ? controller.translate("settings.language") : ""; color: Theme.text; font.family: Theme.fontFamily; font.bold: true; font.pixelSize: 12 }
                            Label { text: controller ? controller.translate("settings.languageHint") : ""; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        }
                        ComboBox {
                            id: langCombo
                            Layout.preferredWidth: 240
                            Layout.preferredHeight: 40
                            model: languages
                            textRole: "name"
                            valueRole: "code"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            currentIndex: {
                                var code = settings.language || "auto"
                                for (var i = 0; i < languages.length; i++) if (languages[i].code === code) return i
                                return 0
                            }
                            onActivated: controller.setLanguage(currentValue)
                        }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.border }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Label { text: controller ? controller.translate("settings.theme") : ""; color: Theme.text; font.family: Theme.fontFamily; font.bold: true; font.pixelSize: 12 }
                        }
                        Segmented {
                            id: themeSegment
                            Layout.preferredWidth: 280
                            Layout.preferredHeight: 40
                            model: [
                                {value: "system", label: controller ? controller.translate("settings.theme.system") : ""},
                                {value: "light", label: controller ? controller.translate("settings.theme.light") : ""},
                                {value: "dark", label: controller ? controller.translate("settings.theme.dark") : ""}
                            ]
                            current: settings.theme || "dark"
                            onSelected: controller.setTheme(value)
                        }
                    }
                }
            }

            // ---------------------------------------------------------- Safety
            Card {
                Layout.fillWidth: true
                contentMargins: 24
                contentSpacing: 16
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    SectionTitle { text: controller ? controller.translate("settings.safety") : "" }

                    SettingToggle {
                        Layout.fillWidth: true
                        title: controller ? controller.translate("settings.useTrash") : ""
                        hint: controller ? controller.translate("settings.useTrashHint") : ""
                        checked: settings.useTrash !== false
                        onToggled: controller.setUseTrash(value)
                    }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.border }
                    SettingToggle {
                        Layout.fillWidth: true
                        title: controller ? controller.translate("settings.confirm") : ""
                        hint: controller ? controller.translate("settings.confirmHint") : ""
                        checked: settings.confirm !== false
                        onToggled: controller.setConfirm(value)
                    }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.border }
                    SettingToggle {
                        Layout.fillWidth: true
                        title: controller ? controller.translate("settings.autoUpdate") : ""
                        checked: settings.autoUpdate !== false
                        onToggled: controller.setAutoUpdate(value)
                    }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.border }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Label { text: controller ? controller.translate("settings.minAge") : ""; color: Theme.text; font.family: Theme.fontFamily; font.bold: true; font.pixelSize: 12 }
                            Label { text: controller ? controller.translate("settings.minAgeHint") : ""; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        }
                        SpinBox {
                            id: ageSpin
                            Layout.preferredWidth: 128
                            Layout.preferredHeight: 40
                            from: 0; to: 365
                            value: settings.minAge || 0
                            font.family: Theme.fontFamily
                            onValueModified: controller.setMinAge(value)
                        }
                    }
                }
            }

            // ---------------------------------------------------- Custom folders
            Card {
                Layout.fillWidth: true
                contentMargins: 24
                contentSpacing: 14
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 14
                    SectionTitle { text: controller ? controller.translate("settings.folders") : "" }
                    Label {
                        text: controller ? controller.translate("settings.foldersHint") : ""
                        color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10
                        wrapMode: Text.WordWrap; Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        TextField {
                            id: folderPathField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            leftPadding: 12; rightPadding: 12
                            placeholderText: controller ? controller.translate("settings.path") : ""
                            color: Theme.text; placeholderTextColor: Theme.textFaint
                            font.family: Theme.fontFamily; font.pixelSize: 12
                            selectByMouse: true
                            background: Rectangle { radius: Theme.radiusSmall; color: Theme.surfaceAlt; border.color: Theme.border; border.width: 1 }
                        }
                        TextField {
                            id: patternField
                            Layout.preferredWidth: 92
                            Layout.preferredHeight: 40
                            leftPadding: 12; rightPadding: 12
                            text: "*"
                            placeholderText: "*"
                            color: Theme.text; placeholderTextColor: Theme.textFaint
                            font.family: Theme.monoFamily; font.pixelSize: 12
                            selectByMouse: true
                            background: Rectangle { radius: Theme.radiusSmall; color: Theme.surfaceAlt; border.color: Theme.border; border.width: 1 }
                        }
                        AppButton {
                            id: addFolderBtn
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 40
                            enabled: folderPathField.text.length > 0
                            background: Rectangle { radius: Theme.radiusSmall; color: addFolderBtn.enabled ? Theme.accent : Theme.textFaint }
                            contentItem: Label { text: "+"; color: "white"; font.pixelSize: 18; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                            onClicked: {
                                if (controller.addCustomFolder(folderPathField.text, patternField.text, "custom", 0)) {
                                    folderPathField.text = ""
                                    patternField.text = "*"
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Repeater {
                            model: folders
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 46
                                radius: Theme.radiusSmall
                                color: Theme.surfaceAlt
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 8
                                    spacing: 10
                                    Label { text: "▣"; color: Theme.accent; font.pixelSize: 13 }
                                    Label {
                                        text: modelData.paths ? modelData.paths[0] : ""
                                        color: Theme.text; font.family: Theme.monoFamily; font.pixelSize: 10
                                        Layout.fillWidth: true; elide: Text.ElideMiddle
                                    }
                                    AppButton {
                                        flat: true
                                        Layout.preferredWidth: 30
                                        Layout.preferredHeight: 30
                                        background: Rectangle { radius: 8; color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.12) }
                                        contentItem: Label { text: "×"; color: Theme.red; font.pixelSize: 16; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                                        onClicked: controller.removeCustomFolder(modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---------------------------------------------------- Rules
            Card {
                Layout.fillWidth: true
                contentMargins: 24
                contentSpacing: 12
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    SectionTitle { text: controller ? controller.translate("settings.rules") : "" }
                    Label {
                        text: controller ? controller.translate("settings.rulesHint") : ""
                        color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10
                        wrapMode: Text.WordWrap; Layout.fillWidth: true
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Repeater {
                            model: rules
                            delegate: RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 46
                                spacing: 12
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Label { text: modelData.displayName || modelData.name; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11 }
                                    Label { text: modelData.displayDescription || modelData.description; color: Theme.textFaint; font.family: Theme.fontFamily; font.pixelSize: 9; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                                Label {
                                    text: modelData.displayCategory || ""
                                    color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 9
                                    Layout.preferredWidth: 96
                                    elide: Text.ElideRight
                                }
                                Toggle {
                                    checked: modelData.enabled
                                    onToggled: controller.setRuleEnabled(modelData.id, value)
                                }
                            }
                        }
                    }
                }
            }

            // ---------------------------------------------------- Exclusions
            Card {
                Layout.fillWidth: true
                contentMargins: 24
                contentSpacing: 12
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    SectionTitle { text: controller ? controller.translate("settings.exclusions") : "" }
                    Label {
                        text: controller ? controller.translate("settings.exclusionsHint") : ""
                        color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10
                        wrapMode: Text.WordWrap; Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        TextField {
                            id: exclusionField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            leftPadding: 12; rightPadding: 12
                            placeholderText: controller ? controller.translate("settings.path") : ""
                            color: Theme.text; placeholderTextColor: Theme.textFaint
                            font.family: Theme.fontFamily; font.pixelSize: 12
                            selectByMouse: true
                            background: Rectangle { radius: Theme.radiusSmall; color: Theme.surfaceAlt; border.color: Theme.border; border.width: 1 }
                        }
                        AppButton {
                            flat: true
                            Layout.preferredHeight: 40
                            leftPadding: 16; rightPadding: 16
                            background: Rectangle { radius: Theme.radiusSmall; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14) }
                            contentItem: Label {
                                text: "+ " + (controller ? controller.translate("settings.addExclusion") : "")
                                color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                            }
                            onClicked: {
                                if (controller.addExclusion(exclusionField.text)) exclusionField.text = ""
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Repeater {
                            model: exclusions
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                radius: Theme.radiusSmall
                                color: Theme.surfaceAlt
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 6
                                    spacing: 8
                                    Label {
                                        text: modelData; color: Theme.textMuted; font.family: Theme.monoFamily; font.pixelSize: 10
                                        Layout.fillWidth: true; elide: Text.ElideMiddle
                                    }
                                    AppButton {
                                        flat: true
                                        Layout.preferredWidth: 28
                                        Layout.preferredHeight: 28
                                        background: Rectangle { radius: 7; color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.12) }
                                        contentItem: Label { text: "×"; color: Theme.red; font.pixelSize: 15; horizontalAlignment: Text.AlignHCenter }
                                        onClicked: controller.removeExclusion(modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---------------------------------------------------- Updates
            Card {
                Layout.fillWidth: true
                contentMargins: 24
                contentSpacing: 12
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 14
                    SectionTitle { text: controller ? controller.translate("settings.updates") : "" }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Label {
                                text: {
                                    if (updateInfo.error) return controller.translateArg("settings.updateFailed", updateInfo.error)
                                    if (updateInfo.available) return controller.translateArg("settings.updateAvailable", updateInfo.latest)
                                    return controller.translate("settings.upToDate")
                                }
                                color: updateInfo.available ? Theme.amber : Theme.text
                                font.family: Theme.fontFamily; font.pixelSize: 11
                                wrapMode: Text.WordWrap; Layout.fillWidth: true
                            }
                            Label { text: controller.appVersion; color: Theme.textFaint; font.family: Theme.monoFamily; font.pixelSize: 10 }
                        }
                        AppButton {
                            flat: true
                            Layout.preferredHeight: 38
                            leftPadding: 16; rightPadding: 16
                            background: Rectangle { radius: Theme.radiusSmall; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14) }
                            contentItem: Label {
                                text: controller ? controller.translate("settings.checkNow") : ""
                                color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                            }
                            onClicked: controller.checkForUpdates()
                        }
                        AppButton {
                            visible: updateInfo.available === true
                            flat: true
                            Layout.preferredHeight: 38
                            leftPadding: 16; rightPadding: 16
                            background: Rectangle { radius: Theme.radiusSmall; color: Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.14) }
                            contentItem: Label {
                                text: controller ? controller.translate("settings.download") : ""
                                color: Theme.green; font.family: Theme.fontFamily; font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                            }
                            onClicked: controller.openReleases()
                        }
                    }
                }
            }

            AppButton {
                Layout.alignment: Qt.AlignRight
                flat: true
                Layout.preferredHeight: 38
                leftPadding: 16; rightPadding: 16
                background: Rectangle { radius: Theme.radiusSmall; color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.12) }
                contentItem: Label {
                    text: controller ? controller.translate("settings.reset") : ""
                    color: Theme.red; font.family: Theme.fontFamily; font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                }
                onClicked: resetDialog.open()
            }
        }
    }

    Dialog {
        id: resetDialog
        anchors.centerIn: parent
        width: 420
        modal: true
        padding: 0
        closePolicy: Popup.CloseOnEscape
        background: Rectangle { color: Theme.surface; radius: Theme.radius; border.color: Theme.border; border.width: 1 }

        header: Label {
            text: controller ? controller.translate("settings.reset") : ""
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 16
            font.bold: true
            leftPadding: 26
            rightPadding: 26
            topPadding: 24
            bottomPadding: 0
        }

        contentItem: Label {
            text: controller ? controller.translate("settings.resetConfirm") : ""
            color: Theme.textMuted
            wrapMode: Text.WordWrap
            font.family: Theme.fontFamily
            font.pixelSize: 12
            lineHeight: 1.35
        }

        footer: Item {
            implicitHeight: 76
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 26
                anchors.rightMargin: 26
                anchors.bottomMargin: 22
                anchors.topMargin: 8
                spacing: 10
                Item { Layout.fillWidth: true }
                AppButton {
                    flat: true
                    Layout.preferredHeight: 40
                    leftPadding: 18
                    rightPadding: 18
                    background: Rectangle { radius: Theme.radiusSmall; color: Theme.surfaceAlt; border.color: Theme.border; border.width: 1 }
                    contentItem: Label {
                        text: controller ? controller.translate("common.cancel") : ""
                        color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                    }
                    onClicked: resetDialog.close()
                }
                AppButton {
                    flat: true
                    Layout.preferredHeight: 40
                    leftPadding: 20
                    rightPadding: 20
                    background: Rectangle { radius: Theme.radiusSmall; color: Theme.red }
                    contentItem: Label {
                        text: controller ? controller.translate("settings.reset") : ""
                        color: "white"; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    onClicked: {
                        resetDialog.close()
                        controller.resetSettings()
                        refreshAll()
                    }
                }
            }
        }
    }
}
