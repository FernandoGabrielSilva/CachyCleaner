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
        contentHeight: contentColumn.height + 48
        clip: true
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 36
            spacing: 22

            // Hero
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 210
                radius: Theme.radius
                color: Theme.accent
                layer.enabled: false

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    width: 260; height: 260
                    radius: 130
                    color: "white"
                    opacity: 0.06
                    x: 60; y: -80
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: 180; height: 180
                    radius: 90
                    color: "white"
                    opacity: 0.05
                    x: -40; y: 60
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 32
                    spacing: 8
                    Label {
                        text: controller ? controller.translate("dashboard.title") : ""
                        color: "white"; font.family: Theme.fontFamily; font.bold: true; font.pixelSize: 28
                    }
                    Label {
                        text: controller ? controller.translate("dashboard.subtitle") : ""
                        color: "white"; opacity: 0.82; font.family: Theme.fontFamily; font.pixelSize: 12
                        Layout.maximumWidth: 460
                        wrapMode: Text.WordWrap
                    }
                    Item { Layout.fillHeight: true }
                    Button {
                        flat: true
                        Layout.preferredWidth: 168
                        height: 38
                        background: Rectangle { radius: 19; color: "white" }
                        contentItem: RowLayout {
                            spacing: 8
                            Label { text: "✦"; color: Theme.accent; font.pixelSize: 13; Layout.leftMargin: 12 }
                            Label {
                                text: controller ? controller.translate("dashboard.cta") : ""
                                color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true
                            }
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
                rowSpacing: 18
                columnSpacing: 18

                Repeater {
                    model: [
                        {value: summary.humanTotal || "0 B", label: "dashboard.total", icon: "◈", color: Theme.accent},
                        {value: String(summary.totalItems || 0), label: "dashboard.items", icon: "▤", color: Theme.blue},
                        {value: String(Object.keys(summary.perCategoryCount || {}).length), label: "dashboard.categories", icon: "◫", color: Theme.green}
                    ]
                    delegate: Card {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 128
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 6
                            RowLayout {
                                Layout.fillWidth: true
                                Rectangle {
                                    Layout.preferredWidth: 34

                                    Layout.preferredHeight: 34
                                    radius: 10
                                    color: modelData.color
                                    opacity: 0.14
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
                                font.pixelSize: 25
                                font.bold: true
                                Layout.topMargin: 4
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
                columnSpacing: 18
                rowSpacing: 18

                Card {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 176
                    color: Theme.surfaceAlt
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 22
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
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }

                Card {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 176
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 22
                        spacing: 10
                        Label {
                            text: controller ? controller.translate("dashboard.lastScan") : ""
                            color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 11
                        }
                        Label {
                            text: (summary.lastScan && summary.lastScan > 0)
                                ? new Date(summary.lastScan * 1000).toLocaleString()
                                : (controller ? controller.translate("dashboard.never") : "")
                            color: Theme.text; font.family: Theme.fontFamily; font.bold: true; font.pixelSize: 15
                            wrapMode: Text.WordWrap
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
