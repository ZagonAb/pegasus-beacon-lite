import QtQuick 2.15
import QtGraphicalEffects 1.15

FocusScope {
    id: root

    property var gameModel
    property int currentGameIndex: 0
    property var collectionEntry:  null
    property var ratioMap: ({})
    property var fillMap: ({})

    signal gameSelected(var game)
    signal focusRequested()
    signal nextCollectionRequested()
    signal prevCollectionRequested()
    signal contextMenuRequested(var game)

    function restoreFocus() { flick.forceActiveFocus() }

    property bool _acceptHeld: false

    Timer {
        id: longPressTimer
        interval: 600
        repeat:   false
        onTriggered: {
            root._acceptHeld = false
            var g = root.gameModel.get ? root.gameModel.get(root.currentGameIndex)
                                       : root.gameModel[root.currentGameIndex]
            if (g) root.contextMenuRequested(g)
        }
    }
    readonly property real availW: width - vpx(64)
    readonly property real bSize: Math.floor(availW / 7.5)
    readonly property real bSizeAlt: bSize
    readonly property real hGap:  vpx(150)
    readonly property real rowStep: Math.ceil((bSize + bSizeAlt) / 2) - vpx(10)
    readonly property real padLeft: vpx(32)

    readonly property int gameCount: {
        if (!gameModel) return 0
            if (gameModel.count !== undefined) return gameModel.count
                if (gameModel.length !== undefined) return gameModel.length
                    return 0
    }

    property real animatedOffsetX: 0
    property real animatedOffsetY: 0
    property real animatedRotation: 0
    property int animatingIndex: -1
    property var imageSourceMap: ({})
    property int _loadIdx: -1
    property int _maxVisibleItems: 100

    Timer {
        id: loadTimer
        interval: 50
        repeat: true
        running: false

        onTriggered: {
            if (root._loadIdx >= Math.min(root.gameCount, root._maxVisibleItems)) {
                loadTimer.stop()
                if (root._maxVisibleItems < root.gameCount) {
                    lazyLoadTimer.start()
                }
                return
            }

            var idx = root._loadIdx
            var game = root.gameModel.get ? root.gameModel.get(idx) : root.gameModel[idx]
            var url = (game && game.assets && game.assets.boxFront) ? game.assets.boxFront : ""

            var m = root.imageSourceMap
            m[idx] = url
            root.imageSourceMap = m
            root._loadIdx++
        }
    }

    Timer {
        id: lazyLoadTimer
        interval: 100
        repeat: true
        running: false

        onTriggered: {
            if (root._loadIdx >= root.gameCount) {
                lazyLoadTimer.stop()
                return
            }

            var idx = root._loadIdx
            var game = root.gameModel.get ? root.gameModel.get(idx) : root.gameModel[idx]
            var url = (game && game.assets && game.assets.boxFront) ? game.assets.boxFront : ""

            var m = root.imageSourceMap
            m[idx] = url
            root.imageSourceMap = m
            root._loadIdx++
        }
    }

    function _startPrioritizedLoad() {
        loadTimer.stop()
        lazyLoadTimer.stop()
        root.imageSourceMap = ({})
        root._loadIdx = 0
        root._maxVisibleItems = Math.min(root.gameCount, 80)
        if (root.gameCount > 0)
            loadTimer.start()
    }

    onGameModelChanged: {
        root.currentGameIndex = 0
        Qt.callLater(_startPrioritizedLoad)
    }
    onGameCountChanged: Qt.callLater(_startPrioritizedLoad)
    Component.onCompleted: Qt.callLater(_startPrioritizedLoad)

    function animateSelection(index) {
        animatingIndex = index
        offsetAnimRestart()
    }

    SequentialAnimation {
        id: offsetAnim
        running: false

        ParallelAnimation {
            SpringAnimation {
                target: root
                property: "animatedOffsetX"
                from: 12
                to: 0
                spring: 9.0
                damping: 1.2
                epsilon: 0.5
                duration: 100
            }
            SpringAnimation {
                target: root
                property: "animatedOffsetY"
                from: 30
                to: 0
                spring: 9.0
                damping: 1.2
                epsilon: 0.5
                duration: 70
            }
            NumberAnimation {
                target: root
                property: "animatedRotation"
                from: 10
                to: 0
                duration: 100
                easing.type: Easing.OutQuad
            }
        }
    }

    function offsetAnimRestart() {
        animatedOffsetX = 12
        animatedOffsetY = 10
        animatedRotation = 8
        offsetAnim.stop()
        offsetAnim.start()
    }

    function layoutOf(idx) {
        var pair = Math.floor(idx / 7)
        var rem  = idx % 7
        if (rem < 3) return { row: pair*2, col: rem, rowType: 3 }
        else return { row: pair*2 + 1, col: rem - 3, rowType: 4 }
    }

    function bubbleCX(lo) {
        var d = (lo.rowType === 3) ? bSize : bSizeAlt
        if (lo.rowType === 3) {
            var tw = 3*d + 2*hGap
            return padLeft + (availW - tw)/2 + d/2 + lo.col*(d + hGap)
        }
        var tw4 = 4*d + 3*hGap
        return padLeft + (availW - tw4)/2 + d/2 + lo.col*(d + hGap)
    }

    function bubbleCY(lo) {
        var d = (lo.rowType === 3) ? bSize : bSizeAlt
        return vpx(20) + lo.row * rowStep + d/2
    }

    function totalContentH() {
        if (gameCount === 0) return height
            var lo = layoutOf(gameCount - 1)
            var d = (lo.rowType === 3) ? bSize : bSizeAlt
            return bubbleCY(lo) + d/2 + vpx(100)
    }

    function neighborIn(fromIdx, dir) {
        var lo = layoutOf(fromIdx)
        var best = -1
        var bestD = 1e9

        var startRow = Math.max(0, lo.row - 2)
        var endRow = Math.min(Math.floor(gameCount / 3.5) + 1, lo.row + 3)

        for (var i = 0; i < gameCount; i++) {
            if (i === fromIdx) continue
                var lo2 = layoutOf(i)

                if (lo2.row < startRow || lo2.row > endRow) continue

                    var cx = bubbleCX(lo)
                    var cy = bubbleCY(lo)
                    var dx = bubbleCX(lo2) - cx
                    var dy = bubbleCY(lo2) - cy

                    var ok = false

                    if (dir === "up" && dy < -rowStep*0.25 && Math.abs(dx) < bSize*1.8) ok = true
                        else if (dir === "down" && dy > rowStep*0.25 && Math.abs(dx) < bSize*1.8) ok = true
                            else if (dir === "left" && dx < -bSize*0.25 && lo2.row === lo.row) ok = true
                                else if (dir === "right" && dx > bSize*0.25 && lo2.row === lo.row) ok = true

                                    if (ok) {
                                        var d2 = dx*dx + dy*dy
                                        if (d2 < bestD) { bestD = d2; best = i }
                                    }
        }
        return best
    }

    function ensureVisible(idx) {
        var lo = layoutOf(idx)
        var d = (lo.rowType === 3) ? bSize : bSizeAlt
        var cy = bubbleCY(lo)
        var top = cy - d/2 - vpx(24)
        var bottom = cy + d/2 + vpx(24)
        if (top < flick.contentY)
            flick.contentY = Math.max(0, top)
            else if (bottom > flick.contentY + flick.height)
                flick.contentY = bottom - flick.height
    }

    onCurrentGameIndexChanged: {
        animateSelection(currentGameIndex)
        Qt.callLater(function() {
            if (activeCanvas) activeCanvas.requestPaint()
        })
    }

    Item {
        anchors.fill: parent
        clip: true

        Flickable {
            id: flick
            anchors.fill: parent
            contentWidth: width
            contentHeight: root.totalContentH()
            flickableDirection: Flickable.VerticalFlick
            interactive: true
            focus: true
            boundsBehavior: Flickable.StopAtBounds

            Behavior on contentY {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }

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
                if (api.keys.isPrevPage(event)) { event.accepted = true; root.prevCollectionRequested(); return }

                var next = -1
                if (api.keys.isUp(event)) next = root.neighborIn(root.currentGameIndex, "up")
                    if (api.keys.isDown(event)) next = root.neighborIn(root.currentGameIndex, "down")
                        if (api.keys.isLeft(event)) next = root.neighborIn(root.currentGameIndex, "left")
                            if (api.keys.isRight(event)) next = root.neighborIn(root.currentGameIndex, "right")
                                if (next >= 0) {
                                    event.accepted = true
                                    root.currentGameIndex = next
                                    root.ensureVisible(next)
                                }
            }

            Keys.onReleased: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                    event.accepted = true
                    longPressTimer.stop()
                    if (root._acceptHeld) {
                        root._acceptHeld = false
                        var g = root.gameModel.get ? root.gameModel.get(root.currentGameIndex)
                                                   : root.gameModel[root.currentGameIndex]
                        if (g) root.gameSelected(g)
                    }
                }
            }

            Item {
                id: contentArea
                width: flick.width
                height: flick.contentHeight

                Canvas {
                    id: bgCanvas
                    x: 0
                    y: flick.contentY
                    width: flick.width
                    height: flick.height
                    renderStrategy: Canvas.Cooperative

                    Connections {
                        target: flick
                        function onContentYChanged() { bgCanvas.requestPaint() }
                    }

                    Connections {
                        target: root
                        function onGameCountChanged() { bgCanvas.requestPaint() }
                    }

                    Connections {
                        target: themeManager
                        function onCurrentThemeChanged() { activeCanvas.requestPaint() }
                    }

                    function drawBubbleEffect(ctx, cx, cy, r) {
                        ctx.save()

                        var isDarkTheme = themeManager.currentTheme === "dark"
                        var shadowColor = isDarkTheme ? "rgba(255,255,255,0.25)" : "rgba(0,0,0,0.35)"
                        var shineColor = isDarkTheme ? "rgba(255,255,255,0.15)" : "rgba(255,255,255,0.45)"
                        var bubbleColor = isDarkTheme ? "rgba(30,30,40,0.7)" : "rgba(245,245,250,0.7)"

                        // Sombra del borde
                        var edgeShadow = ctx.createRadialGradient(cx, cy, r * 0.6, cx, cy, r)
                        edgeShadow.addColorStop(0, "rgba(0,0,0,0)")
                        edgeShadow.addColorStop(1, shadowColor)
                        ctx.fillStyle = edgeShadow
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, 0, Math.PI * 2)
                        ctx.fill()

                        var shine = ctx.createRadialGradient(cx - r*0.15, cy - r*0.2, 0, cx - r*0.15, cy - r*0.2, r * 0.55)
                        shine.addColorStop(0, shineColor)
                        shine.addColorStop(1, "rgba(255,255,255,0)")
                        ctx.fillStyle = shine
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, 0, Math.PI * 2)
                        ctx.fill()

                        ctx.restore()
                    }

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        ctx.save()
                        ctx.translate(0, -flick.contentY)

                        var viewTop    = flick.contentY
                        var viewBottom = viewTop + flick.height
                        var margin     = vpx(200)

                        for (var i = 0; i < root.gameCount; i++) {
                            var lo = root.layoutOf(i)
                            var r  = ((lo.rowType === 3) ? root.bSize : root.bSizeAlt) / 2
                            var cy = root.bubbleCY(lo)

                            if (cy + r + margin >= viewTop && cy - r - margin <= viewBottom) {
                                var cx = root.bubbleCX(lo)
                                drawBubbleEffect(ctx, cx, cy, r)
                            }
                        }

                        ctx.restore()
                    }
                }

                Canvas {
                    id: activeCanvas
                    x: 0
                    y: flick.contentY
                    width: flick.width
                    height: flick.height

                    Connections {
                        target: root
                        function onCurrentGameIndexChanged() { activeCanvas.requestPaint() }
                        function onActiveFocusChanged()      { activeCanvas.requestPaint() }
                        function onAnimatedOffsetXChanged()  { activeCanvas.requestPaint() }
                        function onAnimatedOffsetYChanged()  { activeCanvas.requestPaint() }
                        function onAnimatedRotationChanged() { activeCanvas.requestPaint() }
                    }
                    Connections {
                        target: flick
                        function onContentYChanged() { activeCanvas.requestPaint() }
                    }

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        if (!root.activeFocus) return

                            ctx.save()
                            ctx.translate(0, -flick.contentY)

                            var lo = root.layoutOf(root.currentGameIndex)
                            var r  = ((lo.rowType === 3) ? root.bSize : root.bSizeAlt) / 2
                            var cx = root.bubbleCX(lo) + root.animatedOffsetX
                            var cy = root.bubbleCY(lo) + root.animatedOffsetY

                            ctx.strokeStyle = themeManager.color("accent")
                            ctx.lineWidth = 3
                            ctx.beginPath()
                            ctx.arc(cx, cy, r + 2, 0, Math.PI * 2)
                            ctx.stroke()

                            ctx.restore()
                    }
                }

                Repeater {
                    id: gameRepeater
                    model: root.gameModel

                    delegate: Loader {
                        id: bubbleLoader

                        property int itemIndex: index

                        active: {
                            if (!root.gameModel) return false
                                var lo = root.layoutOf(itemIndex)
                                var d = (lo.rowType === 3) ? root.bSize : root.bSizeAlt
                                var cy = root.bubbleCY(lo)
                                var viewTop = flick.contentY
                                var viewBottom = viewTop + flick.height
                                var margin = vpx(300)
                                return (cy + d/2 + margin >= viewTop && cy - d/2 - margin <= viewBottom)
                        }

                        sourceComponent: bubbleComponent
                        onLoaded: {
                            item.gameData = modelData
                            item.itemIdx = index
                        }
                    }
                }
            }
        }
    }

    Component {
        id: bubbleComponent

        Item {
            id: bubbleItem

            property var gameData
            property int itemIdx: -1

            property var lo: root.layoutOf(itemIdx)
            property real d: (lo.rowType === 3) ? root.bSize : root.bSizeAlt
            property real cx: root.bubbleCX(lo)
            property real cy: root.bubbleCY(lo)
            property bool isActive: root.currentGameIndex === itemIdx && root.activeFocus

            x: cx - d/2 + (isActive ? root.animatedOffsetX : 0)
            y: cy - d/2 + (isActive ? root.animatedOffsetY : 0)
            width: d
            height: d
            transformOrigin: Item.Center
            rotation: isActive ? root.animatedRotation : 0

            onIsActiveChanged: {
                if (isActive) reflectionWrapper.startAnimation()
                else          reflectionWrapper.stopAnimation()
            }

            Item {
                id: clippedContainer
                anchors.fill: parent

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: clippedContainer.width
                        height: clippedContainer.height
                        radius: width / 2
                    }
                }

                Rectangle {
                    id: bgCircle
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"

                    Item {
                        anchors.centerIn: parent
                        width: parent.width * 0.35
                        height: parent.width * 0.35

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
                            bottomMargin: parent.height * 0.1
                            horizontalCenter: parent.horizontalCenter
                        }
                        text: gameData ? gameData.title.charAt(0).toUpperCase() : ""
                        color: themeManager.color("textTertiary")
                        font {
                            pixelSize: parent.width * 0.2
                            bold: true
                        }
                        visible: true
                    }
                }

                Image {
                    id: coverImage
                    anchors.fill: parent
                    source: root.imageSourceMap[itemIdx] || ""
                    sourceSize.width: 128
                    sourceSize.height: 128
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                    cache: true

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            if (maskLayer.visible) maskLayer.requestPaint()
                        }
                    }
                }

                OpacityMask {
                    id: maskLayer
                    anchors.fill: parent
                    source: coverImage
                    maskSource: Rectangle {
                        width: maskLayer.width
                        height: maskLayer.height
                        radius: width / 2
                    }
                    visible: coverImage.status === Image.Ready && coverImage.source !== ""
                }

                ReflectionEffect {
                    id: reflectionWrapper
                    anchors.fill: parent
                }
            }

            Row {
                anchors {
                    left: parent.left
                    leftMargin: vpx(5)
                    right: parent.right
                    rightMargin: parent.width * 0.11
                    verticalCenter: parent.verticalCenter
                }
                spacing: parent.width * 0.05
                visible: isActive

                Image {
                    id: favoriteIcon
                    width: parent.parent.width * 0.18
                    height: parent.parent.width * 0.18
                    source: "assets/icon/favorite-on.svg"
                    visible: gameData ? gameData.favorite === true : false
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    width: parent.width - (favoriteIcon.visible ? favoriteIcon.width + parent.spacing : 0)
                    text: gameData ? gameData.title : ""
                    color: "#FFFFFF"
                    font {
                        family: global.fonts.sans
                        pixelSize: vpx(20)
                        bold: true
                    }
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    maximumLineCount: 4
                    elide: Text.ElideRight

                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 0
                        verticalOffset: 0
                        radius: 12
                        samples: 17
                        color: "#000000"
                        spread: 0.3
                    }
                }
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
                            root.contextMenuRequested(gameData)
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
                        root.currentGameIndex = itemIdx
                        root.ensureVisible(itemIdx)
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
                        root.gameSelected(gameData)
                    }
                    longPressTriggered = false
                }
            }

            Component.onDestruction: {
                coverImage.source = ""
            }
        }
    }
}
