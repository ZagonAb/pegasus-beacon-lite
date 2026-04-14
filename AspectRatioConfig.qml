import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

FocusScope {
    id: root

    property var fullCollectionList: []
    property bool embedded: false

    signal closed()
    signal backRequested()

    property bool isOpen: false
    property bool panelFocused: false
    property var ratioMap: ({})
    property var fillMap: ({})

    readonly property var ratioKeys: ["", "1:1", "4:3", "3:4", "8:7", "3:5", "2:3", "custom"]
    readonly property var ratioLabels: ({
        "": "Auto",
        "1:1": "1:1 — Square",
        "4:3": "4:3 — Landscape",
        "3:4": "3:4 — Portrait",
        "8:7": "8:7 — NDS / 3DS",
        "3:5": "3:5 — PSP / Switch",
        "2:3": "2:3 — Box Front",
        "custom": "Custom"
    })

    readonly property var fillKeys: ["PreserveAspectFit", "Stretch", "PreserveAspectCrop"]
    readonly property var fillLabels: ({
        "PreserveAspectFit" : "Preserve Aspect Fit",
        "Stretch": "Stretch",
        "PreserveAspectCrop": "Preserve Aspect Crop"
    })

    property var configEntries: []
    property string focusSection: "list"
    property var customMap: ({})

    function _getCustomW(key) {
        if (customMap.hasOwnProperty(key)) return customMap[key].w || 1
            var saved = ratioMap[key] || ""
            if (saved && saved.indexOf("custom:") === 0) {
                var parts = saved.substring(7).split(":")
                return parseFloat(parts[0]) || 1
            }
            return 1
    }

    function _getCustomH(key) {
        if (customMap.hasOwnProperty(key)) return customMap[key].h || 1
            var saved = ratioMap[key] || ""
            if (saved && saved.indexOf("custom:") === 0) {
                var parts = saved.substring(7).split(":")
                return parseFloat(parts[1]) || 1
            }
            return 1
    }

    function _setCustomValue(key, wVal, hVal) {
        var copy = JSON.parse(JSON.stringify(customMap))
        copy[key] = { w: wVal, h: hVal }
        customMap = copy
        var rCopy = JSON.parse(JSON.stringify(ratioMap))
        rCopy[key] = "custom:" + wVal + ":" + hVal
        ratioMap = rCopy
        _saveToMemory()
    }

    Component.onCompleted: { _loadFromMemory() }

    function open() {
        _loadFromMemory()
        _buildEntries()
        isOpen = true
        panelFocused = true
        focusSection = "list"
        configListView.currentIndex = 0
        configListView.forceActiveFocus()
    }

    function configListView_focus() {
        panelFocused = true
        focusSection = "list"
        configListView.forceActiveFocus()
    }

    function getAspectRatioFor(collectionEntry) {
        if (!collectionEntry) return ""
            var key = _keyFor(collectionEntry)
            if (ratioMap.hasOwnProperty(key)) return ratioMap[key]
                return collectionEntry.isVirtual ? "2:3" : ""
    }

    function getFillModeFor(collectionEntry) {
        if (!collectionEntry) return "PreserveAspectFit"
            var key = _keyFor(collectionEntry)
            if (fillMap.hasOwnProperty(key)) return fillMap[key]
                return "PreserveAspectFit"
    }

    function _keyFor(collectionEntry) {
        if (!collectionEntry) return ""
            if (collectionEntry.isVirtual) return "virtual"
                return collectionEntry.shortName || collectionEntry.name || ""
    }

    function _buildEntries() {
        var entries = []
        var hasVirtual = false
        for (var i = 0; i < fullCollectionList.length; i++) {
            if (fullCollectionList[i].isVirtual) { hasVirtual = true; break }
        }
        if (hasVirtual) {
            entries.push({
                label: "FAVS & NOW",
                key: "virtual",
                isVirtual: true,
                description: "Virtual collections (Favorites and Recent)"
            })
        }
        for (var j = 0; j < fullCollectionList.length; j++) {
            var col = fullCollectionList[j]
            if (!col.isVirtual) {
                entries.push({
                    label: col.name,
                    key: col.shortName || col.name || "",
                    isVirtual: false,
                    description: col.summary || ""
                })
            }
        }
        configEntries = entries
    }

    function _loadFromMemory() {
        var saved = api.memory.get("arConfig")
        if (saved !== undefined && saved !== null && typeof saved === "object") {
            ratioMap = JSON.parse(JSON.stringify(saved))
        } else if (typeof saved === "string") {
            try { ratioMap = JSON.parse(saved) } catch(e) { ratioMap = {} }
        } else {
            ratioMap = {}
        }
        var savedFill = api.memory.get("fillConfig")
        if (savedFill !== undefined && savedFill !== null && typeof savedFill === "object") {
            fillMap = JSON.parse(JSON.stringify(savedFill))
        } else if (typeof savedFill === "string") {
            try { fillMap = JSON.parse(savedFill) } catch(e) { fillMap = {} }
        } else {
            fillMap = {}
        }
        var cMap = {}
        for (var k in ratioMap) {
            var val = ratioMap[k]
            if (typeof val === "string" && val.indexOf("custom:") === 0) {
                var parts = val.substring(7).split(":")
                var w = parseFloat(parts[0])
                var h = parseFloat(parts[1])
                if (!isNaN(w) && !isNaN(h) && w > 0 && h > 0) {
                    cMap[k] = { w: w, h: h }
                }
            }
        }
        customMap = cMap
    }

    function _saveToMemory() {
        api.memory.set("arConfig", JSON.parse(JSON.stringify(ratioMap)))
        api.memory.set("fillConfig", JSON.parse(JSON.stringify(fillMap)))
    }

    function _getRatioFor(key, isVirtual) {
        if (ratioMap.hasOwnProperty(key)) return ratioMap[key]
            return isVirtual ? "2:3" : ""
    }

    function _getFillFor(key) {
        if (fillMap.hasOwnProperty(key)) return fillMap[key]
            return "PreserveAspectFit"
    }

    function _setRatioFor(key, ratioKey) {
        if (ratioKey === "custom") {
            var cW = _getCustomW(key)
            var cH = _getCustomH(key)
            if (!customMap.hasOwnProperty(key)) {
                cW = 1; cH = 1
                var cCopy = JSON.parse(JSON.stringify(customMap))
                cCopy[key] = { w: cW, h: cH }
                customMap = cCopy
            }
            var copy = JSON.parse(JSON.stringify(ratioMap))
            copy[key] = "custom:" + cW + ":" + cH
            ratioMap = copy
        } else {
            var copy2 = JSON.parse(JSON.stringify(ratioMap))
            copy2[key] = ratioKey
            ratioMap = copy2
        }
        _saveToMemory()
    }

    function _setFillFor(key, fillKey) {
        var copy = JSON.parse(JSON.stringify(fillMap))
        copy[key] = fillKey
        fillMap = copy
        _saveToMemory()
    }

    function _close() {
        isOpen = false
        panelFocused = false
        root.closed()
    }

    visible: root.embedded ? true : root.isOpen
    anchors.fill: parent
    z: root.embedded ? 0 : 100

    Rectangle {
        anchors.fill: parent
        color: themeManager.color("overlayDark")
        opacity: 0.78
        visible: !root.embedded
        Behavior on opacity { NumberAnimation { duration: 220 } }
        MouseArea { anchors.fill: parent; onClicked: root._close() }
    }

    Item {
        id: panelContainer
        anchors.centerIn: root.embedded ? undefined : parent
        anchors.fill: root.embedded ? parent : undefined
        width: root.embedded ? undefined : Math.min(root.width * 0.82, vpx(900))
        height: root.embedded ? undefined : Math.min(root.height * 0.84, vpx(680))

        Rectangle {
            anchors.fill: parent
            visible: !root.embedded
            radius: vpx(16)
            color: themeManager.color("surface")
            border { width: vpx(1); color: themeManager.color("border") }
            scale: root.isOpen ? 1.0 : 0.92
            opacity: root.isOpen ? 1.0 : 0.0
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
            Behavior on opacity { NumberAnimation { duration: 220 } }
        }

        Rectangle {
            id: panelHeader
            visible: !root.embedded
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: vpx(58)
            radius: vpx(16)
            color: themeManager.color("surfaceElevated")
            border { width: vpx(1); color: themeManager.color("border") }
            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: vpx(16)
                color: parent.color
            }
            Row {
                anchors { left: parent.left; leftMargin: vpx(24); verticalCenter: parent.verticalCenter }
                spacing: vpx(12)
                Rectangle {
                    width: vpx(28); height: vpx(28); radius: vpx(14)
                    color: themeManager.color("surfaceHover")
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: "X"
                        color: themeManager.color("textPrimary")
                        font { family: global.fonts.condensed; pixelSize: vpx(14); bold: true }
                    }
                }
                Text {
                    text: "Aspect Ratio Settings"
                    color: themeManager.color("textPrimary")
                    font { family: fontManager.currentFont; pixelSize: vpx(22); bold: true }
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Text {
                anchors { right: parent.right; rightMargin: vpx(24); verticalCenter: parent.verticalCenter }
                text: "B  Close"
                color: themeManager.color("textSecondary")
                font { family: fontManager.currentFont; pixelSize: vpx(16) }
            }
        }

        Rectangle {
            id: panelFooter
            visible: !root.embedded
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: vpx(48)
            radius: vpx(16)
            color: themeManager.color("surfaceElevated")
            border { width: vpx(1); color: themeManager.color("border") }
            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: vpx(16)
                color: parent.color
            }
            Row {
                anchors { left: parent.left; leftMargin: vpx(20); verticalCenter: parent.verticalCenter }
                spacing: vpx(24)
                Row {
                    spacing: vpx(6); anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: "←  →"
                        color: themeManager.color("textPrimary")
                        font { family: global.fonts.condensed; pixelSize: vpx(15); bold: true }
                    }
                    Text {
                        text: "Change"
                        color: themeManager.color("textSecondary")
                        font { family: fontManager.currentFont; pixelSize: vpx(14) }
                    }
                }
                Row {
                    spacing: vpx(6); anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: "↑  ↓"
                        color: themeManager.color("textPrimary")
                        font { family: global.fonts.condensed; pixelSize: vpx(15); bold: true }
                    }
                    Text {
                        text: "Navigate"
                        color: themeManager.color("textSecondary")
                        font { family: fontManager.currentFont; pixelSize: vpx(14) }
                    }
                }
            }
            Row {
                anchors { right: parent.right; rightMargin: vpx(20); verticalCenter: parent.verticalCenter }
                spacing: vpx(6)
                Rectangle {
                    width: vpx(22); height: vpx(22); radius: vpx(11)
                    color: themeManager.color("iconPrimary")
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: "B"
                        color: themeManager.color("surface")
                        font { family: global.fonts.condensed; pixelSize: vpx(13); bold: true }
                    }
                }
                Text {
                    text: "Close and apply"
                    color: themeManager.color("textTertiary")
                    font { family: fontManager.currentFont; pixelSize: vpx(14) }
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Item {
            id: leftPane
            anchors {
                top: root.embedded ? parent.top : panelHeader.bottom
                bottom: root.embedded ? parent.bottom : panelFooter.top
                left: parent.left
                topMargin: vpx(8)
            }
            width: vpx(280)

            ListView {
                id: configListView
                anchors {
                    fill: parent
                    leftMargin: vpx(12); rightMargin: vpx(4)
                    topMargin: vpx(8); bottomMargin: vpx(8)
                }
                model: root.configEntries
                clip: true
                focus: root.panelFocused && root.focusSection === "list"

                Keys.onUpPressed: { decrementCurrentIndex(); event.accepted = true }
                Keys.onDownPressed: { incrementCurrentIndex(); event.accepted = true }

                Keys.onPressed: {
                    if (api.keys.isCancel(event) || event.key === Qt.Key_Left) {
                        event.accepted = true
                        if (root.embedded) {
                            root.panelFocused = false
                            root.backRequested()
                        } else {
                            root._close()
                        }
                        return
                    }
                    if (api.keys.isAccept(event)) {
                        event.accepted = true
                        root.focusSection = "ratio"
                        ratioMenuButton.forceActiveFocus()
                        return
                    }
                    if (api.keys.isAccept(event) || event.key === Qt.Key_Right) {
                        event.accepted = true
                        root.focusSection = "ratio"
                        ratioMenuButton.forceActiveFocus()
                        return
                    }
                }

                delegate: Rectangle {
                    id: rowItem
                    width: configListView.width
                    height: vpx(56)
                    radius: vpx(10)
                    property bool isCurrent: ListView.isCurrentItem
                    property bool isActive: isCurrent && root.panelFocused && root.focusSection === "list"
                    property bool isSelected: isCurrent
                    property var entry: modelData
                    color: isActive ? themeManager.color("surfaceHover") : (isSelected ? themeManager.color("surfaceHighlight") : "transparent")

                    Rectangle {
                        id: typePill
                        anchors { left: parent.left; leftMargin: vpx(12); verticalCenter: parent.verticalCenter }
                        width: vpx(6); height: vpx(30); radius: vpx(3)
                        color: entry && entry.isVirtual ? themeManager.color("iconPrimary") : themeManager.color("surfaceHover")
                    }

                    Text {
                        id: collectionName
                        anchors {
                            left: typePill.right; leftMargin: vpx(10)
                            right: parent.right; rightMargin: vpx(12)
                            top: parent.top; topMargin: vpx(10)
                        }
                        text: entry ? entry.label : ""
                        color: (isActive || isSelected) ? themeManager.color("textPrimary") : themeManager.color("textTertiary")
                        font { family: fontManager.currentFont; pixelSize: vpx(16); bold: isActive || isSelected }
                        elide: Text.ElideRight
                    }

                    Text {
                        anchors {
                            left: collectionName.left; right: parent.right; rightMargin: vpx(13)
                            bottom: parent.bottom; bottomMargin: vpx(8)
                        }
                        text: {
                            var rk = entry ? root._getRatioFor(entry.key, entry.isVirtual) : ""
                            if (rk === "") return "Auto"
                                if (rk.indexOf("custom:") === 0) return rk.substring(7)
                                    return rk
                        }
                        color: (isActive || isSelected) ? themeManager.color("textPrimary") : themeManager.color("textTertiary")
                        font { family: global.fonts.condensed; pixelSize: vpx(13); bold: true }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            configListView.currentIndex = index
                            root.focusSection = "ratio"
                            ratioMenuButton.forceActiveFocus()
                        }
                    }
                }
            }
        }

        Rectangle {
            id: divider
            anchors {
                top: root.embedded ? parent.top : panelHeader.bottom
                bottom: root.embedded ? parent.bottom : panelFooter.top
                left: leftPane.right
                topMargin: vpx(16); bottomMargin: vpx(16)
            }
            width: vpx(1)
            color: themeManager.color("border")
        }

        Item {
            id: rightPane
            anchors {
                top: root.embedded ? parent.top : panelHeader.bottom
                bottom: root.embedded ? parent.bottom : panelFooter.top
                left: divider.right
                right: parent.right
                topMargin: vpx(16); leftMargin: vpx(16); rightMargin: vpx(16)
            }

            property var currentEntry: {
                if (configListView.currentIndex < 0 || configListView.currentIndex >= root.configEntries.length)
                    return null
                    return root.configEntries[configListView.currentIndex]
            }

            Text {
                id: rightTitle
                anchors { top: parent.top; left: parent.left; right: parent.right }
                text: rightPane.currentEntry ? rightPane.currentEntry.label : ""
                color: themeManager.color("textPrimary")
                font { family: fontManager.currentFont; pixelSize: vpx(20); bold: true }
                wrapMode: Text.WordWrap
                maximumLineCount: 4
                elide: Text.ElideRight
            }

            Text {
                id: rightDesc
                anchors {
                    top: rightTitle.bottom; topMargin: vpx(4)
                    left: parent.left; right: parent.right
                }
                text: rightPane.currentEntry ? (rightPane.currentEntry.description || "") : ""
                color: themeManager.color("textSecondary")
                font { family: fontManager.currentFont; pixelSize: vpx(13) }
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: 2
            }

            Rectangle {
                id: ratioMenuButton
                anchors {
                    top: rightDesc.bottom
                    topMargin: vpx(20)
                    left: parent.left
                    right: parent.horizontalCenter
                    rightMargin: vpx(8)
                }
                height: vpx(50)
                radius: vpx(10)
                color: activeFocus ? themeManager.color("surfaceHover") : themeManager.color("surface")
                border {
                    width: vpx(1)
                    color: activeFocus ? themeManager.color("accent") : themeManager.color("border")
                }
                focus: root.focusSection === "ratio"
                KeyNavigation.right: fillMenuButton

                Keys.onPressed: {
                    if (api.keys.isAccept(event) || event.key === Qt.Key_Return) {
                        event.accepted = true
                        ratioMenu.open()
                        return
                    }
                    if (api.keys.isCancel(event) || event.key === Qt.Key_Left) {
                        event.accepted = true
                        root.focusSection = "list"
                        configListView.forceActiveFocus()
                        return
                    }
                }

                property string currentKey: {
                    return rightPane.currentEntry
                    ? root._getRatioFor(rightPane.currentEntry.key, rightPane.currentEntry.isVirtual)
                    : ""
                }

                Column {
                    anchors {
                        left: parent.left
                        leftMargin: vpx(16)
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: vpx(4)

                    Text {
                        text: "Aspect Ratio"
                        color: themeManager.color("textSecondary")
                        font { family: fontManager.currentFont; pixelSize: vpx(12) }
                    }

                    Text {
                        text: {
                            var k = ratioMenuButton.currentKey
                            if (k && k.indexOf("custom:") === 0) return root.ratioLabels["custom"] || "Custom"
                                return root.ratioLabels[k] !== undefined ? root.ratioLabels[k] : (k === "" ? "Auto" : k)
                        }
                        color: themeManager.color("textPrimary")
                        font { family: fontManager.currentFont; pixelSize: vpx(20); bold: true }
                    }
                }

                Image {
                    anchors {
                        right: parent.right
                        rightMargin: vpx(16)
                        verticalCenter: parent.verticalCenter
                    }
                    source: "assets/icon/arrow-right.svg"
                    width: vpx(16)
                    height: vpx(16)
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: themeManager.color("iconPrimary")
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        ratioMenuButton.forceActiveFocus()
                        root.focusSection = "ratio"
                        ratioMenu.isOpen ? ratioMenu.close() : ratioMenu.open()
                    }
                }
            }

            Rectangle {
                id: fillMenuButton
                anchors {
                    top: rightDesc.bottom
                    topMargin: vpx(20)
                    left: parent.horizontalCenter
                    leftMargin: vpx(8)
                    right: parent.right
                }
                height: vpx(50)
                radius: vpx(10)
                color: activeFocus ? themeManager.color("surfaceHover") : themeManager.color("surface")
                border {
                    width: vpx(1)
                    color: activeFocus ? themeManager.color("accent") : themeManager.color("border")
                }
                KeyNavigation.left: ratioMenuButton

                Keys.onPressed: {
                    if (api.keys.isAccept(event) || event.key === Qt.Key_Return) {
                        event.accepted = true
                        fillMenu.open()
                        return
                    }
                    if (api.keys.isCancel(event)) {
                        event.accepted = true
                        root.focusSection = "list"
                        configListView.forceActiveFocus()
                        return
                    }
                }

                property string currentFill: {
                    return rightPane.currentEntry ? root._getFillFor(rightPane.currentEntry.key) : "PreserveAspectFit"
                }

                Column {
                    anchors {
                        left: parent.left
                        leftMargin: vpx(16)
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: vpx(4)

                    Text {
                        text: "Fill Mode"
                        color: themeManager.color("textSecondary")
                        font { family: fontManager.currentFont; pixelSize: vpx(12) }
                    }

                    Text {
                        text: root.fillLabels[fillMenuButton.currentFill] !== undefined ? root.fillLabels[fillMenuButton.currentFill] : fillMenuButton.currentFill
                        color: themeManager.color("textPrimary")
                        font { family: fontManager.currentFont; pixelSize: vpx(20); bold: true }
                    }
                }

                Image {
                    anchors {
                        right: parent.right
                        rightMargin: vpx(16)
                        verticalCenter: parent.verticalCenter
                    }
                    source: "assets/icon/arrow-right.svg"
                    width: vpx(16)
                    height: vpx(16)
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: themeManager.color("iconPrimary")
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        fillMenuButton.forceActiveFocus()
                        root.focusSection = "fill"
                        fillMenu.isOpen ? fillMenu.close() : fillMenu.open()
                    }
                }
            }

            Item {
                id: customPanel
                anchors {
                    top: ratioMenuButton.bottom
                    topMargin: vpx(5)
                    left: parent.left
                    right: parent.right
                }
                height: vpx(110)
                visible: {
                    var entry = rightPane.currentEntry
                    if (!entry) return false
                        var rk = root._getRatioFor(entry.key, entry.isVirtual)
                        return rk === "custom" || (rk && rk.indexOf("custom:") === 0)
                }

                Item {
                    id: widthInputBox
                    anchors {
                        left: parent.left
                        right: parent.horizontalCenter
                        rightMargin: vpx(6)
                        verticalCenter: parent.verticalCenter
                    }
                    height: vpx(90)

                    Text {
                        id: widthLabel
                        anchors {
                            top: parent.top
                            horizontalCenter: parent.horizontalCenter
                        }
                        text: "Width"
                        color: themeManager.color("textTertiary")
                        font { family: fontManager.currentFont; pixelSize: vpx(16) }
                    }

                    Rectangle {
                        anchors {
                            top: widthLabel.bottom
                            topMargin: vpx(4)
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        radius: vpx(10)
                        color: themeManager.color("surface")
                        border { width: vpx(2); color: themeManager.color("border") }

                        Rectangle {
                            id: widthMinusBtn
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: parent.width * 0.28
                            radius: vpx(8)
                            color: themeManager.color("surfaceHover")
                            Text {
                                anchors.centerIn: parent
                                text: "−"
                                color: themeManager.color("textSecondary")
                                font { family: global.fonts.condensed; pixelSize: vpx(22); bold: true }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var e = rightPane.currentEntry
                                    if (!e) return
                                    var w = Math.max(1, root._getCustomW(e.key) - 1)
                                    root._setCustomValue(e.key, w, root._getCustomH(e.key))
                                }
                            }
                        }

                        Text {
                            id: widthValueText
                            anchors.centerIn: parent
                            text: {
                                var e = rightPane.currentEntry
                                if (!e) return "1"
                                return "" + root._getCustomW(e.key)
                            }
                            color: themeManager.color("textPrimary")
                            font { family: global.fonts.condensed; pixelSize: vpx(28); bold: true }
                        }

                        Rectangle {
                            id: widthPlusBtn
                            anchors {
                                right: parent.right
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: parent.width * 0.28
                            radius: vpx(8)
                            color: themeManager.color("surfaceHover")
                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                color: themeManager.color("textSecondary")
                                font { family: global.fonts.condensed; pixelSize: vpx(22); bold: true }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var e = rightPane.currentEntry
                                    if (!e) return
                                    var w = Math.min(99, root._getCustomW(e.key) + 1)
                                    root._setCustomValue(e.key, w, root._getCustomH(e.key))
                                }
                            }
                        }
                    }
                }

                Item {
                    id: heightInputBox
                    anchors {
                        left: parent.horizontalCenter
                        leftMargin: vpx(6)
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    height: vpx(90)

                    Text {
                        id: heightLabel
                        anchors {
                            top: parent.top
                            horizontalCenter: parent.horizontalCenter
                        }
                        text: "Height"
                        color: themeManager.color("textTertiary")
                        font { family: fontManager.currentFont; pixelSize: vpx(16) }
                    }

                    Rectangle {
                        anchors {
                            top: heightLabel.bottom
                            topMargin: vpx(4)
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        radius: vpx(10)
                        color: themeManager.color("surface")
                        border { width: vpx(2); color: themeManager.color("border") }

                        Rectangle {
                            id: heightMinusBtn
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: parent.width * 0.28
                            radius: vpx(8)
                            color: themeManager.color("surfaceHover")
                            Text {
                                anchors.centerIn: parent
                                text: "−"
                                color: themeManager.color("textSecondary")
                                font { family: global.fonts.condensed; pixelSize: vpx(22); bold: true }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var e = rightPane.currentEntry
                                    if (!e) return
                                    var h = Math.max(1, root._getCustomH(e.key) - 1)
                                    root._setCustomValue(e.key, root._getCustomW(e.key), h)
                                }
                            }
                        }

                        Text {
                            id: heightValueText
                            anchors.centerIn: parent
                            text: {
                                var e = rightPane.currentEntry
                                if (!e) return "1"
                                return "" + root._getCustomH(e.key)
                            }
                            color: themeManager.color("textPrimary")
                            font { family: global.fonts.condensed; pixelSize: vpx(28); bold: true }
                        }

                        Rectangle {
                            id: heightPlusBtn
                            anchors {
                                right: parent.right
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: parent.width * 0.28
                            radius: vpx(8)
                            color: themeManager.color("surfaceHover")
                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                color: themeManager.color("textSecondary")
                                font { family: global.fonts.condensed; pixelSize: vpx(22); bold: true }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var e = rightPane.currentEntry
                                    if (!e) return
                                    var h = Math.min(99, root._getCustomH(e.key) + 1)
                                    root._setCustomValue(e.key, root._getCustomW(e.key), h)
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: previewArea
                anchors {
                    top: customPanel.bottom
                    topMargin: customPanel.visible ? vpx(20) : vpx(10)
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    bottomMargin: vpx(8)
                }

                Text {
                    id: previewLabel
                    anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                    text: "Preview"
                    color: themeManager.color("textTertiary")
                    font { family: fontManager.currentFont; pixelSize: vpx(16) }
                }

                Item {
                    id: previewFrame
                    anchors {
                        top: previewLabel.bottom
                        topMargin: vpx(10)
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: parent.width * 0.65

                    property string _rawKey: {
                        return rightPane.currentEntry
                        ? root._getRatioFor(rightPane.currentEntry.key, rightPane.currentEntry.isVirtual)
                        : ""
                    }
                    property string rKey: {
                        if (_rawKey && _rawKey.indexOf("custom:") === 0)
                            return _rawKey.substring(7)
                            return _rawKey
                    }
                    property bool isCustomMode: _rawKey === "custom" || (_rawKey && _rawKey.indexOf("custom:") === 0)

                    property string fKey: {
                        return rightPane.currentEntry ? root._getFillFor(rightPane.currentEntry.key) : "PreserveAspectFit"
                    }
                    property real previewW: {
                        var key = rKey
                        var maxW = width * 0.85
                        var maxH = height * 0.85
                        if (key === "" || key === "custom") {
                            var wAuto = maxW * 0.63 / 0.85
                            var hAuto = wAuto * 1.3
                            if (hAuto > maxH) { hAuto = maxH; wAuto = hAuto / 1.3 }
                            return wAuto
                        }
                        var parts = key.split(":")
                        if (parts.length !== 2) return Math.min(maxW * 0.74, maxH / 1.3)
                            var wR = parseFloat(parts[0]); var hR = parseFloat(parts[1])
                            if (hR <= 0 || isNaN(wR) || isNaN(hR)) return Math.min(maxW * 0.74, maxH / 1.3)
                                var fromW = maxW; var fromH = maxW * (hR / wR)
                                if (fromH > maxH) { fromH = maxH; fromW = maxH * (wR / hR) }
                                return fromW
                    }
                    property real previewH: {
                        var key = rKey
                        var maxH = height * 0.85
                        if (key === "" || key === "custom") {
                            var h = previewW * 1.3
                            return Math.min(h, maxH)
                        }
                        var parts = key.split(":")
                        if (parts.length !== 2) return Math.min(previewW * 1.3, maxH)
                            var wR = parseFloat(parts[0]); var hR = parseFloat(parts[1])
                            if (wR <= 0 || isNaN(wR) || isNaN(hR)) return Math.min(previewW * 1.3, maxH)
                                return Math.min(previewW * (hR / wR), maxH)
                    }

                    Rectangle {
                        id: previewRect
                        anchors.centerIn: parent
                        width: previewFrame.previewW
                        height: previewFrame.previewH
                        radius: width * 0.04
                        color: themeManager.color("surfaceElevated")
                        border {
                            width: Math.max(1, width * 0.012)
                            color: themeManager.color("accent")
                        }
                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

                        Text {
                            anchors {
                                horizontalCenter: parent.horizontalCenter
                                top: parent.top
                                topMargin: parent.height * 0.08
                            }
                            text: {
                                var rk = previewFrame._rawKey
                                if (rk === "") return "AUTO"
                                    if (rk && rk.indexOf("custom:") === 0) return rk.substring(7)
                                        return rk.toUpperCase()
                            }
                            color: themeManager.color("textPrimary")
                            opacity: 0.6
                            font {
                                family: global.fonts.condensed
                                pixelSize: previewRect.width * 0.14
                                bold: true
                            }
                        }

                        Rectangle {
                            anchors {
                                bottom: parent.bottom
                                horizontalCenter: parent.horizontalCenter
                                bottomMargin: vpx(5)
                            }
                            width: parent.width * 0.95
                            height: parent.height * 0.18
                            radius: vpx(5)
                            color: themeManager.color("surfaceHighlight")

                            Text {
                                anchors.centerIn: parent
                                text: root.fillLabels[previewFrame.fKey] || previewFrame.fKey
                                color: themeManager.color("textSecondary")
                                font {
                                    family: global.fonts.condensed
                                    pixelSize: previewRect.width * 0.09
                                    bold: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: ratioMenu
        anchors.fill: parent
        visible: false
        z: 200

        property bool isOpen: false
        property var anchorItem: ratioMenuButton

        function open() {
            if (isOpen) return
                isOpen = true
                visible = true
                ratioMenuList.currentIndex = _getCurrentRatioIndex()
                Qt.callLater(function() {
                    ratioMenuList.forceActiveFocus()
                    ratioMenuList.positionViewAtIndex(ratioMenuList.currentIndex, ListView.Center)
                })
        }

        function close() {
            if (!isOpen) return
                isOpen = false
                visible = false
                root.focusSection = "ratio"
                ratioMenuButton.forceActiveFocus()
        }

        function toggle() {
            if (isOpen) close()
                else open()
        }

        function _getCurrentRatioIndex() {
            var entry = rightPane.currentEntry
            if (!entry) return 0
                var current = root._getRatioFor(entry.key, entry.isVirtual)
                if (current && current.indexOf("custom:") === 0) {
                    for (var j = 0; j < root.ratioKeys.length; j++) {
                        if (root.ratioKeys[j] === "custom") return j
                    }
                }
                for (var i = 0; i < root.ratioKeys.length; i++) {
                    if (root.ratioKeys[i] === current) return i
                }
                return 0
        }

        Rectangle {
            id: ratioMenuContainer

            property point _mapped: ratioMenu.anchorItem && ratioMenu.isOpen
            ? ratioMenu.anchorItem.mapToItem(root, 0, 0)
            : Qt.point(root.width / 2, root.height / 2)

            property real _anchorBottomY: _mapped.y + (ratioMenu.anchorItem ? ratioMenu.anchorItem.height : 0)
            property real _anchorTopY: _mapped.y

            x: {
                var rawX = _mapped.x
                var adjustedX = rawX
                if (adjustedX + width > root.width - vpx(8))
                    adjustedX = root.width - width - vpx(8)
                    if (adjustedX < vpx(8))
                        adjustedX = vpx(8)
                        return adjustedX
            }

            y: {
                var targetY = _anchorBottomY + vpx(4)
                if (targetY + height > root.height - vpx(8)) {
                    targetY = _anchorTopY - height - vpx(4)
                }
                return Math.max(vpx(8), Math.min(targetY, root.height - height - vpx(1)))
            }

            width: vpx(220)
            height: vpx(250)
            radius: vpx(5)
            clip: true
            color: themeManager.color("surfaceElevated")
            border { width: vpx(2); color: themeManager.color("borderLight") }

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: vpx(4)
                radius: vpx(16)
                samples: 32
                color: "#40000000"
                source: ratioMenuContainer
            }

            opacity: ratioMenu.isOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            ListView {
                    id: ratioMenuList
                    anchors.fill: parent
                    anchors.margins: vpx(2)
                    clip: true
                    focus: ratioMenu.isOpen
                    keyNavigationWraps: true
                    spacing: vpx(2)
                    boundsBehavior: Flickable.StopAtBounds

                    model: root.ratioKeys

                    delegate: Rectangle {
                        width: ratioMenuList.width
                        height: vpx(60)
                        radius: vpx(5)

                        property bool isCurrent: ListView.isCurrentItem

                        color: isCurrent ? themeManager.color("surfaceHover") : themeManager.color("surfaceElevated")
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                            }
                            width: isCurrent ? vpx(3) : 0
                            height: vpx(20)
                            radius: vpx(6)
                            color: themeManager.color("accent")
                            Behavior on width { NumberAnimation { duration: 160 } }
                        }

                        Column {
                            anchors {
                                left: parent.left
                                leftMargin: vpx(12)
                                right: parent.right
                                rightMargin: vpx(28)
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: vpx(2)

                            Text {
                                text: root.ratioLabels[modelData] !== undefined ? root.ratioLabels[modelData] : (modelData === "" ? "Auto" : modelData)
                                color: isCurrent ? themeManager.color("textPrimary") : themeManager.color("textSecondary")
                                font {
                                    family: fontManager.currentFont
                                    pixelSize: vpx(18)
                                    weight: isCurrent ? Font.DemiBold : Font.Normal
                                }
                                elide: Text.ElideRight
                            }

                            Text {
                                text: {
                                    if (modelData === "") return "Auto"
                                        if (modelData === "custom") return "Custom"
                                            if (modelData === "1:1") return "Square"
                                                if (modelData === "4:3") return "Classic"
                                                    if (modelData === "3:4") return "Portrait"
                                                        if (modelData === "8:7") return "NDS"
                                                            if (modelData === "3:5") return "PSP"
                                                                if (modelData === "2:3") return "Box"
                                                                    return ""
                                }
                                color: themeManager.color("textTertiary")
                                font { family: fontManager.currentFont; pixelSize: vpx(16) }
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: ratioMenuList.currentIndex = index
                            onClicked: {
                                var entry = rightPane.currentEntry
                                if (entry) {
                                    root._setRatioFor(entry.key, modelData)
                                    ratioMenu.close()
                                }
                            }
                        }
                    }

                    Keys.onUpPressed: {
                        if (currentIndex > 0) {
                            decrementCurrentIndex()
                            positionViewAtIndex(currentIndex, ListView.Contain)
                        }
                        event.accepted = true
                    }

                    Keys.onDownPressed: {
                        if (currentIndex < root.ratioKeys.length - 1) {
                            incrementCurrentIndex()
                            positionViewAtIndex(currentIndex, ListView.Contain)
                        }
                        event.accepted = true
                    }

                    Keys.onPressed: {
                        if (api.keys.isAccept(event)) {
                            event.accepted = true
                            var entry = rightPane.currentEntry
                            if (entry) {
                                root._setRatioFor(entry.key, root.ratioKeys[currentIndex])
                                ratioMenu.close()
                            }
                            return
                        }
                        if (api.keys.isCancel(event)) {
                            event.accepted = true
                            ratioMenu.close()
                            return
                        }
                    }
            }
        }
    }

    Item {
        id: fillMenu
        anchors.fill: parent
        visible: false
        z: 200

        property bool isOpen: false
        property var anchorItem: fillMenuButton

        function open() {
            if (isOpen) return
                isOpen = true
                visible = true
                fillMenuList.currentIndex = _getCurrentFillIndex()
                Qt.callLater(function() {
                    fillMenuList.forceActiveFocus()
                    fillMenuList.positionViewAtIndex(fillMenuList.currentIndex, ListView.Center)
                })
        }

        function close() {
            if (!isOpen) return
                isOpen = false
                visible = false
                root.focusSection = "ratio"
                fillMenuButton.forceActiveFocus()
        }

        function toggle() {
            if (isOpen) close()
                else open()
        }

        function _getCurrentFillIndex() {
            var entry = rightPane.currentEntry
            if (!entry) return 0
                var current = root._getFillFor(entry.key)
                for (var i = 0; i < root.fillKeys.length; i++) {
                    if (root.fillKeys[i] === current) return i
                }
                return 0
        }

        Rectangle {
            id: fillMenuContainer

            property point _mapped: fillMenu.anchorItem && fillMenu.isOpen
            ? fillMenu.anchorItem.mapToItem(root, 0, 0)
            : Qt.point(root.width / 2, root.height / 2)

            property real _anchorBottomY: _mapped.y + (fillMenu.anchorItem ? fillMenu.anchorItem.height : 0)
            property real _anchorTopY: _mapped.y

            x: {
                var rawX = _mapped.x
                var adjustedX = rawX
                if (adjustedX + width > root.width - vpx(8))
                    adjustedX = root.width - width - vpx(8)
                    if (adjustedX < vpx(8))
                        adjustedX = vpx(8)
                        return adjustedX
            }

            y: {
                var targetY = _anchorBottomY + vpx(4)
                if (targetY + height > root.height - vpx(8)) {
                    targetY = _anchorTopY - height - vpx(4)
                }
                return Math.max(vpx(8), Math.min(targetY, root.height - height - vpx(1)))
            }

            width: vpx(210)
            height: vpx(205)
            radius: vpx(5)
            color: themeManager.color("surfaceElevated")
            border { width: vpx(2); color: themeManager.color("borderLight") }

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: vpx(4)
                radius: vpx(16)
                samples: 32
                color: "#40000000"
                source: fillMenuContainer
            }

            opacity: fillMenu.isOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            ListView {
                    id: fillMenuList
                    anchors.fill: parent
                    anchors.margins: vpx(2)
                    clip: true
                    focus: fillMenu.isOpen
                    keyNavigationWraps: true
                    spacing: vpx(2)
                    boundsBehavior: Flickable.StopAtBounds

                    model: root.fillKeys

                    delegate: Rectangle {
                        width: fillMenuList.width
                        height: vpx(60)
                        radius: vpx(6)

                        property bool isCurrent: ListView.isCurrentItem

                        color: isCurrent ? themeManager.color("surfaceHover") : themeManager.color("surfaceElevated")
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                            }
                            width: isCurrent ? vpx(3) : 0
                            height: vpx(20)
                            radius: vpx(2)
                            color: themeManager.color("accent")
                            Behavior on width { NumberAnimation { duration: 160 } }
                        }

                        Column {
                            anchors {
                                left: parent.left
                                leftMargin: vpx(12)
                                right: parent.right
                                rightMargin: vpx(28)
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: vpx(2)

                            Text {
                                text: root.fillLabels[modelData] !== undefined ? root.fillLabels[modelData] : modelData
                                color: isCurrent ? themeManager.color("textPrimary") : themeManager.color("textSecondary")
                                font {
                                    family: fontManager.currentFont
                                    pixelSize: vpx(18)
                                    weight: isCurrent ? Font.DemiBold : Font.Normal
                                }
                                elide: Text.ElideRight
                            }

                            Text {
                                text: {
                                    if (modelData === "PreserveAspectFit") return "Fit"
                                        if (modelData === "Stretch") return "Stretch"
                                            if (modelData === "PreserveAspectCrop") return "Crop"
                                                return ""
                                }
                                color: themeManager.color("textTertiary")
                                font { family: fontManager.currentFont; pixelSize: vpx(16) }
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: fillMenuList.currentIndex = index
                            onClicked: {
                                var entry = rightPane.currentEntry
                                if (entry) {
                                    root._setFillFor(entry.key, modelData)
                                    fillMenu.close()
                                }
                            }
                        }
                    }

                    Keys.onUpPressed: {
                        if (currentIndex > 0) {
                            decrementCurrentIndex()
                            positionViewAtIndex(currentIndex, ListView.Contain)
                        }
                        event.accepted = true
                    }

                    Keys.onDownPressed: {
                        if (currentIndex < root.fillKeys.length - 1) {
                            incrementCurrentIndex()
                            positionViewAtIndex(currentIndex, ListView.Contain)
                        }
                        event.accepted = true
                    }

                    Keys.onPressed: {
                        if (api.keys.isAccept(event)) {
                            event.accepted = true
                            var entry = rightPane.currentEntry
                            if (entry) {
                                root._setFillFor(entry.key, root.fillKeys[currentIndex])
                                fillMenu.close()
                            }
                            return
                        }
                        if (api.keys.isCancel(event)) {
                            event.accepted = true
                            fillMenu.close()
                            return
                        }
                    }
            }
        }
    }
}
