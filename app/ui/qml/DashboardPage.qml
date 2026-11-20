import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import QtQml.Models 6.0
import "components"

Item {
    id: page
    property var controller: null
    property var summary: ({totalBytes: 0, totalItems: 0, perCategory: {}, humanTotal: "0 B", lastScan: 0})

    Component.onCompleted: refresh()
    Connections { target: controller; function onSummaryChanged() { refresh() } }
    function refresh() {
        if (!controller) return
        try { summary = JSON.parse(controller.summaryJson) } catch(e) {}
    }

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
            spacing: 20

            // Hero
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 204
                radius: Theme.radius
                color: Theme.accent
                clip: true

                Rectangle {
                    width: 280; height: 280
                    radius: 140
                    color: "white"
                    opacity: 0.07
                    x: parent.width - 190; y: -110
                }
                Rectangle {
                    width: 190; height: 190
                    radius: 95
                    color: "white"
                    opacity: 0.05
                    x: parent.width - 340; y: 130
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 32
                    spacing: 10
                    Label {
                        text: controller ? controller.translate("dashboard.title") : ""
                        color: "white"; font.family: Theme.fontFamily; font.bold: true; font.pixelSize: 28
                    }
                    Label {
                        text: controller ? controller.translate("dashboard.subtitle") : ""
                        color: "white"; opacity: 0.85; font.family: Theme.fontFamily; font.pixelSize: 13
                        Layout.maximumWidth: 520
                        wrapMode: Text.WordWrap
                    }
                    Item { Layout.fillHeight: true }
                    AppButton {
                        flat: true
                        Layout.preferredWidth: 184
                        Layout.preferredHeight: 42
                        padding: 0
                        background: Rectangle { radius: 21; color: "white" }
                        contentItem: RowLayout {
                            spacing: 8
                            Label { text: "✦"; color: Theme.accent; font.pixelSize: 14; Layout.leftMargin: 18 }
                            Label {
                                text: controller ? controller.translate("dashboard.cta") : ""
                                color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                        }
                        onClicked: {
                            stack.replace(pageFor("analyze"))
                            win.currentPage = "analyze"
                            controller.startScan()
                        }
                    }
                }
            }

            // Stats
            GridLayout {
                Layout.fillWidth: true
                columns: 3
                rowSpacing: 16
                columnSpacing: 16

                Repeater {
                    model: [
                        {value: summary.humanTotal || "0 B", label: "dashboard.total", icon: "◈", color: Theme.accent},
                        {value: String(summary.totalItems || 0), label: "dashboard.items", icon: "▤", color: Theme.blue},
                        {value: String(Object.keys(summary.perCategoryCount || {}).length), label: "dashboard.categories", icon: "◫", color: Theme.green}
                    ]
                    delegate: Card {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 136
                        contentMargins: 20
                        contentSpacing: 6
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            RowLayout {
                                Layout.fillWidth: true
                                Rectangle {
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 36
                                    radius: 11
                                    color: Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.16)
                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData.icon
                                        color: modelData.color
                                        font.pixelSize: 16
                                    }
                                }
                                Item { Layout.fillWidth: true }
                            }
                            Label {
                                text: modelData.value
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 26
                                font.bold: true
                                Layout.topMargin: 2
                            }
                            Label {
                                text: controller ? controller.translate(modelData.label) : ""
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }

            // Tip + recent
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 16
                rowSpacing: 16

                Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 168
                    cardColor: Theme.surfaceAlt
                    contentMargins: 22
                    contentSpacing: 10
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        RowLayout {
                            spacing: 8
                            Label { text: "🛡"; font.pixelSize: 16 }
                            Label {
                                text: controller ? controller.translate("dashboard.tip.title") : ""
                                color: Theme.text; font.family: Theme.fontFamily; font.bold: true; font.pixelSize: 13
                            }
                        }
                        Label {
                            text: controller ? controller.translate("dashboard.tip") : ""
                            color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 11
                            lineHeight: 1.35
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }

                Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 168
                    contentMargins: 22
                    contentSpacing: 8
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Label {
                            text: controller ? controller.translate("dashboard.lastScan") : ""
                            color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 11
                        }
                        Label {
                            text: (summary.lastScan && summary.lastScan > 0)
                                ? new Date(summary.lastScan * 1000).toLocaleString()
                                : (controller ? controller.translate("dashboard.never") : "")
                            color: Theme.text; font.family: Theme.fontFamily; font.bold: true; font.pixelSize: 16
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                        Item { Layout.fillHeight: true }
                        Label {
                            text: controller ? controller.translate("dashboard.recent") : ""
                            color: Theme.textFaint; font.family: Theme.fontFamily; font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }
}
