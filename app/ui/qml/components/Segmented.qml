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
                objectName: "Segmented_Button_1"
                id: segment
                Layout.fillWidth: true
                Layout.fillHeight: true
                flat: true
                hoverEnabled: true
                padding: 0
                background: Rectangle {
                    color: root.current === modelData.value
                        ? (Theme.dark ? "#E8ECF2" : "#1D1F24")
                        : (segment.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05) : "transparent")
                    radius: 8
                    Behavior on color { ColorAnimation { duration: 140 } }
                }
                contentItem: Label {
                    text: modelData.label
                    color: root.current === modelData.value
                        ? (Theme.dark ? "#101317" : "#FFFFFF")
                        : Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: root.current === modelData.value
                    horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: Theme.dark ? "#FFFFFF" : "#000000"
                    opacity: segment.down ? 0.24 : 0
                    visible: segment.down
                    z: 2
                }
                Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                onPressed: segment.scale = 0.96
                onReleased: segment.scale = 1
                onCanceled: segment.scale = 1
                onClicked: {
                    root.current = modelData.value
                    root.selected(modelData.value)
                }
            }
        }
    }
}
