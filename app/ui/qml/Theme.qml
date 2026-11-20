pragma Singleton
import QtQuick 6.0
import QtQuick.Controls 6.0

QtObject {
    readonly property bool dark: appController ? appController.effectiveTheme === "dark" : true

    // CachyOS cyan/green family: colour lives on data and one highlight,
    // never on every control. True neutral darks, no navy or slate.
    readonly property color accent: "#22D3EE"
    readonly property color accentLight: "#67E8F9"
    readonly property color accentDark: "#0E7490"
    readonly property color green: "#34D399"
    readonly property color red: "#F87171"
    readonly property color amber: "#FBBF24"
    readonly property color blue: "#60A5FA"

    readonly property color bg: dark ? "#0C0E11" : "#F7F8FA"
    readonly property color surface: dark ? "#14171C" : "#FFFFFF"
    readonly property color surfaceAlt: dark ? "#1B1F26" : "#F1F3F6"
    readonly property color border: dark ? "#282D36" : "#E5E8EE"
    readonly property color text: dark ? "#F4F6F8" : "#141726"
    readonly property color textMuted: dark ? "#A9B1BD" : "#606876"
    readonly property color textFaint: dark ? "#7D8795" : "#858D99"
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
        pointSize: 24,
        weight: Font.DemiBold
    })
    readonly property font fontHeading: Qt.font({
        family: "Inter, Segoe UI, Noto Sans, Sans Serif",
        pointSize: 16,
        weight: Font.DemiBold
    })
    readonly property font fontBody: Qt.font({
        family: "Inter, Segoe UI, Noto Sans, Sans Serif",
        pointSize: 14,
        weight: Font.Normal
    })
    readonly property font fontSmall: Qt.font({
        family: "Inter, Segoe UI, Noto Sans, Sans Serif",
        pointSize: 12,
        weight: Font.Normal
    })
    readonly property font fontMono: Qt.font({
        family: "JetBrains Mono, Fira Code, monospace",
        pointSize: 11
    })
}
