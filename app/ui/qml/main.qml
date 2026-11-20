import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import QtQuick.Controls.Material 6.0
import QtQuick.Window 6.0
import CachyCleaner 1.0
import "components"

ApplicationWindow {
    id: win
    width: 1180
    height: 760
    minimumWidth: 940
    minimumHeight: 620
    visible: true
    title: appController.appName

    color: Theme.bg
    Material.theme: Theme.dark ? Material.Dark : Material.Light
    Material.accent: Theme.accent

    property string currentPage: "dashboard"
    property var selection: ({count: 0, bytes: 0, human: "0 B"})
    property var settings: ({})
    property bool confirmClean: true

    Component.onCompleted: {
        settings = JSON.parse(appController.settingsJson)
        confirmClean = settings.confirm !== false
        if (settings.autoUpdate !== false) appController.checkForUpdates()
    }

    Connections {
        target: appController
        function onSettingsJsonChanged() {
            settings = JSON.parse(appController.settingsJson)
            confirmClean = settings.confirm !== false
        }
        function onToast(message, type) {
            toastBar.show(message, type)
        }
    }

    // ------------------------------------------------------------------ sidebar
    Rectangle {
        id: sidebar
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Theme.navWidth
        color: Theme.surface
        border.width: 1
        border.color: Theme.border

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 18
            anchors.bottomMargin: 16
            spacing: 6

            RowLayout {
                Layout.preferredHeight: 56
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 40

                    Layout.preferredHeight: 40
                    radius: 12
                    color: Theme.accent
                    Rectangle {
                        anchors.centerIn: parent
                        width: 18; height: 18
                        radius: 5
                        color: "white"
                        rotation: 45
                        Rectangle {
                            anchors.centerIn: parent
                            width: 8; height: 8
                            radius: 3
                            color: Theme.accent
                        }
                    }
                }
                ColumnLayout {
                    spacing: 1
                    Label { text: "Cachy"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 18; font.bold: true }
                    Label { text: "Cleaner"; color: Theme.accentLight; font.family: Theme.fontFamily; font.pixelSize: 18; font.bold: true }
                }
            }

            Item { Layout.preferredHeight: 14 }

            Repeater {
                model: [
                    {id: "dashboard", icon: "◫", key: "nav.dashboard"},
                    {id: "analyze",   icon: "⌕", key: "nav.analyze"},
                    {id: "settings",  icon: "⚙", key: "nav.settings"},
                    {id: "about",     icon: "ⓘ", key: "nav.about"}
                ]
                delegate: AppButton {
                    id: navBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    flat: true
                    padding: 0
                    leftPadding: 12
                    rightPadding: 12
                    background: Rectangle {
                        radius: Theme.radiusSmall
                        color: win.currentPage === modelData.id
                            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                            : (navBtn.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05) : "transparent")
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }
                    contentItem: RowLayout {
                        spacing: 12
                        Label {
                            text: modelData.icon
                            color: win.currentPage === modelData.id ? Theme.accentLight : Theme.textMuted
                            font.pixelSize: 18
                        }
                        Label {
                            text: appController.translate(modelData.key)
                            color: win.currentPage === modelData.id ? Theme.text : Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: win.currentPage === modelData.id
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                    onClicked: {
                        win.currentPage = modelData.id
                        stack.replace(pageFor(modelData.id))
                    }
                }
            }

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 74
                radius: Theme.radiusSmall
                color: Theme.surfaceAlt
                border.color: Theme.border
                border.width: 1
                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    anchors.topMargin: 12
                    anchors.bottomMargin: 12
                    spacing: 4
                    RowLayout {
                        spacing: 7
                        Rectangle { Layout.preferredWidth: 7; Layout.preferredHeight: 7; radius: 4; color: Theme.green }
                        Label {
                            text: appController.status
                            color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10
                            elide: Text.ElideRight; Layout.fillWidth: true
                        }
                    }
                    Label {
                        text: appController.statusDetail || appController.appVersion
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------ main area
    Rectangle {
        anchors.left: sidebar.right
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: Theme.bg

        Rectangle {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 80
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.pagePadding
                anchors.rightMargin: Theme.pagePadding
                spacing: 12

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Label {
                        id: pageTitle
                        text: appController.appName
                        font.family: Theme.fontFamily
                        font.pixelSize: 20
                        font.bold: true
                        color: Theme.text
                    }
                    Label {
                        id: pageSubtitle
                        text: appController.translate("app.tagline")
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.textMuted
                    }
                }

                AppButton {
                    id: updateBadge
                    visible: {
                        var u = JSON.parse(appController.updateInfoJson)
                        return u.available === true
                    }
                    flat: true
                    padding: 0
                    leftPadding: 14
                    rightPadding: 14
                    Layout.preferredHeight: 34
                    background: Rectangle { radius: 17; color: Qt.rgba(Theme.amber.r, Theme.amber.g, Theme.amber.b, 0.16) }
                    contentItem: RowLayout {
                        spacing: 6
                        Label { text: "●"; color: Theme.amber; font.pixelSize: 10 }
                        Label {
                            text: {
                                var u = JSON.parse(appController.updateInfoJson)
                                return appController.translateArg("settings.updateAvailable", u.latest)
                            }
                            color: Theme.amber
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                    onClicked: win.currentPage = "settings", stack.replace(pageFor("settings"))
                }

                AppButton {
                    id: scanButton
                    visible: win.currentPage === "dashboard" || win.currentPage === "analyze"
                    enabled: !appController.busy
                    Layout.preferredHeight: 40
                    padding: 0
                    leftPadding: 18
                    rightPadding: 18
                    background: Rectangle {
                        radius: Theme.radiusSmall
                        color: scanButton.enabled ? Theme.accent : Theme.textFaint
                    }
                    contentItem: RowLayout {
                        spacing: 8
                        Label { text: "✦"; color: "white"; font.pixelSize: 14 }
                        Label {
                            text: appController.translate("header.scan")
                            color: "white"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                    onClicked: {
                        win.currentPage = "analyze"
                        stack.replace(pageFor("analyze"))
                        appController.startScan()
                    }
                }

                AppButton {
                    id: cleanButton
                    visible: win.currentPage === "analyze" && selection.count > 0
                    enabled: !appController.busy
                    Layout.preferredHeight: 40
                    padding: 0
                    leftPadding: 18
                    rightPadding: 18
                    background: Rectangle {
                        radius: Theme.radiusSmall
                        color: cleanButton.enabled ? Theme.green : Theme.textFaint
                    }
                    contentItem: RowLayout {
                        spacing: 8
                        Label { text: "✓"; color: "white"; font.pixelSize: 14 }
                        Label {
                            text: appController.translate("common.clean") + " (" + selection.human + ")"
                            color: "white"; font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true
                        }
                    }
                    onClicked: confirmDialog.open()
                }

                AppButton {
                    id: cancelButton
                    visible: appController.busy
                    flat: true
                    Layout.preferredHeight: 40
                    padding: 0
                    leftPadding: 16
                    rightPadding: 16
                    background: Rectangle { radius: Theme.radiusSmall; color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.12) }
                    contentItem: Label {
                        text: appController.translate("header.cancel")
                        color: Theme.red; font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                    onClicked: {
                        if (appController.scanning) appController.cancelScan()
                        else appController.cancelClean()
                    }
                }
            }
        }

        Rectangle { id: headerLine; anchors.top: header.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: Theme.border }

        StackView {
            id: stack
            objectName: "stack"
            anchors.top: headerLine.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: progressBar.visible ? progressBar.top : parent.bottom
            initialItem: pageFor("dashboard")

            pushEnter: Transition { PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 180 } }
            popExit: Transition { PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 120 } }
        }

        Rectangle {
            id: progressBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: appController.busy ? 3 : 0
            color: Theme.border
            visible: appController.busy
            Rectangle {
                width: parent.width * appController.progress / 100
                height: parent.height
                color: Theme.accent
                Behavior on width { NumberAnimation { duration: 200 } }
            }
        }
    }

    // -------------------------------------------------------------- confirmation
    Dialog {
        id: confirmDialog
        anchors.centerIn: parent
        width: 470
        modal: true
        padding: 0
        closePolicy: Popup.CloseOnEscape
        background: Rectangle { color: Theme.surface; radius: Theme.radius; border.color: Theme.border; border.width: 1 }

        header: Label {
            text: appController.translate("analyze.confirmTitle")
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 16
            font.bold: true
            leftPadding: 26
            rightPadding: 26
            topPadding: 24
            bottomPadding: 0
        }

        contentItem: ColumnLayout {
            spacing: 12
            Label {
                id: confirmBody
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 12
                lineHeight: 1.35
            }
            Label {
                id: confirmNote
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Theme.amber
                font.family: Theme.fontFamily
                font.pixelSize: 11
                lineHeight: 1.35
            }
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
                        text: appController.translate("common.cancel")
                        color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true
                    }
                    onClicked: confirmDialog.close()
                }
                AppButton {
                    flat: true
                    Layout.preferredHeight: 40
                    leftPadding: 20
                    rightPadding: 20
                    background: Rectangle { radius: Theme.radiusSmall; color: Theme.green }
                    contentItem: Label {
                        text: appController.translate("common.clean")
                        color: "white"; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true
                        horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true
                    }
                    onClicked: {
                        confirmDialog.close()
                        appController.cleanSelected(settings.useTrash ? "false" : "true", true)
                    }
                }
            }
        }

        onOpened: {
            confirmBody.text = appController.translateArgs(
                "analyze.confirmBody", String(selection.count), selection.human
            )
            confirmNote.text = settings.useTrash
                ? appController.translate("analyze.confirmTrash")
                : appController.translate("analyze.confirmPermanent")
        }
    }

    // -------------------------------------------------------------------- toast
    Rectangle {
        id: toastBar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        width: Math.min(460, parent.width - 80)
        height: 52
        radius: Theme.radiusSmall
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        opacity: 0
        visible: opacity > 0
        z: 100

        property string kind: "info"
        function show(message, type) {
            toastLabel.text = message
            kind = type
            toastDot.color = type === "success" ? Theme.green : type === "error" ? Theme.red : Theme.accent
            opacity = 1
            toastTimer.restart()
        }
        Timer { id: toastTimer; interval: 3200; onTriggered: toastBar.opacity = 0 }
        Behavior on opacity { NumberAnimation { duration: 220 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 10
            Rectangle { id: toastDot; Layout.preferredWidth: 8; Layout.preferredHeight: 8; radius: 4; color: Theme.accent }
            Label { id: toastLabel; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
        }
    }

    // ------------------------------------------------------------------- helpers
    function pageFor(id) {
        switch (id) {
            case "analyze":  return analyzePage.createObject(stack)
            case "settings": return settingsPage.createObject(stack)
            case "about":    return aboutPage.createObject(stack)
            default:         return dashboardPage.createObject(stack)
        }
    }

    Component { id: dashboardPage; DashboardPage { controller: appController } }
    Component { id: analyzePage; AnalyzePage { controller: appController } }
    Component { id: settingsPage; SettingsPage { controller: appController } }
    Component { id: aboutPage; AboutPage { controller: appController } }

    Connections {
        target: appController
        function onSelectionChanged() { selection = JSON.parse(appController.selectionJson) }
    }
}
