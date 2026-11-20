import QtQuick 6.0
import QtQuick.Controls 6.0
import ".."

Rectangle {
    id: root
    default property alias content: contentItem.data
    property color cardColor: Theme.surface
    property color borderColor: Theme.border
    property int cardRadius: Theme.radius
    property real elevation: 0

    radius: cardRadius
    color: cardColor
    border.width: 1
    border.color: borderColor

    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on borderColor { ColorAnimation { duration: 200 } }

    Item { id: contentItem; anchors.fill: parent }
}
