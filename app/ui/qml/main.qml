import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import QtQuick.Controls.Material 6.0
import QtQuick.Window 6.0
import CachyCleaner 1.0

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
            anchors.margins: 20
            spacing: 8

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
                    spacing: 0
                    Label { text: "Cachy"; color: Theme.text; font.pixelSize: 17; font.bold: true }
                    Label { text: "Cleaner"; color: Theme.accentLight; font.pixelSize: 17; font.bold: true }
                }
            }

            Item { Layout.preferredHeight: 16 }

            Repeater {
                model: [
                    {id: "dashboard", icon: "◫", key: "nav.dashboard"},
                    {id: "analyze",   icon: "⌕", key: "nav.analyze"},
                    {id: "settings",  icon: "⚙", key: "nav.settings"},
                    {id: "about",     icon: "ⓘ", key: "nav.about"}
                ]
                delegate: Button {
                    id: navBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    flat: true
                    background: Rectangle {
                        radius: Theme.radiusSmall
                        color: win.currentPage === modelData.id ? Theme.accent : "transparent"
                        opacity: win.currentPage === modelData.id ? 0.14 : 1
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }
                    contentItem: RowLayout {
                        spacing: 14
                        Label {
                            text: modelData.icon
                            color: win.currentPage === modelData.id ? Theme.accentLight : Theme.textMuted
                            font.pixelSize: 19
                            Layout.leftMargin: 10
                        }
                        Label {
                            text: appController.translate(modelData.key)
                            color: win.currentPage === modelData.id ? Theme.text : Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            Layout.fillWidth: true
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
                Layout.preferredHeight: 72
                radius: Theme.radiusSmall
                color: Theme.surfaceAlt
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 2
                    RowLayout {
                        spacing: 6
                        Rectangle { width: 7; height: 7; radius: 4; color: Theme.green }
                        Label { text: appController.status; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10 }
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
            height: 76
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 36
                anchors.rightMargin: 36
                spacing: 14

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Label {
                        id: pageTitle
                        text: appController.appName
                        font.family: Theme.fontFamily
font.bold: true
                        color: Theme.text
                    }
                    Label {
                        id: pageSubtitle
                        text: appController.translate("app.tagline")
                        font.family: Theme.fontFamily
                        color: Theme.textMuted
                    }
                }

                Button {
                    id: updateBadge
                    visible: {
                        var u = JSON.parse(appController.updateInfoJson)
                        return u.available === true
                    }
                    flat: true
                    background: Rectangle { radius: 20; color: Theme.amber; opacity: 0.16 }
                    contentItem: RowLayout {
                        spacing: 6
                        Label { text: "●"; color: Theme.amber; font.pixelSize: 10 }
                        Label {
                            text: {
                                var u = JSON.parse(appController.updateInfoJson)
                                return appController.translate("settings.updateAvailable", u.latest)
                            }
                            color: Theme.amber
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                    onClicked: win.currentPage = "settings", stack.replace(pageFor("settings"))
                }

                Button {
                    id: scanButton
                    visible: win.currentPage === "dashboard" || win.currentPage === "analyze"
                    enabled: !appController.busy
                    height: 40
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

                Button {
                    id: cleanButton
                    visible: win.currentPage === "analyze" && selection.count > 0
                    enabled: !appController.busy
                    height: 40
                    background: Rectangle {
                        radius: Theme.radiusSmall
                        color: cleanButton.enabled ? Theme.green : Theme.textFaint
                    }
                    contentItem: RowLayout {
                        spacing: 8
                        Label { text: "✓"; color: "white"; font.pixelSize: 14 }
                        Label {
                            text: appController.translate("header.clean") + " (" + selection.human + ")"
                            color: "white"; font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true
                        }
                    }
                    onClicked: confirmDialog.open()
                }

                Button {
                    id: cancelButton
                    visible: appController.busy
                    flat: true
                    height: 40
                    background: Rectangle { radius: Theme.radiusSmall; color: Theme.red; opacity: 0.12 }
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
        width: 440
        modal: true
        title: appController.translate("analyze.confirmTitle")
        standardButtons: Dialog.Cancel | Dialog.Ok
        background: Rectangle { color: Theme.surface; radius: Theme.radius; border.color: Theme.border; border.width: 1 }
        Label {
            id: confirmBody
            anchors.fill: parent
            anchors.margins: 20
            wrapMode: Text.WordWrap
            color: Theme.textMuted
            font.family: Theme.fontFamily
            text: ""
        }
        Label {
            id: confirmNote
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 20
            wrapMode: Text.WordWrap
            color: Theme.amber
            font.family: Theme.fontFamily
            text: ""
        }
        onOpened: {
            confirmBody.text = appController.translate(
                "analyze.confirmBody", selection.count, selection.human
            )
            confirmNote.text = settings.useTrash
                ? appController.translate("analyze.confirmTrash")
                : appController.translate("analyze.confirmPermanent")
        }
        onAccepted: appController.cleanSelected(settings.useTrash ? "false" : "true", true)
    }

    // -------------------------------------------------------------------- toast
    Rectangle {
        id: toastBar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        width: Math.min(420, parent.width - 80)
        height: 48
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
            anchors.margins: 14
            spacing: 10
            Rectangle { id: toastDot; width: 8; height: 8; radius: 4; color: Theme.accent }
            Label { id: toastLabel; color: Theme.text; font.family: Theme.fontFamily; Layout.fillWidth: true; elide: Text.ElideRight }
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
