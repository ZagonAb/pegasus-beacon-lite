import QtQuick 2.15
import QtGraphicalEffects 1.15

FocusScope {
    id: root
    anchors.fill: parent

    signal closed()
    signal platformOrderChanged()

    property int viewMode: 0
    property var fullCollectionList: []
    property var ratioMap: ({})
    property var fillMap: ({})
    property string backgroundStyle: "background"
    property bool isOpen: false
    property int currentSection: 0
    property bool rightFocused: false
    property string arFocusSection: "list"
    property bool platformsGrab: false

    readonly property var sections: [
        { id: "preferences", label: "Preferences", icon: "⚙", hasContent: true },
        { id: "platforms", label: "Platforms", icon: "▦", hasContent: true },
        { id: "aspectRatio", label: "Aspect Ratio", icon: "⊡", hasContent: true },
        { id: "about", label: "About", icon: "ℹ", hasContent: true }
    ]

    function open() {
        isOpen = true
        currentSection = 0
        rightFocused = false
        platformsGrab = false
        arFocusSection = "list"
        sectionList.currentIndex = 0
        sectionList.forceActiveFocus()
    }

    function _close() {
        isOpen = false
        root.closed()
    }

    function _enterRight() {
        var sec = sections[currentSection]
        if (!sec.hasContent) return

            if (sec.id === "about") {
                rightFocused = false
                return
            }

            rightFocused = true

            if (sec.id === "preferences") {
                arFocusSection = "list"
                preferencesPanel.forceActiveFocus()
            } else if (sec.id === "platforms") {
                if (platformsLoader.item)
                    platformsLoader.item.forceActiveFocus()
            } else if (sec.id === "aspectRatio") {
                arFocusSection = "list"
                if (rightLoader.item)
                    rightLoader.item.configListView_focus()
            }
    }

    function _onRightLoaded() {
        if (rightFocused && sections[currentSection].id === "aspectRatio")
            rightLoader.item.configListView_focus()
    }

    function _exitRight() {
        rightFocused = false
        platformsGrab = false
        arFocusSection = "list"
        prefViewMenu.close()
        themeMenu.close()
        bgStyleMenu.close()
        sectionList.forceActiveFocus()
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.isOpen ? 0.82 : 0.0
        Behavior on opacity { NumberAnimation { duration: 220 } }
    }

    Rectangle {
        id: mainPanel
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        radius: vpx(0)
        color: themeManager.color("surface")
        border { width: vpx(1); color: themeManager.color("border") }

        scale: root.isOpen ? 1.0 : 0.94
        opacity: root.isOpen ? 1.0 : 0.0
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
        Behavior on opacity { NumberAnimation { duration: 220 } }

        Rectangle {
            id: panelHeader
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: vpx(62)
            radius: vpx(0)
            color: themeManager.color("surfaceElevated")
            border { width: vpx(1); color: themeManager.color("border") }

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: vpx(16)
                color: parent.color
            }
            Row {
                id: rowPanel
                anchors { left: parent.left; leftMargin: vpx(28); verticalCenter: parent.verticalCenter }
                spacing: vpx(10)
                Image {
                    source: "assets/icon/pegasus.svg"
                    width: vpx(42)
                    height: vpx(42)
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    anchors.verticalCenter: parent.verticalCenter
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: themeManager.color("textTertiary")
                    }
                }
                Text {
                    text: "Pegasus Beacon Lite"
                    color: themeManager.color("textPrimary")
                    font { family: global.fonts.sans; pixelSize: vpx(24); bold: true }
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
                text: root.sections[root.currentSection].label
                color: themeManager.color("textTertiary")
                font { family: global.fonts.sans; pixelSize: vpx(18) }
            }

            Row {
                id: closeBtnRow
                anchors { right: parent.right; rightMargin: vpx(28); verticalCenter: parent.verticalCenter }
                spacing: vpx(8)
                Rectangle {
                    width: vpx(32)
                    height: vpx(32)
                    radius: width / 2
                    color: themeManager.color("iconPrimary")
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: "B"
                        color: themeManager.color("surface")
                        font { family: global.fonts.condensed; pixelSize: vpx(20); bold: true }
                    }
                }
                Text {
                    text: "Close"
                    color: themeManager.color("textSecondary")
                    font { family: global.fonts.sans; pixelSize: vpx(20) }
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: closeBtnRow
                onClicked: root._close()
            }
        }

        Item {
            id: contentArea

            anchors {
                top: panelHeader.bottom
                bottom: panelFooter.top
                left: parent.left
                right: parent.right
            }

            Item {
                id: leftNav
                anchors { top: parent.top; left: parent.left; bottom: parent.bottom }
                width: vpx(370)

                ListView {
                    id: sectionList
                    anchors {
                        fill: parent
                        leftMargin: vpx(14)
                        rightMargin: vpx(8)
                        topMargin: vpx(14)
                        bottomMargin: vpx(14)
                    }
                    model: root.sections
                    clip: true
                    interactive: false
                    focus: root.isOpen && !root.rightFocused

                    onCurrentIndexChanged: root.currentSection = currentIndex

                    Keys.onUpPressed: { decrementCurrentIndex(); event.accepted = true }
                    Keys.onDownPressed: { incrementCurrentIndex(); event.accepted = true }

                    Keys.onPressed: {
                        if (api.keys.isCancel(event)) {
                            event.accepted = true
                            root._close()
                            return
                        }
                        if (api.keys.isAccept(event) || event.key === Qt.Key_Right) {
                            event.accepted = true
                            var sec = root.sections[root.currentSection]
                            if (sec.id === "about") {
                                root.rightFocused = false
                                return
                            }
                            root._enterRight()
                            return
                        }
                        if (event.key === Qt.Key_Left && root.currentSection === root.sections.findIndex(s => s.id === "about")) {
                            event.accepted = true
                            root.rightFocused = false
                            return
                        }
                    }

                    delegate: Rectangle {
                        id: sectionRow
                        width: sectionList.width
                        height: vpx(90)
                        radius: vpx(10)
                        property bool isCurrent: ListView.isCurrentItem
                        property var sec: modelData
                        color: isCurrent ? themeManager.color("surfaceHighlight") : "transparent"
                        Behavior on color { ColorAnimation { duration: 140 } }

                        Rectangle {
                            id: sectionAccent
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            width: isCurrent ? vpx(3) : vpx(0)
                            height: vpx(32)
                            radius: vpx(2)
                            color: themeManager.color("accent")
                            Behavior on width { NumberAnimation { duration: 160 } }
                        }

                        Item {
                            id: sectionIconItem
                            anchors {
                                left: sectionAccent.right
                                leftMargin: vpx(10)
                                verticalCenter: parent.verticalCenter
                                verticalCenterOffset: -vpx(15)
                            }
                            width: vpx(32)
                            height: vpx(32)

                            property color sectionIconColor: isCurrent ? themeManager.color("iconPrimary") : themeManager.color("iconDisabled")
                            Behavior on sectionIconColor { ColorAnimation { duration: 140 } }

                            Image {
                                id: sectionIconImg
                                anchors.fill: parent
                                source: {
                                    if (sec.id === "preferences") return "assets/icon/preferences.svg"
                                        if (sec.id === "platforms") return "assets/icon/platforms.svg"
                                            if (sec.id === "aspectRatio") return "assets/icon/aspect-ratio.svg"
                                                if (sec.id === "about") return "assets/icon/info.svg"
                                                    return ""
                                }
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                                visible: false
                            }

                            ColorOverlay {
                                anchors.fill: sectionIconImg
                                source: sectionIconImg
                                color: sectionIconItem.sectionIconColor
                            }
                        }

                        Column {
                            anchors { left: sectionAccent.right; leftMargin: vpx(52); verticalCenter: parent.verticalCenter }
                            spacing: vpx(3)
                            Text {
                                text: sec.label
                                color: sectionRow.isCurrent ? themeManager.color("textPrimary") : themeManager.color("textTertiary")
                                font { family: global.fonts.sans; pixelSize: vpx(32); bold: sectionRow.isCurrent }
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }
                            Text {
                                text: {
                                    if (sec.id === "platforms") return "Reorder collections"
                                        if (sec.id === "preferences") return "View mode"
                                            if (sec.id === "aspectRatio") return "Box art fit"
                                                if (sec.id === "about") return "Information"
                                                    return sec.hasContent ? "Settings" : "Coming soon"
                                }
                                color: sectionRow.isCurrent ? themeManager.color("textSecondary") : themeManager.color("textDisabled")
                                font { family: global.fonts.sans; pixelSize: vpx(22) }
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }
                        }

                        Item {
                            id: arrowItem
                            anchors { right: parent.right; rightMargin: vpx(14); verticalCenter: parent.verticalCenter }
                            width: vpx(24)
                            height: vpx(24)
                            visible: sec.hasContent

                            property color arrowIconColor: sectionRow.isCurrent && sec.hasContent ? themeManager.color("iconPrimary") : themeManager.color("borderLight")
                            Behavior on arrowIconColor { ColorAnimation { duration: 140 } }

                            Image {
                                id: arrowImg
                                anchors.fill: parent
                                source: "assets/icon/arrow-right.svg"
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                                visible: false
                            }

                            ColorOverlay {
                                anchors.fill: arrowImg
                                source: arrowImg
                                color: arrowItem.arrowIconColor
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                sectionList.currentIndex = index
                                root.currentSection = index
                                root._enterRight()
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: navDivider
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: leftNav.right
                    topMargin: vpx(16)
                    bottomMargin: vpx(16)
                }
                width: vpx(1)
                color: themeManager.color("border")
            }

            Item {
                id: rightArea
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: navDivider.right
                    right: parent.right
                }

                Item {
                    anchors.fill: parent
                    visible: !root.sections[root.currentSection].hasContent
                    Column {
                        anchors.centerIn: parent
                        spacing: vpx(20)
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "( ˘▾˘)"
                            color: themeManager.color("borderLight")
                            font { family: global.fonts.condensed; pixelSize: vpx(60) }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Nothing here, continue on your way..."
                            color: themeManager.color("textDisabled")
                            font { family: global.fonts.sans; pixelSize: vpx(20) }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.sections[root.currentSection].label + "  —  Coming soon"
                            color: themeManager.color("border")
                            font { family: global.fonts.condensed; pixelSize: vpx(14) }
                        }
                    }
                }

                Item {
                    id: preferencesPanel
                    anchors.fill: parent
                    visible: root.sections[root.currentSection].id === "preferences"

                    readonly property var _modeIcons: [
                        "assets/icon/gallery.svg",
                        "assets/icon/gridview.svg",
                        "assets/icon/bulles.svg",
                        "assets/icon/listview.svg"
                    ]

                    readonly property var _modeNames: ["Gallery", "Grid", "Bubbles", "List"]

                    readonly property var _bgStyleLabels: ({
                        "hills": "Hills",
                        "ps-symbols": "PS Symbols",
                        "firefly": "Firefly",
                        "pegasus": "Pegasus-fe",
                        "background": "Background",
                        "screenshot": "Screenshot"
                    })

                    property string selectedItem: "gameview"
                    property bool panelFocused: root.rightFocused && root.sections[root.currentSection].id === "preferences"

                    focus: panelFocused

                    Keys.onUpPressed: {
                        event.accepted = true
                        if (selectedItem === "theme")
                            selectedItem = "gameview"
                            else if (selectedItem === "bgstyle")
                                selectedItem = "theme"
                                else if (selectedItem === "themecolor")
                                    selectedItem = "bgstyle"
                    }
                    Keys.onDownPressed: {
                        event.accepted = true
                        if (selectedItem === "gameview")
                            selectedItem = "theme"
                            else if (selectedItem === "theme")
                                selectedItem = "bgstyle"
                                else if (selectedItem === "bgstyle")
                                    selectedItem = "themecolor"
                    }

                    Keys.onPressed: {
                        if (api.keys.isCancel(event) || event.key === Qt.Key_Left) {
                            event.accepted = true
                            root._exitRight()
                            return
                        }
                        if (api.keys.isAccept(event)) {
                            event.accepted = true
                            if (selectedItem === "gameview")
                                prefViewMenu.toggle()
                            else if (selectedItem === "theme")
                                   themeMenu.toggle()
                            else if (selectedItem === "bgstyle")
                                   bgStyleMenu.toggle()
                            else if (selectedItem === "themecolor")
                                   themeColorMenu.toggle()
                            return
                        }
                    }

                    Column {
                        anchors {
                            top: parent.top
                            topMargin: vpx(28)
                            left: parent.left
                            leftMargin: vpx(28)
                            right: parent.right
                            rightMargin: vpx(28)
                        }
                        spacing: vpx(8)

                        Text {
                            text: "Game view"
                            color: themeManager.color("textSecondary")
                            font { family: global.fonts.sans; pixelSize: vpx(22) }
                            leftPadding: vpx(4)
                        }

                        Rectangle {
                            id: viewModeRow
                            width: parent.width
                            height: vpx(80)
                            radius: vpx(10)
                            property bool isSelected: preferencesPanel.selectedItem === "gameview" && preferencesPanel.panelFocused
                            color: isSelected ? themeManager.color("surfaceSelected") : themeManager.color("surface")
                            border {
                                width: vpx(1)
                                color: isSelected ? themeManager.color("accent") : themeManager.color("border")
                            }
                            Behavior on color { ColorAnimation { duration: 130 } }
                            Behavior on border.color { ColorAnimation { duration: 130 } }

                            Row {
                                anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                                spacing: vpx(14)

                                Image {
                                    source: preferencesPanel._modeIcons[root.viewMode] || ""
                                    width: vpx(32)
                                    height: vpx(32)
                                    fillMode: Image.PreserveAspectFit
                                    mipmap: true
                                    anchors.verticalCenter: parent.verticalCenter
                                    layer.enabled: true
                                    layer.effect: ColorOverlay {
                                        color: viewModeRow.isSelected ? themeManager.color("accent") : themeManager.color("iconSecondary")
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: vpx(3)
                                    Text {
                                        text: "Game view mode"
                                        color: viewModeRow.isSelected ? themeManager.color("textPrimary") : themeManager.color("textSecondary")
                                        font { family: global.fonts.sans; pixelSize: vpx(28); bold: viewModeRow.isSelected }
                                        Behavior on color { ColorAnimation { duration: 130 } }
                                    }
                                    Text {
                                        text: preferencesPanel._modeNames[root.viewMode] || "Gallery"
                                        color: viewModeRow.isSelected ? themeManager.color("textPrimary") : themeManager.color("textTertiary")
                                        font { family: global.fonts.sans; pixelSize: vpx(20) }
                                        Behavior on color { ColorAnimation { duration: 130 } }
                                    }
                                }
                            }

                            Image {
                                anchors { right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                                source: "assets/icon/arrow-right.svg"
                                width: vpx(16)
                                height: vpx(16)
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                                layer.enabled: true
                                layer.effect: ColorOverlay {
                                    color: viewModeRow.isSelected ? themeManager.color("accent") : themeManager.color("borderLight")
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (!root.rightFocused) {
                                        root.rightFocused = true
                                        preferencesPanel.panelFocused = true
                                    }
                                    preferencesPanel.selectedItem = "gameview"
                                    preferencesPanel.forceActiveFocus()
                                    prefViewMenu.toggle()
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: vpx(1)
                            color: themeManager.color("border")
                            opacity: 0.5
                        }

                        Text {
                            text: "Theme"
                            color: themeManager.color("textSecondary")
                            font { family: global.fonts.sans; pixelSize: vpx(22) }
                            leftPadding: vpx(4)
                        }

                        Rectangle {
                            id: themeRow
                            width: parent.width
                            height: vpx(80)
                            radius: vpx(10)
                            property bool isSelected: preferencesPanel.selectedItem === "theme" && preferencesPanel.panelFocused
                            color: isSelected ? themeManager.color("surfaceSelected") : themeManager.color("surface")
                            border {
                                width: vpx(1)
                                color: isSelected ? themeManager.color("accent") : themeManager.color("border")
                            }
                            Behavior on color { ColorAnimation { duration: 130 } }
                            Behavior on border.color { ColorAnimation { duration: 130 } }

                            Row {
                                anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                                spacing: vpx(14)

                                Image {
                                    id: themeIcon
                                    source: "assets/icon/theme.svg"
                                    width: vpx(32)
                                    height: vpx(32)
                                    fillMode: Image.PreserveAspectFit
                                    mipmap: true
                                    anchors.verticalCenter: parent.verticalCenter
                                    layer.enabled: true
                                    layer.effect: ColorOverlay {
                                        color: themeRow.isSelected ? themeManager.color("accent") : themeManager.color("iconSecondary")
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: vpx(3)
                                    Text {
                                        text: "Theme"
                                        color: themeRow.isSelected ? themeManager.color("textPrimary") : themeManager.color("textSecondary")
                                        font { family: global.fonts.sans; pixelSize: vpx(28); bold: themeRow.isSelected }
                                        Behavior on color { ColorAnimation { duration: 130 } }
                                    }
                                    Text {
                                        text: themeManager.currentTheme === "dark" ? "Dark" : "Light"
                                        color: themeRow.isSelected ? themeManager.color("textPrimary") : themeManager.color("textTertiary")
                                        font { family: global.fonts.sans; pixelSize: vpx(20) }
                                        Behavior on color { ColorAnimation { duration: 130 } }
                                    }
                                }
                            }

                            Rectangle {
                                anchors { right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                                width: vpx(80)
                                height: vpx(36)
                                radius: vpx(18)
                                color: themeManager.currentTheme === "dark" ? themeManager.color("surfaceHover") : themeManager.color("borderLight")

                                Text {
                                    anchors.centerIn: parent
                                    text: themeManager.currentTheme === "dark" ? "Dark" : "Light"
                                    color: themeManager.color("textPrimary")
                                    font { family: global.fonts.sans; pixelSize: vpx(16); bold: true }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (!root.rightFocused) {
                                        root.rightFocused = true
                                        preferencesPanel.panelFocused = true
                                    }
                                    preferencesPanel.selectedItem = "theme"
                                    preferencesPanel.forceActiveFocus()
                                    themeMenu.toggle()
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: vpx(1)
                            color: themeManager.color("border")
                            opacity: 0.5
                        }

                        Text {
                            text: "Background Style"
                            color: themeManager.color("textSecondary")
                            font { family: global.fonts.sans; pixelSize: vpx(22) }
                            leftPadding: vpx(4)
                        }

                        Rectangle {
                            id: bgStyleRow
                            width: parent.width
                            height: vpx(80)
                            radius: vpx(10)
                            property bool isSelected: preferencesPanel.selectedItem === "bgstyle" && preferencesPanel.panelFocused
                            color: isSelected ? themeManager.color("surfaceSelected") : themeManager.color("surface")
                            border {
                                width: vpx(1)
                                color: isSelected ? themeManager.color("accent") : themeManager.color("border")
                            }
                            Behavior on color { ColorAnimation { duration: 130 } }
                            Behavior on border.color { ColorAnimation { duration: 130 } }

                            Row {
                                anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                                spacing: vpx(14)

                                Image {
                                    source: "assets/icon/background.svg"
                                    width: vpx(32)
                                    height: vpx(32)
                                    fillMode: Image.PreserveAspectFit
                                    mipmap: true
                                    anchors.verticalCenter: parent.verticalCenter
                                    layer.enabled: true
                                    layer.effect: ColorOverlay {
                                        color: bgStyleRow.isSelected ? themeManager.color("accent") : themeManager.color("iconSecondary")
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: vpx(3)
                                    Text {
                                        text: "Background Style"
                                        color: bgStyleRow.isSelected ? themeManager.color("textPrimary") : themeManager.color("textSecondary")
                                        font { family: global.fonts.sans; pixelSize: vpx(28); bold: bgStyleRow.isSelected }
                                        Behavior on color { ColorAnimation { duration: 130 } }
                                    }
                                    Text {
                                        text: preferencesPanel._bgStyleLabels[root.backgroundStyle] || "Background"
                                        color: bgStyleRow.isSelected ? themeManager.color("textPrimary") : themeManager.color("textTertiary")
                                        font { family: global.fonts.sans; pixelSize: vpx(20) }
                                        Behavior on color { ColorAnimation { duration: 130 } }
                                    }
                                }
                            }

                            Rectangle {
                                anchors { right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                                width: vpx(110)
                                height: vpx(36)
                                radius: vpx(18)
                                color: themeManager.color("surfaceHover")

                                Text {
                                    anchors.centerIn: parent
                                    text: preferencesPanel._bgStyleLabels[root.backgroundStyle] || "Background"
                                    color: themeManager.color("textPrimary")
                                    font { family: global.fonts.sans; pixelSize: vpx(16); bold: true }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (!root.rightFocused) {
                                        root.rightFocused = true
                                        preferencesPanel.panelFocused = true
                                    }
                                    preferencesPanel.selectedItem = "bgstyle"
                                    preferencesPanel.forceActiveFocus()
                                    bgStyleMenu.toggle()
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: vpx(1)
                            color: themeManager.color("border")
                            opacity: 0.5
                        }

                        Text {
                            text: "Theme Color"
                            color: themeManager.color("textSecondary")
                            font { family: global.fonts.sans; pixelSize: vpx(22) }
                            leftPadding: vpx(4)
                        }

                        Rectangle {
                            id: themeColorRow
                            width: parent.width
                            height: vpx(80)
                            radius: vpx(10)
                            property bool isSelected: preferencesPanel.selectedItem === "themecolor" && preferencesPanel.panelFocused
                            color: isSelected ? themeManager.color("surfaceSelected") : themeManager.color("surface")
                            border {
                                width: vpx(1)
                                color: isSelected ? themeManager.color("accent") : themeManager.color("border")
                            }
                            Behavior on color { ColorAnimation { duration: 130 } }
                            Behavior on border.color { ColorAnimation { duration: 130 } }

                            Row {
                                anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                                spacing: vpx(14)

                                Item {
                                    width: vpx(32)
                                    height: vpx(32)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: vpx(6)
                                        border.width: vpx(1)
                                        border.color: themeManager.color("borderLight")
                                        color: "transparent"
                                    }

                                    Image {
                                        id: dropIcon
                                        anchors.centerIn: parent
                                        width: vpx(24)
                                        height: vpx(24)
                                        source: "assets/icon/drop.svg"
                                        sourceSize: Qt.size(width, height)
                                        fillMode: Image.PreserveAspectFit
                                        visible: false
                                    }

                                    ColorOverlay {
                                        anchors.fill: dropIcon
                                        source: dropIcon
                                        color: themeManager.accentColorValue
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: vpx(3)
                                    Text {
                                        text: "Theme Color"
                                        color: themeColorRow.isSelected ? themeManager.color("textPrimary") : themeManager.color("textSecondary")
                                        font { family: global.fonts.sans; pixelSize: vpx(28); bold: themeColorRow.isSelected }
                                        Behavior on color { ColorAnimation { duration: 130 } }
                                    }
                                    Text {
                                        text: {
                                            var map = { emerald:"Emerald", amber:"Amber", fuchsia:"Fuchsia",
                                                skyblue:"Sky Blue", ruby:"Ruby", purple:"Purple", default:"Default" }
                                                return map[themeManager.accentColorName] || "Default"
                                        }
                                        color: themeColorRow.isSelected ? themeManager.color("textPrimary") : themeManager.color("textTertiary")
                                        font { family: global.fonts.sans; pixelSize: vpx(20) }
                                        Behavior on color { ColorAnimation { duration: 130 } }
                                    }
                                }
                            }

                            Rectangle {
                                anchors { right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                                width: vpx(110)
                                height: vpx(36)
                                radius: vpx(18)
                                color: themeManager.color("surfaceHover")

                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        var map = { emerald:"Emerald", amber:"Amber", fuchsia:"Fuchsia",
                                            skyblue:"Sky Blue", ruby:"Ruby", purple:"Purple", default:"Default" }
                                            return map[themeManager.accentColorName] || "Default"
                                    }
                                    color: themeManager.color("textPrimary")
                                    font { family: global.fonts.sans; pixelSize: vpx(16); bold: true }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (!root.rightFocused) {
                                        root.rightFocused = true
                                        preferencesPanel.panelFocused = true
                                    }
                                    preferencesPanel.selectedItem = "themecolor"
                                    preferencesPanel.forceActiveFocus()
                                    themeColorMenu.toggle()
                                }
                            }
                        }
                    }
                }

                Item {
                    id: aboutPanel
                    anchors.fill: parent
                    visible: root.sections[root.currentSection].id === "about"

                    Flickable {
                        anchors.fill: parent
                        contentHeight: aboutContent.height + vpx(56)
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: aboutContent
                            anchors {
                                top: parent.top
                                topMargin: vpx(10)
                                left: parent.left
                                leftMargin: vpx(40)
                                right: parent.right
                                rightMargin: vpx(40)
                            }
                            spacing: vpx(12)

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: vpx(20)

                                Image {
                                    source: "assets/icon/pegasus.svg"
                                    width: vpx(80)
                                    height: vpx(80)
                                    fillMode: Image.PreserveAspectFit
                                    mipmap: true
                                    anchors.verticalCenter: parent.verticalCenter
                                    layer.enabled: true
                                    layer.effect: ColorOverlay {
                                        color: themeManager.color("accent")
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: vpx(8)

                                    Text {
                                        text: "Pegasus Beacon Lite"
                                        color: themeManager.color("textPrimary")
                                        font { family: global.fonts.sans; pixelSize: vpx(38); bold: true }
                                    }

                                    Text {
                                        text: "Version 1.0"
                                        color: themeManager.color("textSecondary")
                                        font { family: global.fonts.condensed; pixelSize: vpx(20) }
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: vpx(1)
                                color: themeManager.color("border")
                                opacity: 0.3
                            }

                            Column {
                                width: parent.width
                                spacing: vpx(24)

                                Row {
                                    spacing: vpx(16)

                                    Text {
                                        text: "Developer"
                                        width: vpx(140)
                                        color: themeManager.color("textSecondary")
                                        font { family: global.fonts.sans; pixelSize: vpx(22) }
                                    }

                                    Text {
                                        text: "ZagonAb"
                                        color: themeManager.color("accent")
                                        font { family: global.fonts.sans; pixelSize: vpx(22); bold: true }
                                    }
                                }

                                Row {
                                    spacing: vpx(16)

                                    Text {
                                        text: "GitHub"
                                        width: vpx(140)
                                        color: themeManager.color("textSecondary")
                                        font { family: global.fonts.sans; pixelSize: vpx(22) }
                                    }

                                    Text {
                                        text: "github.com/ZagonAb"
                                        color: themeManager.color("textPrimary")
                                        font {
                                            family: global.fonts.sans
                                            pixelSize: vpx(22)
                                            underline: githubLinkMa.containsMouse
                                        }

                                        MouseArea {
                                            id: githubLinkMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: Qt.openUrlExternally("https://github.com/ZagonAb")
                                        }
                                    }
                                }

                                Row {
                                    spacing: vpx(16)

                                    Text {
                                        text: "License"
                                        width: vpx(140)
                                        color: themeManager.color("textSecondary")
                                        font { family: global.fonts.sans; pixelSize: vpx(22) }
                                    }

                                    Column {
                                        spacing: vpx(6)

                                        Text {
                                            text: "CC BY-NC-SA 4.0"
                                            color: themeManager.color("textPrimary")
                                            font {
                                                family: global.fonts.sans
                                                pixelSize: vpx(22)
                                                underline: licenseLinkMa.containsMouse
                                            }

                                            MouseArea {
                                                id: licenseLinkMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                onClicked: Qt.openUrlExternally("https://creativecommons.org/licenses/by-nc-sa/4.0/")
                                            }
                                        }

                                        Text {
                                            text: "Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International"
                                            color: themeManager.color("textTertiary")
                                            font { family: global.fonts.condensed; pixelSize: vpx(14) }
                                            wrapMode: Text.WordWrap
                                            width: parent.width
                                        }
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: vpx(1)
                                    color: themeManager.color("border")
                                    opacity: 0.3
                                }

                                Column {
                                    width: parent.width
                                    spacing: vpx(12)

                                    Text {
                                        text: "Disclaimer"
                                        color: themeManager.color("textSecondary")
                                        font { family: global.fonts.sans; pixelSize: vpx(22); bold: true }
                                    }

                                    Text {
                                        text: "Pegasus Beacon Lite is an independent, open-source project created from scratch as a recreation inspired by the user interface of Beacon Game Launcher. Beacon Game Launcher is proprietary software and this project has no affiliation, association, authorization, or endorsement from Beacon Game Launcher or its developers. All code in this project is original and written specifically for Pegasus Beacon Lite."
                                        color: themeManager.color("textTertiary")
                                        font { family: global.fonts.sans; pixelSize: vpx(16) }
                                        wrapMode: Text.WordWrap
                                        width: parent.width
                                        lineHeight: 1.5
                                    }
                                }

                                Column {
                                    width: parent.width
                                    spacing: vpx(12)

                                    Text {
                                        text: "Inspired by"
                                        color: themeManager.color("textSecondary")
                                        font { family: global.fonts.sans; pixelSize: vpx(22); bold: true }
                                    }

                                    Text {
                                        text: "Beacon Game Launcher"
                                        color: themeManager.color("textPrimary")
                                        font { family: global.fonts.sans; pixelSize: vpx(20) }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors {
                            right: parent.right
                            rightMargin: vpx(4)
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: vpx(3)
                        radius: vpx(2)
                        color: themeManager.color("borderLight")
                        opacity: 0.3
                        visible: aboutContent.height > parent.height
                    }
                }

                Loader {
                    id: platformsLoader
                    anchors.fill: parent
                    active: root.sections[root.currentSection].id === "platforms"
                    source: "PlatformsPanel.qml"

                    onLoaded: {
                        if (root.rightFocused && root.sections[root.currentSection].id === "platforms")
                            item.forceActiveFocus()
                    }
                }

                Connections {
                    target: platformsLoader.item
                    function onBackRequested() { root._exitRight() }
                    function onOrderChanged() { root.platformOrderChanged() }
                    function onGamepadGrabChanged() {
                        root.platformsGrab = platformsLoader.item ? platformsLoader.item.gamepadGrab : false
                    }
                }

                Loader {
                    id: rightLoader
                    anchors.fill: parent
                    active: root.sections[root.currentSection].id === "aspectRatio"
                    source: "AspectRatioConfig.qml"

                    onLoaded: {
                        item.embedded = true
                        item.fullCollectionList = Qt.binding(function() { return root.fullCollectionList })
                        item._buildEntries()
                        item._loadFromMemory()
                        item.isOpen = true
                        root._onRightLoaded()
                    }
                }

                Connections {
                    target: rightLoader.item
                    function onRatioMapChanged() {
                        var m = rightLoader.item ? rightLoader.item.ratioMap : null
                        if (m && Object.keys(m).length > 0) root.ratioMap = m
                    }
                    function onFillMapChanged() {
                        var m = rightLoader.item ? rightLoader.item.fillMap : null
                        if (m) root.fillMap = m
                    }
                    function onFocusSectionChanged() {
                        root.arFocusSection = rightLoader.item ? rightLoader.item.focusSection : "list"
                    }
                    function onBackRequested() { root._exitRight() }
                }
            }
        }

        Rectangle {
            id: panelFooter
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: vpx(50)
            radius: vpx(0)
            color: themeManager.color("surfaceElevated")
            border { width: vpx(1); color: themeManager.color("border") }

            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: vpx(16)
                color: parent.color
            }

            Column {
                anchors.centerIn: parent
                spacing: vpx(4)
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Pegasus Beacon Lite v1.0 · Developed by ZagonAb"
                    color: themeManager.color("textTertiary")
                    font { family: global.fonts.sans; pixelSize: vpx(11) }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Inspired by Beacon Game Launcher"
                    color: themeManager.color("border")
                    font { family: global.fonts.condensed; pixelSize: vpx(9) }
                    opacity: 0.7
                }
            }
        }

        ViewSwitcherMenu {
            id: prefViewMenu
            z: 20
            currentViewMode: root.viewMode
            anchorItem: viewModeRow
            openDirection: "down"
            anchorAlignment: "left"

            onViewSelected: function(mode) { root.viewMode = mode }
            onMenuClosed: { preferencesPanel.forceActiveFocus() }
        }

        ThemeSwitcherMenu {
            id: themeMenu
            z: 20
            currentTheme: themeManager.currentTheme
            anchorItem: themeRow
            openDirection: "down"
            anchorAlignment: "left"

            onThemeSelected: function(theme) { themeManager.setTheme(theme) }
            onMenuClosed: { preferencesPanel.forceActiveFocus() }
        }

        BackgroundStyleMenu {
            id: bgStyleMenu
            z: 20
            currentStyle: root.backgroundStyle
            anchorItem: bgStyleRow
            openDirection: "down"
            anchorAlignment: "left"

            Component.onCompleted: loadFromMemory()

            onStyleSelected: function(style) { root.backgroundStyle = style }
            onMenuClosed: { preferencesPanel.forceActiveFocus() }
        }

        ThemeColorMenu {
            id: themeColorMenu
            z: 20
            currentColor: themeManager.accentColorName
            anchorItem: themeColorRow
            openDirection: "down"
            anchorAlignment: "left"

            onColorSelected: function(colorName) {
                themeManager.setAccentColor(colorName)
            }
            onMenuClosed: {
                preferencesPanel.forceActiveFocus()
            }
        }
    }
}
