import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import ".."

// Button without the Material style's default insets/padding, so custom
// backgrounds and content fill the whole control and stay aligned.
Button {
    objectName: "AppButton_Button_1"
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

    // Override on light-filled buttons (e.g. the inverted primary CTA) so the
    // wash darkens instead of bleaching the label.
    property color pressColor: Theme.dark ? "#FFFFFF" : "#000000"
    property real pressOpacity: 0.32

    // Press feedback is two-fold: a short wash and a spring back to full size.
    // The flash keeps the click visible even when the handler changes the page.
    Rectangle {
        anchors.fill: parent
        radius: Math.min(Theme.radiusSmall, height / 2)
        color: root.pressColor
        opacity: root.down ? root.pressOpacity : 0
        visible: root.enabled && (root.down || tapFlash.running)
        z: 2
        Behavior on opacity { NumberAnimation { duration: 60 } }
    }

    SequentialAnimation {
        id: tapFlash
        PropertyAnimation {
            target: root
            property: "scale"
            from: 0.96
            to: 1
            duration: 190
            easing.type: Easing.OutBack
        }
    }

    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

    onPressed: root.scale = 0.96
    onReleased: {
        root.scale = 1
        tapFlash.restart()
    }
    onCanceled: root.scale = 1
}
