import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import "components"

Item {
    id: page
    property var controller: null

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

            Card {
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                color: Theme.surfaceAlt

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10
                    Rectangle {
                        Layout.preferredWidth: 64

                        Layout.preferredHeight: 64
                        radius: 18
                        color: Theme.accent
                        Rectangle {
                            anchors.centerIn: parent
                            width: 28; height: 28; radius: 8; color: "white"; rotation: 45
                            Rectangle { anchors.centerIn: parent; width: 12; height: 12; radius: 4; color: Theme.accent }
                        }
                    }
                    Label { text: "CachyCleaner"; color: Theme.text; font.pixelSize: 26; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                    Label {
                        text: controller ? controller.translate("app.tagline") : ""
                        color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 12
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 14
                    Label { text: controller ? controller.translate("about.description") : ""; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 11; wrapMode: Text.WordWrap }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: controller ? controller.translate("about.version") : ""; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 11 }
                        Item { Layout.fillWidth: true }
                        Label { text: controller ? controller.appVersion : ""; color: Theme.text; font.family: Theme.monoFamily; font.pixelSize: 11 }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: controller ? controller.translate("about.license") : ""; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 11 }
                        Item { Layout.fillWidth: true }
                        Label { text: "MIT"; color: Theme.text; font.family: Theme.monoFamily; font.pixelSize: 11 }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: controller ? controller.translate("about.builtWith") : ""; color: Theme.textFaint; font.family: Theme.fontFamily; font.pixelSize: 10 }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 8
                        spacing: 10
                        Button {
                            flat: true; height: 38
                            background: Rectangle { radius: Theme.radiusSmall; color: Theme.accent; opacity: 0.14 }
                            contentItem: Label { text: controller ? controller.translate("about.github") : ""; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 11 }
                            onClicked: controller.openReleases()
                        }
                        Button {
                            flat: true; height: 38
                            background: Rectangle { radius: Theme.radiusSmall; color: Theme.surfaceAlt }
                            contentItem: Label { text: controller ? controller.translate("about.checkUpdate") : ""; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11 }
                            onClicked: controller.checkForUpdates()
                        }
                    }
                }
            }
        }
    }
}
