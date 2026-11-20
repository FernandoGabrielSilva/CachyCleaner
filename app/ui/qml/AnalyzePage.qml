import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import "components"

Item {
    id: page
    property var controller: null
    property var items: []
    property var selection: ({count: 0, human: "0 B"})

    Component.onCompleted: { refreshItems(); refreshSelection() }
    Connections {
        target: controller
        function onScanResultsChanged() { refreshItems() }
        function onSelectionChanged() { refreshSelection() }
    }
    function refreshItems() {
        if (!controller) return
        try { items = JSON.parse(controller.resultsJson) } catch(e) { items = [] }
    }
    function refreshSelection() {
        if (!controller) return
        try { selection = JSON.parse(controller.selectionJson) } catch(e) {}
    }
    function humanSize(b) {
        if (b < 1024) return b + " B"
        if (b < 1048576) return (b/1024).toFixed(1) + " KB"
        if (b < 1073741824) return (b/1048576).toFixed(1) + " MB"
        return (b/1073741824).toFixed(2) + " GB"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.pagePadding
        anchors.rightMargin: Theme.pagePadding
        anchors.topMargin: Theme.pagePadding
        anchors.bottomMargin: Theme.pagePadding
        spacing: 14

        // Search + toolbar
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            TextField {
                id: searchField
                Layout.preferredWidth: 340
                Layout.preferredHeight: 40
                leftPadding: 14
                rightPadding: 14
                placeholderText: controller ? controller.translate("analyze.search") : ""
                color: Theme.text
                placeholderTextColor: Theme.textFaint
                font.family: Theme.fontFamily
                font.pixelSize: 12
                selectByMouse: true
                background: Rectangle {
                    radius: Theme.radiusSmall
                    color: Theme.surface
                    border.color: searchField.activeFocus ? Theme.accent : Theme.border
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                }
                onTextChanged: controller.setSearch(text)
            }

            Item { Layout.fillWidth: true }

            AppButton {
                flat: true
                Layout.preferredHeight: 40
                leftPadding: 16
                rightPadding: 16
                background: Rectangle { radius: Theme.radiusSmall; color: Theme.surfaceAlt; border.color: Theme.border; border.width: 1 }
                contentItem: Label {
                    text: controller ? controller.translate("analyze.selectAll") : ""
                    color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                }
                onClicked: controller.selectAll()
            }
            AppButton {
                flat: true
                Layout.preferredHeight: 40
                leftPadding: 16
                rightPadding: 16
                background: Rectangle { radius: Theme.radiusSmall; color: Theme.surfaceAlt; border.color: Theme.border; border.width: 1 }
                contentItem: Label {
                    text: controller ? controller.translate("analyze.clearAll") : ""
                    color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                }
                onClicked: controller.clearSelection()
            }
        }

        // Selection summary strip
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            radius: Theme.radiusSmall
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.28)
            border.width: 1
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 8
                Label {
                    text: selection.count + " " + (controller ? controller.translate("analyze.selected") : "")
                    color: Theme.accentLight
                    font.family: Theme.fontFamily; font.bold: true; font.pixelSize: 12
                }
                Item { Layout.fillWidth: true }
                Label {
                    text: selection.human
                    color: Theme.accentLight
                    font.family: Theme.monoFamily; font.bold: true; font.pixelSize: 13
                }
            }
        }

        // Results
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentMargins: 0
            contentSpacing: 0
            clip: true

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    color: Theme.surfaceAlt
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 12
                        Item { Layout.preferredWidth: 64 }
                        Label {
                            text: controller ? controller.translate("analyze.results") : ""
                            color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10
                            Layout.fillWidth: true
                        }
                        Label {
                            text: controller ? controller.translate("analyze.size") : ""
                            color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10
                            Layout.preferredWidth: 92; horizontalAlignment: Text.AlignRight
                        }
                        Label {
                            text: controller ? controller.translate("analyze.modified") : ""
                            color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10
                            Layout.preferredWidth: 120; horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: items.length
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Rectangle {
                        id: row
                        width: listView.width
                        height: 58
                        color: "transparent"

                        property var item: items[index]
                        property bool hovered: false

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: Theme.border
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: Theme.accent
                            opacity: row.hovered ? 0.05 : 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: row.hovered = true
                            onExited: row.hovered = false
                            onClicked: {
                                if (!row.item) return
                                controller.setItemSelectedByPath(row.item.path, !(row.item.selected !== false))
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20
                            spacing: 12

                            CheckBox {
                                id: check
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                checked: row.item ? row.item.selected !== false : false
                                indicator.width: 18
                                indicator.height: 18
                                onToggled: {
                                    if (row.item) controller.setItemSelectedByPath(row.item.path, check.checked)
                                }
                                Connections {
                                    target: controller
                                    function onScanResultsChanged() {
                                        check.checked = row.item ? row.item.selected !== false : false
                                    }
                                }
                            }
                            Rectangle {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                radius: 9
                                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
                                Label {
                                    anchors.centerIn: parent
                                    text: row.item && row.item.isDir ? "▣" : "▤"
                                    color: Theme.accent
                                    font.pixelSize: 14
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                Label {
                                    text: row.item ? row.item.name : ""
                                    color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 12
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: row.item ? row.item.path : ""
                                    color: Theme.textFaint; font.family: Theme.fontFamily; font.pixelSize: 9
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }
                            }
                            Label {
                                text: row.item ? humanSize(row.item.size) : ""
                                color: Theme.text; font.family: Theme.monoFamily; font.pixelSize: 10
                                Layout.preferredWidth: 92; horizontalAlignment: Text.AlignRight
                            }
                            Label {
                                text: row.item && row.item.modified ? new Date(row.item.modified * 1000).toLocaleDateString() : "—"
                                color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10
                                Layout.preferredWidth: 120; horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        width: parent.width - 80
                        visible: items.length === 0 && !controller.busy
                        text: controller ? controller.translate("analyze.emptyHint") : ""
                        color: Theme.textFaint; font.family: Theme.fontFamily; font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                    BusyIndicator {
                        anchors.centerIn: parent
                        running: controller.busy && items.length === 0
                        visible: running
                        width: 44; height: 44
                    }
                }
            }
        }
    }
}
