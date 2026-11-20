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
        contentHeight: contentColumn.implicitHeight + Theme.pagePadding * 2
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

            // Hero: one statement, one action. Flat surface, no saturated fill.
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 196
                radius: Theme.radius
                color: Theme.surface
                border.width: 1
                border.color: Theme.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 32
                    spacing: 10
                    Label {
                        text: controller ? controller.translate("dashboard.title") : ""
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 24
                        font.bold: true
                    }
                    Label {
                        text: controller ? controller.translate("dashboard.subtitle") : ""
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        Layout.maximumWidth: 560
                        wrapMode: Text.WordWrap
                    }
                    Item { Layout.fillHeight: true }
                    AppButton {
                        objectName: "DashboardPage_AppButton_1"
                        id: heroCta
                        flat: true
                        Layout.preferredWidth: 184
                        Layout.preferredHeight: 42
                        padding: 0
                        leftPadding: 16
                        rightPadding: 16
                        pressColor: Theme.dark ? "#000000" : "#FFFFFF"
                        pressOpacity: 0.18
                        background: Rectangle {
                            radius: 21
                            color: Theme.dark ? "#F4F6F8" : "#14171C"
                        }
                        contentItem: RowLayout {
                            spacing: 8
                            Label {
                                text: "✦"
                                color: Theme.dark ? "#14171C" : "#FFFFFF"
                                font.pixelSize: 14
                            }
                            Label {
                                text: controller ? controller.translate("dashboard.cta") : ""
                                color: Theme.dark ? "#14171C" : "#FFFFFF"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
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

            // KPIs are type, not tiles: one card split by hairlines, label above value.
            Card {
                Layout.fillWidth: true
                Layout.preferredHeight: 116
                contentMargins: 20
                contentSpacing: 0
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 24
                    Repeater {
                        model: [
                            {value: summary.humanTotal || "0 B", label: "dashboard.total"},
                            {value: String(summary.totalItems || 0), label: "dashboard.items"},
                            {value: String(Object.keys(summary.perCategoryCount || {}).length), label: "dashboard.categories"}
                        ]
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 24
                            Rectangle {
                                Layout.preferredWidth: 1
                                Layout.fillHeight: true
                                color: Theme.border
                                visible: index > 0
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                Label {
                                    text: controller ? controller.translate(modelData.label) : ""
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Label {
                                    text: modelData.value
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 26
                                    font.bold: true
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            // Tip + recent
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 20
                rowSpacing: 20

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
                            Rectangle {
                                Layout.preferredWidth: 7
                                Layout.preferredHeight: 7
                                radius: 4
                                color: Theme.accent
                            }
                            Label {
                                text: controller ? controller.translate("dashboard.tip.title") : ""
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.bold: true
                                font.pixelSize: 14
                            }
                        }
                        Label {
                            text: controller ? controller.translate("dashboard.tip") : ""
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
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
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                        Label {
                            text: (summary.lastScan && summary.lastScan > 0)
                                ? new Date(summary.lastScan * 1000).toLocaleString()
                                : (controller ? controller.translate("dashboard.never") : "")
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.bold: true
                            font.pixelSize: 16
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                        Item { Layout.fillHeight: true }
                        Label {
                            text: controller ? controller.translate("dashboard.recent") : ""
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
