import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import ".."

Item {
    id: root
    property var model: []
    property string current: ""
    signal selected(string value)
    implicitWidth: 270
    implicitHeight: 40

    Rectangle {
        anchors.fill: parent
        radius: 11
        color: Theme.surfaceAlt
        border.color: Theme.border
        border.width: 1
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 3
        spacing: 3
        Repeater {
            model: root.model
            delegate: Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                flat: true
                padding: 0
                background: Rectangle {
                    color: root.current === modelData.value ? Theme.accent : "transparent"
                    radius: 8
                    Behavior on color { ColorAnimation { duration: 140 } }
                }
                contentItem: Label {
                    text: modelData.label
                    color: root.current === modelData.value ? "white" : Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: root.current === modelData.value
                    horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    root.current = modelData.value
                    root.selected(modelData.value)
                }
            }
        }
    }
}
