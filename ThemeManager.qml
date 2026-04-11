import QtQuick 2.15

QtObject {
    id: themeManager

    property string currentTheme: "dark"
    property string accentColorName: "default"

    property color accentColorValue: {
        if (accentColorName === "default") {
            return currentTheme === "dark" ? "#FFFFFF" : "#212529"
        }
        return _colorMap[accentColorName] || "#FFFFFF"
    }

    readonly property color effectiveAccentColor: {
        if (accentColorName !== "default")
            return accentColorValue
            else
                return color("accent")
    }

    readonly property var _colorMap: ({
        "emerald":"#10B981",
        "amber":"#F59E0B",
        "fuchsia":"#D946EF",
        "skyblue":"#0EA5E9",
        "ruby":"#EF4444",
        "purple":"#8B5CF6"
    })

    signal themeChanged()

    signal accentColorChanged()

    function setAccentColor(name) {
        if (accentColorName === name) return
            accentColorName = name
            api.memory.set("themeColor", name)
            accentColorChanged()
    }

    function setTheme(theme) {
        if (theme === currentTheme) return
            currentTheme = theme
            themeChanged()
            api.memory.set("appTheme", theme)
    }

    Component.onCompleted: {
        var saved = api.memory.get("appTheme")
        if (saved === "light" || saved === "dark")
            currentTheme = saved

            var savedColor = api.memory.get("themeColor")
            if (savedColor && _colorMap[savedColor] !== undefined)
                accentColorName = savedColor
                else
                    accentColorName = "default"
    }

    readonly property var darkPalette: ({
        background: "#0D0D0D",
        surface: "#111111",
        surfaceElevated: "#1A1A1A",
        surfaceHighlight: "#252525",
        surfaceHover: "#2C2C2C",
        surfaceSelected: "#2A2A2A",
        textPrimary: "#FFFFFF",
        textSecondary: "#888888",
        textTertiary: "#555555",
        textDisabled: "#333333",
        border: "#2A2A2A",
        borderLight: "#3A3A3A",
        borderHighlight: "#4A4A4A",
        accent: "#FFFFFF",
        accentHover: "#5BA0E9",
        success: "#4CAF50",
        warning: "#FF9800",
        error: "#F44336",
        overlayDark: "#CC000000",
        overlayMedium: "#88000000",
        overlayLight: "#44000000",
        iconPrimary: "#FFFFFF",
        iconSecondary: "#888888",
        iconDisabled: "#333333"
    })

    readonly property var lightPalette: ({
        background: "#E8ECEF",
        surface: "#F8F9FA",
        surfaceElevated: "#FFFFFF",
        surfaceHighlight: "#CCCCCD",
        surfaceHover: "#DEE2E6",
        surfaceSelected: "#CCCCCD",
        textPrimary: "#212529",
        textSecondary: "#495057",
        textTertiary: "#6C757D",
        textDisabled: "#ADB5BD",
        border: "#DEE2E6",
        borderLight: "#CCCCCD",
        borderHighlight: "#CED4DA",
        accent: "#212529",
        accentHover: "#3A80C9",
        success: "#4CAF50",
        warning: "#FF9800",
        error: "#F44336",
        overlayDark: "#CCFFFFFF",
        overlayMedium: "#88FFFFFF",
        overlayLight: "#44FFFFFF",
        iconPrimary: "#212529",
        iconSecondary: "#495057",
        iconDisabled: "#ADB5BD"
    })

    readonly property var activePalette: currentTheme === "light" ? lightPalette : darkPalette

    function color(name) {
        return activePalette[name] || darkPalette[name] || "#FFFFFF"
    }
}
