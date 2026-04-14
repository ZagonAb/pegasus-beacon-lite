import QtQuick 2.15
import QtGraphicalEffects 1.15
import "utils.js" as Utils

FocusScope {
    id: root

    property var gameModel
    property int currentGameIndex: 0
    property bool hasFocus: false
    property var collectionEntry: null
    property var ratioMap: ({})
    property var fillMap: ({})

    readonly property string activeRatio: {
        var _map = ratioMap
        var entry = collectionEntry
        if (!entry) return ""
            var key = entry.isVirtual ? "virtual" : (entry.shortName || entry.name || "")
            if (key !== "" && _map.hasOwnProperty(key)) return _map[key]
                return entry.isVirtual ? "2:3" : ""
    }

    readonly property string activeFillMode: {
        var _fmap = fillMap
        var entry = collectionEntry
        if (!entry) return "PreserveAspectFit"
            var key = entry.isVirtual ? "virtual" : (entry.shortName || entry.name || "")
            if (key !== "" && _fmap.hasOwnProperty(key)) return _fmap[key]
                return "PreserveAspectFit"
    }

    readonly property int activeFillModeEnum: {
        var m = activeFillMode
        if (m === "Stretch")            return Image.Stretch
            if (m === "PreserveAspectCrop") return Image.PreserveAspectCrop
                return Image.PreserveAspectFit
    }

    readonly property bool backdropEnabled: activeRatio !== ""
    readonly property bool isFourThreeRatio: activeRatio === "4:3"
    readonly property int cellPadding: isFourThreeRatio ? vpx(14) : vpx(14)

    signal gameSelected(var game)
    signal focusRequested()
    signal nextCollectionRequested()
    signal prevCollectionRequested()
    signal contextMenuRequested(var game)

    function restoreFocus() { grid.forceActiveFocus() }

    readonly property int cornerRadius: vpx(12)
    readonly property int columns: 5
    property bool _acceptHeld: false

    Timer {
        id: longPressTimer
        interval: 600
        repeat: false
        onTriggered: {
            root._acceptHeld = false
            var g = grid.model.get ? grid.model.get(grid.currentIndex)
            : grid.model[grid.currentIndex]
            if (g) root.contextMenuRequested(g)
        }
    }

    function isItemSelected(index) {
        return index === root.currentGameIndex && root.activeFocus
    }

    Item {
        anchors.fill: parent
        clip: true

        GridView {
            id: grid
            anchors {
                fill: parent
                leftMargin: vpx(18)
                rightMargin: vpx(18)
                topMargin: vpx(16)
                bottomMargin: vpx(26)
            }

            cellWidth: Math.floor(width / root.columns)
            cellHeight: root.isFourThreeRatio
            ? Math.floor(cellWidth * 0.75)
            : Utils.gridCellHeight(cellWidth, root.activeRatio)

            clip: false
            focus: true
            currentIndex: root.currentGameIndex

            onCurrentIndexChanged: root.currentGameIndex = currentIndex
            model: root.gameModel

            Keys.onPressed: {
                if (event.key === Qt.Key_Left || event.key === Qt.Key_Right ||
                    event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                    if (typeof soundManager !== 'undefined') {
                        soundManager.playNavigation()
                    }
                    }

                    if (api.keys.isAccept(event)) {
                        event.accepted = true
                        if (event.isAutoRepeat) {
                            if (!longPressTimer.running && root._acceptHeld) {
                                longPressTimer.restart()
                            }
                        } else {
                            if (!root._acceptHeld) {
                                longPressTimer.restart()
                                root._acceptHeld = true
                            }
                        }
                        return
                    }
                    if (api.keys.isNextPage(event)) {
                        event.accepted = true
                        if (typeof soundManager !== 'undefined') {
                            soundManager.playCollection()
                        }
                        root.nextCollectionRequested()
                        return
                    }
                    if (api.keys.isPrevPage(event)) {
                        event.accepted = true
                        if (typeof soundManager !== 'undefined') {
                            soundManager.playCollection()
                        }
                        root.prevCollectionRequested()
                        return
                    }
            }

            Keys.onReleased: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                    event.accepted = true
                    longPressTimer.stop()
                    if (root._acceptHeld) {
                        root._acceptHeld = false
                        var g = model.get ? model.get(currentIndex) : model[currentIndex]
                        if (g) root.gameSelected(g)
                    }
                }
            }

            delegate: Item {
                id: cell
                width: grid.cellWidth
                height: grid.cellHeight

                property bool isActive: GridView.isCurrentItem && root.activeFocus
                property var game: modelData

                onIsActiveChanged: {
                    if (isActive) reflectionContainer.startAnimation()
                        else          reflectionContainer.stopAnimation()
                }

                Item {
                    id: paddedContainer
                    anchors {
                        centerIn: parent
                        margins: root.cellPadding / 2
                    }
                    width: parent.width - root.cellPadding
                    height: parent.height - root.cellPadding

                    Item {
                        id: imageContainer
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height

                        layer.enabled: root.backdropEnabled
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: imageContainer.width
                                height: imageContainer.height
                                radius: root.cornerRadius
                            }
                        }

                        Image {
                            id: backdropSource
                            anchors.fill: parent
                            source: root.backdropEnabled && cell.game ? (cell.game.assets.boxFront || "") : ""
                            fillMode: Image.PreserveAspectCrop
                            smooth: true; asynchronous: true; visible: false
                        }

                        FastBlur {
                            anchors.fill: parent; source: backdropSource; radius: 48; cached: true
                            visible: root.backdropEnabled && backdropSource.status === Image.Ready
                        }

                        Rectangle {
                            anchors.fill: parent; color: "#000000"; opacity: 0.38
                            visible: root.backdropEnabled && backdropSource.status === Image.Ready
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: root.backdropEnabled ? 0 : root.cornerRadius
                            color: "#1E1E1E"
                            visible: boxImage.status !== Image.Ready

                            Item {
                                anchors.centerIn: parent
                                width: parent.width * 0.3
                                height: parent.width * 0.3

                                Image {
                                    id: noImageIcon
                                    anchors.fill: parent
                                    source: "assets/icon/no-image.svg"
                                    fillMode: Image.PreserveAspectFit
                                    mipmap: true
                                    visible: false
                                }

                                ColorOverlay {
                                    anchors.fill: noImageIcon
                                    source: noImageIcon
                                    color: themeManager.color("iconSecondary")
                                }
                            }

                            Text {
                                anchors {
                                    bottom: parent.bottom
                                    bottomMargin: vpx(12)
                                    horizontalCenter: parent.horizontalCenter
                                }
                                text: cell.game ? cell.game.title.charAt(0).toUpperCase() : ""
                                color: themeManager.color("textTertiary")
                                font { family: global.fonts.condensed; pixelSize: vpx(32); bold: true }
                                visible: true
                            }
                        }

                        Item {
                            id: gameArtContainer
                            anchors.centerIn: parent
                            width: boxImage.width > 0 ? boxImage.width : parent.width
                            height: boxImage.height > 0 ? boxImage.height : parent.height

                            Image {
                                id: boxImage
                                anchors.centerIn: parent
                                source: cell.game ? (cell.game.assets.boxFront || "") : ""
                                fillMode: root.activeFillModeEnum
                                smooth: true; asynchronous: true; visible: false

                                onSourceChanged: { if (status === Image.Ready) updateSize() }
                                onStatusChanged: { if (status === Image.Ready) updateSize() }

                                Connections {
                                    target: root
                                    function onActiveRatioChanged() {
                                        if (boxImage.status === Image.Ready) boxImage.updateSize()
                                    }
                                    function onActiveFillModeEnumChanged() {
                                        if (boxImage.status === Image.Ready) boxImage.updateSize()
                                    }
                                }

                                function updateSize() {
                                    var cW = imageContainer.width
                                    var cH = imageContainer.height
                                    if (root.activeFillMode === "Stretch") {
                                        width = cW; height = cH; return
                                    }
                                    if (root.activeFillMode === "PreserveAspectCrop") {
                                        width = cW; height = cH; return
                                    }

                                    if (root.activeRatio !== "") {
                                        var fit = Utils.fitToRatio(cW, cH, root.activeRatio)
                                        width = fit.width; height = fit.height
                                    } else {
                                        var iW = implicitWidth; var iH = implicitHeight
                                        if (iW <= 0 || iH <= 0) return
                                            var r = Math.min(cW / iW, cH / iH)
                                            width = iW * r; height = iH * r
                                    }
                                }
                            }

                            Rectangle {
                                id: maskRect
                                anchors.centerIn: parent
                                width: boxImage.width  > 0 ? boxImage.width : parent.width
                                height: boxImage.height > 0 ? boxImage.height : parent.height
                                radius: root.backdropEnabled ? vpx(4) : root.cornerRadius
                                visible: false
                            }

                            OpacityMask {
                                anchors.centerIn: parent
                                width: maskRect.width; height: maskRect.height
                                source: boxImage; maskSource: maskRect; cached: true
                            }

                            ReflectionEffect {
                                id: reflectionContainer
                                anchors.fill: parent
                                cornerRadius: root.cornerRadius
                            }

                            Item {
                                id: imageOverlay
                                anchors.fill: parent

                                Rectangle {
                                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                    height: vpx(80); radius: root.backdropEnabled ? vpx(4) : root.cornerRadius
                                    opacity: cell.isActive ? 1.0 : 0.0
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 1.0; color: "#E8000000" }
                                    }
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }

                                Row {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        bottom: parent.bottom
                                        leftMargin: vpx(8)
                                        rightMargin: vpx(8)
                                        bottomMargin: vpx(8)
                                    }
                                    spacing: vpx(6)
                                    opacity: cell.isActive ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }

                                    Item {
                                        id: favoriteIconWrapper
                                        width: vpx(22)
                                        height: vpx(22)
                                        visible: cell.game ? cell.game.favorite === true : false
                                        anchors.verticalCenter: parent.verticalCenter

                                        Image {
                                            id: favoriteIcon
                                            anchors.fill: parent
                                            source: "assets/icon/favorite-on.svg"
                                            fillMode: Image.PreserveAspectFit
                                            mipmap: true
                                            visible: false
                                        }

                                        ColorOverlay {
                                            anchors.fill: favoriteIcon
                                            source: favoriteIcon
                                            color: themeManager.effectiveAccentColor
                                        }
                                    }

                                    Text {
                                        width: parent.width - (favoriteIconWrapper.visible ? favoriteIconWrapper.width + parent.spacing : 0)
                                        text: cell.game ? cell.game.title : ""
                                        color: themeManager.effectiveAccentColor
                                        font { family: fontManager.currentFont; pixelSize: vpx(22); bold: true }
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 4
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: activeBorder
                            anchors.centerIn: parent
                            width: gameArtContainer.width + vpx(10)
                            height: gameArtContainer.height + vpx(10)
                            radius: root.cornerRadius + vpx(5); color: "transparent"
                            border { width: vpx(3); color: themeManager.effectiveAccentColor }
                            opacity: (!root.backdropEnabled && cell.isActive) ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }

                    Rectangle {
                        id: activeBorderBackdrop
                        anchors.centerIn: imageContainer
                        width: imageContainer.width + vpx(4); height: imageContainer.height + vpx(4)
                        radius: root.cornerRadius + vpx(5); color: "transparent"
                        border { width: vpx(3); color: themeManager.effectiveAccentColor }
                        visible: root.backdropEnabled
                        opacity: (root.backdropEnabled && cell.isActive) ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }

                transform: Scale {
                    origin.x: cell.width / 2; origin.y: cell.height / 2
                    xScale: cell.isActive ? 1.01 : 1.0; yScale: cell.isActive ? 1.01 : 1.0
                    Behavior on xScale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    Behavior on yScale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                }

                MouseArea {
                    anchors.fill: parent

                    property bool longPressTriggered: false
                    property int pressX: 0
                    property int pressY: 0

                    Timer {
                        id: longPressTimer
                        interval: 600
                        repeat: false
                        onTriggered: {
                            if (!parent.longPressTriggered) {
                                parent.longPressTriggered = true
                                root.contextMenuRequested(cell.game)
                            }
                        }
                    }

                    onPressed: {
                        longPressTriggered = false
                        pressX = mouse.x
                        pressY = mouse.y
                        longPressTimer.start()
                    }

                    onReleased: {
                        longPressTimer.stop()

                        if (!longPressTriggered &&
                            Math.abs(mouse.x - pressX) < 10 &&
                            Math.abs(mouse.y - pressY) < 10) {
                            grid.currentIndex = index
                            root.focusRequested()
                            }
                            longPressTriggered = false
                    }

                    onPositionChanged: {
                        if (Math.abs(mouse.x - pressX) > 15 || Math.abs(mouse.y - pressY) > 15) {
                            longPressTimer.stop()
                        }
                    }

                    onCanceled: {
                        longPressTimer.stop()
                        longPressTriggered = false
                    }

                    onClicked: {
                        if (longPressTriggered) {
                            longPressTriggered = false
                            mouse.accepted = true
                        }
                    }

                    onDoubleClicked: {
                        longPressTimer.stop()
                        if (!longPressTriggered) {
                            root.gameSelected(cell.game)
                        }
                        longPressTriggered = false
                    }
                }
            }
        }
    }
}
