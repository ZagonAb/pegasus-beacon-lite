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
        "PreserveAspectFit": "Preserve Aspect Fit",
        "Stretch": "Stretch",
        "PreserveAspectCrop": "Preserve Aspect Crop"
    })

    property var configEntries: []
    property string focusSection: "list"

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
        var copy = JSON.parse(JSON.stringify(ratioMap))
        copy[key] = ratioKey
        ratioMap = copy
        _saveToMemory()
    }

    function _setFillFor(key, fillKey) {
        var copy = JSON.parse(JSON.stringify(fillMap))
        copy[key] = fillKey
        fillMap = copy
        _saveToMemory()
    }

    function _ratioIndexFor(key, isVirtual) {
        var current = _getRatioFor(key, isVirtual)
        for (var i = 0; i < ratioKeys.length; i++) {
            if (ratioKeys[i] === current) return i
        }
        return 0
    }

    function _fillIndexFor(key) {
        var current = _getFillFor(key)
        for (var i = 0; i < fillKeys.length; i++) {
            if (fillKeys[i] === current) return i
        }
        return 0
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
                    font { family: global.fonts.sans; pixelSize: vpx(22); bold: true }
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Text {
                anchors { right: parent.right; rightMargin: vpx(24); verticalCenter: parent.verticalCenter }
                text: "B  Close"
                color: themeManager.color("textSecondary")
                font { family: global.fonts.sans; pixelSize: vpx(16) }
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
                        font { family: global.fonts.sans; pixelSize: vpx(14) }
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
                        font { family: global.fonts.sans; pixelSize: vpx(14) }
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
                    font { family: global.fonts.sans; pixelSize: vpx(14) }
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
                        ratioFocusScope.forceActiveFocus()
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
                        font { family: global.fonts.sans; pixelSize: vpx(16); bold: isActive || isSelected }
                        elide: Text.ElideRight
                    }

                    Text {
                        anchors {
                            left: collectionName.left; right: parent.right; rightMargin: vpx(13)
                            bottom: parent.bottom; bottomMargin: vpx(8)
                        }
                        text: {
                            var rk = entry ? root._getRatioFor(entry.key, entry.isVirtual) : ""
                            return rk === "" ? "Auto" : rk
                        }
                        color: (isActive || isSelected) ? themeManager.color("textPrimary") : themeManager.color("textTertiary")
                        font { family: global.fonts.condensed; pixelSize: vpx(13); bold: true }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            configListView.currentIndex = index
                            root.focusSection = "ratio"
                            ratioFocusScope.forceActiveFocus()
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
                font { family: global.fonts.sans; pixelSize: vpx(20); bold: true }
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
                font { family: global.fonts.sans; pixelSize: vpx(13) }
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: 2
            }

            FocusScope {
                id: ratioFocusScope
                anchors {
                    top: rightDesc.bottom; topMargin: vpx(20)
                    left: parent.left; right: parent.right
                }
                height: vpx(80)
                focus: root.focusSection === "ratio"

                Keys.onPressed: {
                    if (api.keys.isCancel(event)) {
                        event.accepted = true
                        root.focusSection = "list"
                        configListView.forceActiveFocus()
                        return
                    }
                    if (event.key === Qt.Key_Down) {
                        event.accepted = true
                        root.focusSection = "fill"
                        fillFocusScope.forceActiveFocus()
                        return
                    }
                    if (event.key === Qt.Key_Left) {
                        event.accepted = true
                        var e1 = rightPane.currentEntry
                        if (!e1) return
                            var i1 = root._ratioIndexFor(e1.key, e1.isVirtual)
                            root._setRatioFor(e1.key, root.ratioKeys[(i1 - 1 + root.ratioKeys.length) % root.ratioKeys.length])
                            return
                    }
                    if (event.key === Qt.Key_Right) {
                        event.accepted = true
                        var e2 = rightPane.currentEntry
                        if (!e2) return
                            var i2 = root._ratioIndexFor(e2.key, e2.isVirtual)
                            root._setRatioFor(e2.key, root.ratioKeys[(i2 + 1) % root.ratioKeys.length])
                            return
                    }
                }

                Text {
                    id: ratioSectionLabel
                    anchors { top: parent.top; left: parent.left }
                    text: "Aspect Ratio"
                    color: root.focusSection === "ratio" ? themeManager.color("textPrimary") : themeManager.color("textSecondary")
                    font { family: global.fonts.sans; pixelSize: vpx(12); bold: root.focusSection === "ratio" }
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                Rectangle {
                    id: ratioSelector
                    anchors {
                        top: ratioSectionLabel.bottom; topMargin: vpx(6)
                        left: parent.left; right: parent.right
                    }
                    height: vpx(54)
                    radius: vpx(10)
                    color: root.focusSection === "ratio" ? themeManager.color("surfaceHighlight") : themeManager.color("surface")
                    border {
                        width: vpx(1)
                        color: root.focusSection === "ratio" ? themeManager.color("accent") : themeManager.color("border")
                    }
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: {
                            root.focusSection = "ratio"
                            ratioFocusScope.forceActiveFocus()
                        }
                    }

                    property string currentKey: {
                        return rightPane.currentEntry
                        ? root._getRatioFor(rightPane.currentEntry.key, rightPane.currentEntry.isVirtual)
                        : ""
                    }

                    Item {
                        id: ratioBtnLeft
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        width: vpx(48); height: vpx(48)

                        Image {
                            id: ratioLeftIcon
                            anchors.centerIn: parent
                            width: vpx(18); height: vpx(18)
                            source: "assets/icon/left.svg"
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            visible: true
                        }

                        ColorOverlay {
                            anchors.fill: ratioLeftIcon
                            source: ratioLeftIcon
                            color: root.focusSection === "ratio" ? themeManager.color("iconPrimary") : themeManager.color("iconDisabled")
                            Behavior on color { NumberAnimation { duration: 120 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.focusSection = "ratio"
                                ratioFocusScope.forceActiveFocus()
                                var e = rightPane.currentEntry
                                if (!e) return
                                    var i = root._ratioIndexFor(e.key, e.isVirtual)
                                    root._setRatioFor(e.key, root.ratioKeys[(i - 1 + root.ratioKeys.length) % root.ratioKeys.length])
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: {
                            var k = ratioSelector.currentKey
                            return root.ratioLabels[k] !== undefined ? root.ratioLabels[k] : (k === "" ? "Auto" : k)
                        }
                        color: root.focusSection === "ratio" ? themeManager.color("textPrimary") : themeManager.color("textSecondary")
                        font { family: global.fonts.sans; pixelSize: vpx(17); bold: root.focusSection === "ratio" }
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Item {
                        id: ratioBtnRight
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        width: vpx(48); height: vpx(48)

                        Image {
                            id: ratioRightIcon
                            anchors.centerIn: parent
                            width: vpx(18); height: vpx(18)
                            source: "assets/icon/right.svg"
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            visible: true
                        }

                        ColorOverlay {
                            anchors.fill: ratioRightIcon
                            source: ratioRightIcon
                            color: root.focusSection === "ratio" ? themeManager.color("iconPrimary") : themeManager.color("iconDisabled")
                            Behavior on color { NumberAnimation { duration: 120 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.focusSection = "ratio"
                                ratioFocusScope.forceActiveFocus()
                                var e = rightPane.currentEntry
                                if (!e) return
                                    var i = root._ratioIndexFor(e.key, e.isVirtual)
                                    root._setRatioFor(e.key, root.ratioKeys[(i + 1) % root.ratioKeys.length])
                            }
                        }
                    }

                    Text {
                        anchors { right: parent.right; rightMargin: vpx(50); verticalCenter: parent.verticalCenter }
                        text: "↓ Fill Mode"
                        color: root.focusSection === "ratio" ? themeManager.color("textSecondary") : "transparent"
                        font { family: global.fonts.sans; pixelSize: vpx(11) }
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }
            }

            FocusScope {
                id: fillFocusScope
                anchors {
                    top: ratioFocusScope.bottom; topMargin: vpx(14)
                    left: parent.left; right: parent.right
                }
                height: vpx(80)
                focus: root.focusSection === "fill"

                Keys.onPressed: {
                    if (api.keys.isCancel(event)) {
                        event.accepted = true
                        root.focusSection = "list"
                        configListView.forceActiveFocus()
                        return
                    }
                    if (event.key === Qt.Key_Up) {
                        event.accepted = true
                        root.focusSection = "ratio"
                        ratioFocusScope.forceActiveFocus()
                        return
                    }
                    if (event.key === Qt.Key_Left) {
                        event.accepted = true
                        var e1 = rightPane.currentEntry
                        if (!e1) return
                            var i1 = root._fillIndexFor(e1.key)
                            root._setFillFor(e1.key, root.fillKeys[(i1 - 1 + root.fillKeys.length) % root.fillKeys.length])
                            return
                    }
                    if (event.key === Qt.Key_Right) {
                        event.accepted = true
                        var e2 = rightPane.currentEntry
                        if (!e2) return
                            var i2 = root._fillIndexFor(e2.key)
                            root._setFillFor(e2.key, root.fillKeys[(i2 + 1) % root.fillKeys.length])
                            return
                    }
                }

                Text {
                    id: fillSectionLabel
                    anchors { top: parent.top; left: parent.left }
                    text: "Fill Mode"
                    color: root.focusSection === "fill" ? themeManager.color("textPrimary") : themeManager.color("textSecondary")
                    font { family: global.fonts.sans; pixelSize: vpx(12); bold: root.focusSection === "fill" }
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                Rectangle {
                    id: fillSelector
                    anchors {
                        top: fillSectionLabel.bottom; topMargin: vpx(6)
                        left: parent.left; right: parent.right
                    }
                    height: vpx(54)
                    radius: vpx(10)
                    color: root.focusSection === "fill" ? themeManager.color("surfaceHighlight") : themeManager.color("surface")
                    border {
                        width: vpx(1)
                        color: root.focusSection === "fill" ? themeManager.color("accent") : themeManager.color("border")
                    }
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: {
                            root.focusSection = "fill"
                            fillFocusScope.forceActiveFocus()
                        }
                    }

                    property string currentFill: {
                        return rightPane.currentEntry ? root._getFillFor(rightPane.currentEntry.key) : "PreserveAspectFit"
                    }

                    Item {
                        id: fillBtnLeft
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        width: vpx(48); height: vpx(48)

                        Image {
                            id: fillLeftIcon
                            anchors.centerIn: parent
                            width: vpx(18); height: vpx(18)
                            source: "assets/icon/left.svg"
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            visible: true
                        }

                        ColorOverlay {
                            anchors.fill: fillLeftIcon
                            source: fillLeftIcon
                            color: root.focusSection === "fill" ? themeManager.color("iconPrimary") : themeManager.color("iconDisabled")
                            Behavior on color { NumberAnimation { duration: 120 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.focusSection = "fill"
                                fillFocusScope.forceActiveFocus()
                                var e = rightPane.currentEntry
                                if (!e) return
                                    var i = root._fillIndexFor(e.key)
                                    root._setFillFor(e.key, root.fillKeys[(i - 1 + root.fillKeys.length) % root.fillKeys.length])
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: {
                            var k = fillSelector.currentFill
                            return root.fillLabels[k] !== undefined ? root.fillLabels[k] : k
                        }
                        color: root.focusSection === "fill" ? themeManager.color("textPrimary") : themeManager.color("textSecondary")
                        font { family: global.fonts.sans; pixelSize: vpx(17); bold: root.focusSection === "fill" }
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Item {
                        id: fillBtnRight
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        width: vpx(48); height: vpx(48)

                        Image {
                            id: fillRightIcon
                            anchors.centerIn: parent
                            width: vpx(18); height: vpx(18)
                            source: "assets/icon/right.svg"
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            visible: true
                        }

                        ColorOverlay {
                            anchors.fill: fillRightIcon
                            source: fillRightIcon
                            color: root.focusSection === "fill" ? themeManager.color("iconPrimary") : themeManager.color("iconDisabled")
                            Behavior on color { NumberAnimation { duration: 120 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.focusSection = "fill"
                                fillFocusScope.forceActiveFocus()
                                var e = rightPane.currentEntry
                                if (!e) return
                                    var i = root._fillIndexFor(e.key)
                                    root._setFillFor(e.key, root.fillKeys[(i + 1) % root.fillKeys.length])
                            }
                        }
                    }

                    Text {
                        anchors { right: parent.right; rightMargin: vpx(50); verticalCenter: parent.verticalCenter }
                        text: "↑ Aspect Ratio"
                        color: root.focusSection === "fill" ? themeManager.color("textSecondary") : "transparent"
                        font { family: global.fonts.sans; pixelSize: vpx(11) }
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }
            }

            Item {
                id: previewArea
                anchors {
                    top: fillFocusScope.bottom; topMargin: vpx(20)
                    left: parent.left; right: parent.right
                    bottom: parent.bottom; bottomMargin: vpx(8)
                }

                Text {
                    id: previewLabel
                    anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                    text: "Preview"
                    color: themeManager.color("textTertiary")
                    font { family: global.fonts.sans; pixelSize: vpx(12) }
                }

                Item {
                    id: previewFrame
                    anchors {
                        top: previewLabel.bottom; topMargin: vpx(10)
                        bottom: parent.bottom; horizontalCenter: parent.horizontalCenter
                    }
                    width: parent.width * 0.55

                    property string rKey: {
                        return rightPane.currentEntry
                        ? root._getRatioFor(rightPane.currentEntry.key, rightPane.currentEntry.isVirtual)
                        : ""
                    }
                    property string fKey: {
                        return rightPane.currentEntry ? root._getFillFor(rightPane.currentEntry.key) : "PreserveAspectFit"
                    }
                    property real previewW: {
                        if (rKey === "" || rKey === "custom") return width * 0.7
                            var parts = rKey.split(":")
                            if (parts.length !== 2) return width * 0.7
                                var wR = parseFloat(parts[0]); var hR = parseFloat(parts[1])
                                if (hR <= 0) return width * 0.7
                                    var maxW = width * 0.85; var maxH = height * 0.85
                                    var fromW = maxW; var fromH = maxW * (hR / wR)
                                    if (fromH > maxH) { fromH = maxH; fromW = maxH * (wR / hR) }
                                    return fromW
                    }
                    property real previewH: {
                        if (rKey === "" || rKey === "custom") return previewW * 1.3
                            var parts = rKey.split(":")
                            if (parts.length !== 2) return previewW * 1.3
                                var wR = parseFloat(parts[0]); var hR = parseFloat(parts[1])
                                if (wR <= 0) return previewW * 1.3
                                    return previewW * (hR / wR)
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: previewFrame.previewW; height: previewFrame.previewH
                        radius: vpx(8)
                        color: themeManager.color("surfaceElevated")
                        border { width: vpx(2); color: themeManager.color("accent") }
                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

                        Text {
                            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: vpx(10) }
                            text: previewFrame.rKey === "" ? "AUTO" : previewFrame.rKey.toUpperCase()
                            color: themeManager.color("textPrimary")
                            opacity: 0.6
                            font { family: global.fonts.condensed; pixelSize: vpx(18); bold: true }
                        }

                        Rectangle {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: parent.height * 0.28
                            radius: vpx(6)
                            color: themeManager.color("surfaceHighlight")
                            Rectangle {
                                anchors { top: parent.top; left: parent.left; right: parent.right }
                                height: vpx(1)
                                color: themeManager.color("border")
                            }
                            Text {
                                anchors.centerIn: parent
                                text: root.fillLabels[previewFrame.fKey] || previewFrame.fKey
                                color: themeManager.color("textSecondary")
                                font { family: global.fonts.condensed; pixelSize: vpx(10); bold: true }
                            }
                        }
                    }
                }
            }
        }
    }
}
