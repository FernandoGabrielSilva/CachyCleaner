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
    implicitHeight: hint ? 62 : 40

    RowLayout {
        anchors.fill: parent
        spacing: 16
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Label { text: root.title; color: Theme.text; font.family: Theme.fontFamily; font.bold: true; font.pixelSize: 12 }
            Label { text: root.hint; visible: root.hint.length > 0; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        }
        Toggle {
            checked: root.checked
            onToggled: root.toggled(value)
        }
    }
}
