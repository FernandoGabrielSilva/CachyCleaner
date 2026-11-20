import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import ".."

Item {
    id: root
    property var model: []
    property string current: ""
    signal selected(string value)
    implicitWidth: 250
    implicitHeight: 36

    RowLayout {
        anchors.fill: parent
        spacing: 0
        Repeater {
            model: root.model
            delegate: Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                flat: true
                background: Rectangle {
                    color: root.current === modelData.value ? Theme.accent : "transparent"
                    radius: 9
                }
                contentItem: Label {
                    text: modelData.label
                    color: root.current === modelData.value ? "white" : Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
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
