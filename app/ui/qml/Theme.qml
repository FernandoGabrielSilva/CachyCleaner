pragma Singleton
import QtQuick 6.0
import QtQuick.Controls 6.0

QtObject {
    readonly property bool dark: appController ? appController.effectiveTheme === "dark" : true

    readonly property color accent: "#7C5CFF"
    readonly property color accentLight: "#A78BFA"
    readonly property color accentDark: "#5B3FD6"
    readonly property color green: "#22C55E"
    readonly property color red: "#EF4444"
    readonly property color amber: "#F59E0B"
    readonly property color blue: "#3B82F6"

    readonly property color bg: dark ? "#0A0C12" : "#F7F8FC"
    readonly property color surface: dark ? "#12151F" : "#FFFFFF"
    readonly property color surfaceAlt: dark ? "#1A1E2A" : "#F1F3FA"
    readonly property color border: dark ? "#242938" : "#E6E8F0"
    readonly property color text: dark ? "#F2F4FB" : "#141726"
    readonly property color textMuted: dark ? "#98A0B5" : "#6B7280"
    readonly property color textFaint: dark ? "#68708A" : "#9CA3AF"
    readonly property color shadow: dark ? "#000000" : "#C9CEDC"

    readonly property int radius: 16
    readonly property int radiusSmall: 10
    readonly property int padding: 24
    readonly property int pagePadding: 32
    readonly property int navWidth: 248

    readonly property string fontFamily: "Inter, Segoe UI, Noto Sans, Sans Serif"
    readonly property string monoFamily: "JetBrains Mono, Fira Code, monospace"

    readonly property font fontTitle: Qt.font({
        family: "Inter, Segoe UI, Noto Sans, Sans Serif",
        pointSize: 26,
        weight: Font.Bold
    })
    readonly property font fontHeading: Qt.font({
        family: "Inter, Segoe UI, Noto Sans, Sans Serif",
        pointSize: 16,
        weight: Font.DemiBold
    })
    readonly property font fontBody: Qt.font({
        family: "Inter, Segoe UI, Noto Sans, Sans Serif",
        pointSize: 10,
        weight: Font.Normal
    })
    readonly property font fontSmall: Qt.font({
        family: "Inter, Segoe UI, Noto Sans, Sans Serif",
        pointSize: 9,
        weight: Font.Normal
    })
    readonly property font fontMono: Qt.font({
        family: "JetBrains Mono, Fira Code, monospace",
        pointSize: 9
    })
}
