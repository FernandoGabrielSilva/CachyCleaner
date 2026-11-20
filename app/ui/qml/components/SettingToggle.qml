import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import ".."

Item {
    id: root
    property string title: ""
    property string hint: ""
    property bool checked: false
    signal toggled(bool value)
    implicitHeight: hint ? 66 : 44

    RowLayout {
        anchors.fill: parent
        spacing: 20
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 3
            Label {
                text: root.title
                color: Theme.text; font.family: Theme.fontFamily; font.bold: true; font.pixelSize: 12
                Layout.fillWidth: true
            }
            Label {
                text: root.hint
                visible: root.hint.length > 0
                color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 11
                wrapMode: Text.WordWrap; Layout.fillWidth: true
            }
        }
        Toggle {
            Layout.alignment: Qt.AlignVCenter
            checked: root.checked
            onToggled: root.toggled(value)
        }
    }
}
