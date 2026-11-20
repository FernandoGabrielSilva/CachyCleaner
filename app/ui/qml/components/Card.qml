import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import ".."

Rectangle {
    id: root
    default property alias content: contentColumn.data
    property color cardColor: Theme.surface
    property color borderColor: Theme.border
    property int cardRadius: Theme.radius
    property int contentMargins: 24
    property alias contentSpacing: contentColumn.spacing
    property real elevation: 0

    radius: cardRadius
    color: cardColor
    border.width: 1
    border.color: borderColor
    implicitWidth: contentColumn.implicitWidth + contentMargins * 2
    implicitHeight: contentColumn.implicitHeight + contentMargins * 2

    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on borderColor { ColorAnimation { duration: 200 } }

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: root.contentMargins
        spacing: 14
    }
}
