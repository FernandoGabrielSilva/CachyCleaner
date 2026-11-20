import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import "components"

Item {
    id: page
    property var controller: null

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

            Card {
                Layout.fillWidth: true
                Layout.preferredHeight: 224
                cardColor: Theme.surfaceAlt
                contentMargins: 24
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 68
                        Layout.preferredHeight: 68
                        radius: 20
                        color: Theme.accent
                        Rectangle {
                            anchors.centerIn: parent
                            width: 30; height: 30; radius: 9; color: "white"; rotation: 45
                            Rectangle { anchors.centerIn: parent; width: 13; height: 13; radius: 4; color: Theme.accent }
                        }
                    }
                    Label {
                        text: "CachyCleaner"
                        color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 26; font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Label {
                        text: controller ? controller.translate("app.tagline") : ""
                        color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 12
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                contentMargins: 24
                contentSpacing: 16
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    Label {
                        text: controller ? controller.translate("about.description") : ""
                        color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 12
                        lineHeight: 1.4
                        wrapMode: Text.WordWrap; Layout.fillWidth: true
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.border }

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
                        Label { text: controller ? controller.translate("about.builtWith") : ""; color: Theme.textFaint; font.family: Theme.fontFamily; font.pixelSize: 10; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 10
                        AppButton {
                            flat: true
                            Layout.preferredHeight: 40
                            leftPadding: 18; rightPadding: 18
                            background: Rectangle { radius: Theme.radiusSmall; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14) }
                            contentItem: Label {
                                text: controller ? controller.translate("about.github") : ""
                                color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true
                            }
                            onClicked: controller.openReleases()
                        }
                        AppButton {
                            flat: true
                            Layout.preferredHeight: 40
                            leftPadding: 18; rightPadding: 18
                            background: Rectangle { radius: Theme.radiusSmall; color: Theme.surfaceAlt; border.color: Theme.border; border.width: 1 }
                            contentItem: Label {
                                text: controller ? controller.translate("about.checkUpdate") : ""
                                color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true
                            }
                            onClicked: controller.checkForUpdates()
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }
        }
    }
}
