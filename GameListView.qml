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

    readonly property bool isWidescreenRatio: {
        var r = activeRatio
        return r === "8:7" || r === "1:1"
    }

    readonly property bool isFourThreeRatio: activeRatio === "4:3"

    readonly property int featuredW_fourThree: vpx(500)
    readonly property int thumbW_fourThree: vpx(320)

    readonly property int featuredW: {
        if (isFourThreeRatio) return featuredW_fourThree
            if (isWidescreenRatio) return featuredW_landscape
                return featuredW_portrait
    }

    readonly property int thumbW: {
        if (isFourThreeRatio) return thumbW_fourThree
            if (isWidescreenRatio) return thumbW_landscape
                return thumbW_portrait
    }

    signal gameSelected(var game)
    signal focusRequested()
    signal nextCollectionRequested()
    signal prevCollectionRequested()
    signal contextMenuRequested(var game)

    function restoreFocus() { carousel.forceActiveFocus() }

    function restorePosition() {
        var idx = root.currentGameIndex
        if (idx <= 0) return
        carousel.highlightMoveDuration = 0
        carousel.positionViewAtIndex(idx, ListView.Beginning)
        Qt.callLater(function() {
            carousel.highlightMoveDuration = 220
        })
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            Qt.callLater(restorePosition)
        })
    }

    readonly property int cornerRadius: vpx(14)
    property bool _acceptHeld: false

    Timer {
        id: longPressTimer
        interval: 600
        repeat:   false
        onTriggered: {
            root._acceptHeld = false
            var g = carousel.model.get ? carousel.model.get(carousel.currentIndex)
                                       : carousel.model[carousel.currentIndex]
            if (g) root.contextMenuRequested(g)
        }
    }

    readonly property int featuredW_portrait: vpx(250)
    readonly property int thumbW_portrait: vpx(180)
    readonly property int featuredW_landscape: vpx(380)
    readonly property int thumbW_landscape: vpx(240)
    readonly property var _heights: Utils.listViewHeights(featuredW, thumbW, activeRatio)
    readonly property int featuredH: _heights.featuredH
    readonly property int thumbH: _heights.thumbH

    ListView {
        id: carousel
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: vpx(30) }
        height: root.featuredH + vpx(24)

        orientation: ListView.Horizontal
        snapMode: ListView.SnapToItem
        highlightMoveDuration: 220
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: vpx(48)
        preferredHighlightEnd: vpx(48) + root.featuredW
        clip: false; focus: true
        currentIndex: root.currentGameIndex
        spacing: vpx(24)
        model: root.gameModel

        onCurrentIndexChanged: root.currentGameIndex = currentIndex

        Keys.onPressed: {
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
            if (api.keys.isNextPage(event)) { event.accepted = true; root.nextCollectionRequested(); return }
            if (api.keys.isPrevPage(event))  { event.accepted = true; root.prevCollectionRequested(); return }
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
            id: card
            property bool isActive: ListView.isCurrentItem
            property var game: modelData

            width: card.isActive ? root.featuredW : root.thumbW
            height: carousel.height
            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

            onIsActiveChanged: {
                if (isActive) reflectionContainer.startAnimation()
                else          reflectionContainer.stopAnimation()
            }

            Item {
                id: imageContainer
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                width: card.isActive ? root.featuredW : root.thumbW
                height: card.isActive ? root.featuredH : root.thumbH
                Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

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
                    source: root.backdropEnabled && card.game ? (card.game.assets.boxFront || "") : ""
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
                    color: "#1C1C1C"
                    visible: cardImage.status !== Image.Ready

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
                            bottomMargin: vpx(8)
                            horizontalCenter: parent.horizontalCenter
                        }
                        text: card.game ? card.game.title.charAt(0).toUpperCase() : ""
                        color: themeManager.color("textTertiary")
                        font { family: global.fonts.condensed; pixelSize: vpx(28); bold: true }
                        visible: true
                    }
                }

                Item {
                    id: gameArtContainer
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: cardImage.width > 0 ? cardImage.width : parent.width
                    height: cardImage.height > 0 ? cardImage.height : parent.height

                    Image {
                        id: cardImage
                        anchors.centerIn: parent
                        source: card.game ? (card.game.assets.boxFront || "") : ""
                        fillMode: root.activeFillModeEnum
                        smooth: true; asynchronous: true; visible: false

                        onSourceChanged: { if (status === Image.Ready) updateSize() }
                        onStatusChanged: { if (status === Image.Ready) updateSize() }

                        Connections {
                            target: imageContainer
                            function onWidthChanged()  { if (cardImage.status === Image.Ready) cardImage.updateSize() }
                            function onHeightChanged() { if (cardImage.status === Image.Ready) cardImage.updateSize() }
                        }

                        Connections {
                            target: root
                            function onActiveRatioChanged() {
                                if (cardImage.status === Image.Ready) cardImage.updateSize()
                            }
                            function onActiveFillModeEnumChanged() {
                                if (cardImage.status === Image.Ready) cardImage.updateSize()
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
                        id: cardMask
                        anchors.centerIn: parent
                        width: cardImage.width  > 0 ? cardImage.width  : parent.width
                        height: cardImage.height > 0 ? cardImage.height : parent.height
                        radius: root.backdropEnabled ? vpx(4) : root.cornerRadius
                        visible: false
                    }

                    OpacityMask {
                        anchors.centerIn: parent
                        width: cardMask.width; height: cardMask.height
                        source: cardImage; maskSource: cardMask; cached: true
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
                            anchors.fill: parent
                            radius: root.backdropEnabled ? vpx(4) : root.cornerRadius
                            color: "#000000"
                            opacity: card.isActive ? 0.0 : 0.45
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }
                }

                Rectangle {
                    id: activeBorder
                    anchors.top: parent.top; anchors.topMargin: -vpx(5)
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: gameArtContainer.width + vpx(10); height: gameArtContainer.height + vpx(10)
                    radius: root.cornerRadius + vpx(5); color: "transparent"
                    border { width: vpx(2); color: themeManager.color("accent") }
                    opacity: (!root.backdropEnabled && card.isActive) ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }

            Rectangle {
                id: activeBorderBackdrop
                anchors.top: imageContainer.top; anchors.topMargin: -vpx(5)
                anchors.horizontalCenter: imageContainer.horizontalCenter
                width: imageContainer.width + vpx(4); height: imageContainer.height + vpx(10)
                radius: root.cornerRadius + vpx(5); color: "transparent"
                border { width: vpx(2); color: themeManager.color("accent") }
                visible: root.backdropEnabled
                opacity: (root.backdropEnabled && card.isActive) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
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
                            root.contextMenuRequested(card.game)
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
                        carousel.currentIndex = index
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
                        root.gameSelected(card.game)
                    }
                    longPressTriggered = false
                }
            }
        }
    }
}
