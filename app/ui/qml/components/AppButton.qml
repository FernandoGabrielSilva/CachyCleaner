import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import ".."

// Button without the Material style's default insets/padding, so custom
// backgrounds and content fill the whole control and stay aligned.
Button {
    id: root
    flat: true
    hoverEnabled: true

    topInset: 0
    bottomInset: 0
    leftInset: 0
    rightInset: 0
    verticalPadding: 0
    padding: 0
    leftPadding: 16
    rightPadding: 16

    implicitHeight: 40
    Layout.alignment: Qt.AlignVCenter

    font.family: Theme.fontFamily
    font.pixelSize: 12
}
