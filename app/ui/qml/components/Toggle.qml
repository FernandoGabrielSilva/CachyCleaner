import QtQuick 6.0
import QtQuick.Controls 6.0
import ".."

Item {
    id: root
    width: 44
    height: 26
    property bool checked: false
    signal toggled(bool value)

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.accent : (Theme.dark ? "#333A4D" : "#D9DDE8")
        Behavior on color { ColorAnimation { duration: 180 } }
    }

    Rectangle {
        id: knob
        width: 20
        height: 20
        radius: 10
        x: root.checked ? 20 : 3
        anchors.verticalCenter: parent.verticalCenter
        color: "white"
        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: root.scale = 0.94
        onReleased: root.scale = 1
        onCanceled: root.scale = 1
        onClicked: { root.checked = !root.checked; root.toggled(root.checked) }
    }
    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
}
