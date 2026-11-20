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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 36
        spacing: 16

        // Category chips + toolbar
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            TextField {
                id: searchField
                Layout.preferredWidth: 320
                height: 38
                placeholderText: controller ? controller.translate("analyze.search") : ""
                color: Theme.text
                placeholderTextColor: Theme.textFaint
                background: Rectangle { radius: Theme.radiusSmall; color: Theme.surface; border.color: Theme.border; border.width: 1 }
                onTextChanged: controller.setSearch(text)
            }

            Item { Layout.fillWidth: true }

            Button {
                flat: true
                background: Rectangle { radius: Theme.radiusSmall; color: Theme.surfaceAlt }
                contentItem: Label { text: controller ? controller.translate("analyze.selectAll") : ""; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11 }
                onClicked: controller.selectAll()
            }
            Button {
                flat: true
                background: Rectangle { radius: Theme.radiusSmall; color: Theme.surfaceAlt }
                contentItem: Label { text: controller ? controller.translate("analyze.clearAll") : ""; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11 }
                onClicked: controller.clearSelection()
            }
        }

        // Selection summary strip
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: Theme.radiusSmall
            color: Theme.accent
            opacity: 0.10
            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                Label {
                    text: selection.count + " " + (controller ? controller.translate("analyze.selected") : "")
                    color: Theme.accent; font.family: Theme.fontFamily; font.bold: true; font.pixelSize: 12
                }
                Item { Layout.fillWidth: true }
                Label { text: selection.human; color: Theme.accent; font.family: Theme.fontFamily; font.bold: true; font.pixelSize: 14 }
            }
        }

        // Results list
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header row
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    color: Theme.surfaceAlt
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 12
                        Item { width: 20 }
                        Label { text: controller ? controller.translate("analyze.results") : ""; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10; Layout.fillWidth: true }
                        Label { text: controller ? controller.translate("analyze.size") : ""; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10; Layout.preferredWidth: 90; horizontalAlignment: Text.AlignRight }
                        Label { text: controller ? controller.translate("analyze.modified") : ""; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10; Layout.preferredWidth: 130; horizontalAlignment: Text.AlignRight }
                    }
                }

                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: items.length
                    clip: true
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Rectangle {
                        id: row
                        width: listView.width
                        height: 56
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.border
                        opacity: 1

                        property var item: items[index]

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20
                            spacing: 12

                            CheckBox {
                                id: check
                                checked: item ? item.selected !== false : false
                                width: 20
                                indicator.width: 18; indicator.height: 18
                                onToggled: {
                                    if (item) controller.setItemItemSelectedByPath(item.path, check.checked)
                                }
                                Connections {
                                    target: controller
                                    function onScanResultsChanged() {
                                        check.checked = item ? item.selected !== false : false
                                    }
                                }
                            }
                            Rectangle {
                                Layout.preferredWidth: 32

                                Layout.preferredHeight: 32
                                radius: 9
                                color: Theme.surfaceAlt
                                Label {
                                    anchors.centerIn: parent
                                    text: item && item.isDir ? "▣" : "▤"
                                    color: Theme.accent
                                    font.pixelSize: 14
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Label {
                                    text: item ? item.name : ""
                                    color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: item ? item.path : ""
                                    color: Theme.textFaint; font.family: Theme.fontFamily; font.pixelSize: 9
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }
                            }
                            Label {
                                text: {
                                    if (!item) return ""
                                    var b = item.size
                                    if (b < 1024) return b + " B"
                                    if (b < 1048576) return (b/1024).toFixed(1) + " KB"
                                    if (b < 1073741824) return (b/1048576).toFixed(1) + " MB"
                                    return (b/1073741824).toFixed(2) + " GB"
                                }
                                color: Theme.text; font.family: Theme.monoFamily; font.pixelSize: 10
                                Layout.preferredWidth: 90; horizontalAlignment: Text.AlignRight
                            }
                            Label {
                                text: item && item.modified ? new Date(item.modified * 1000).toLocaleDateString() : "—"
                                color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10
                                Layout.preferredWidth: 130; horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        visible: items.length === 0 && !controller.busy
                        text: controller ? controller.translate("analyze.emptyHint") : ""
                        color: Theme.textFaint; font.family: Theme.fontFamily
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
