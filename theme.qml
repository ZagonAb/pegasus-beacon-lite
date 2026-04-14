import QtQuick 2.15
import QtQuick.Layouts 1.15
import SortFilterProxyModel 0.2
import QtGraphicalEffects 1.15
import QtMultimedia 5.15
import "utils.js" as Utils

FocusScope {
    id: root

    property int currentCollectionIndex: 0
    property int currentGameIndex: 0
    property int viewMode: 0
    property bool gridModeActive: viewMode === 1
    property bool searchActive: false
    property string searchText: ""

    readonly property var searchCollectionEntry: ({
        isVirtual: true,
        virtualType: "search",
        shortName: "virtual",
        name: "Search"
    })

    readonly property var searchResultModel: {
        var t = searchText.trim().toLowerCase()
        if (t === "" || !searchActive) return []
            var results = []
            for (var i = 0; i < api.allGames.count; i++) {
                var g = api.allGames.get(i)
                if (g && g.title && g.title.toLowerCase().indexOf(t) !== -1)
                    results.push(g)
            }
            return results
    }

    property var ratioMap: ({})
    property var fillMap: ({})
    property var collectionOrder: []
    property string backgroundStyle: "background"

    CollectionModel { id: collectionModel }

    property var fullCollectionList: collectionModel.buildFullList(collectionOrder)
    property var activeCollectionEntry: {
        if (!fullCollectionList || fullCollectionList.length === 0) return null
            var entry = fullCollectionList[currentCollectionIndex]
            return entry !== undefined ? entry : null
    }

    property var activeGameModel: {
        if (!activeCollectionEntry) return api.allGames
            if (activeCollectionEntry.isVirtual) {
                var vm = collectionModel.gamesForVirtual(activeCollectionEntry.virtualType)
                return vm !== undefined ? vm : api.allGames
            }
            var col = api.collections.get(activeCollectionEntry.realIndex)
            return col ? col.games : api.allGames
    }

    ThemeManager { id: themeManager }
    FontManager  { id: fontManager  }
    SoundManager { id: soundManager  }

    property string currentTheme: themeManager.currentTheme

    Connections {
        target: themeManager
        function onThemeChanged() {
            root.currentTheme = themeManager.currentTheme
        }
    }

    function _loadRatioMapFromMemory() {
        var saved = api.memory.get("arConfig")
        if (saved !== undefined && saved !== null) {
            if (typeof saved === "object")
                root.ratioMap = JSON.parse(JSON.stringify(saved))
                else if (typeof saved === "string") {
                    try { root.ratioMap = JSON.parse(saved) } catch(e) { root.ratioMap = {} }
                }
        }
        var savedFill = api.memory.get("fillConfig")
        if (savedFill !== undefined && savedFill !== null) {
            if (typeof savedFill === "object")
                root.fillMap = JSON.parse(JSON.stringify(savedFill))
                else if (typeof savedFill === "string") {
                    try { root.fillMap = JSON.parse(savedFill) } catch(e) { root.fillMap = {} }
                }
        }
    }

    function _loadCollectionOrder() {
        var count = api.collections.count
        var saved = api.memory.get("collectionOrder")
        if (saved && Array.isArray(saved) && saved.length === count) {
            var copy = saved.slice().sort(function(a, b) { return a - b })
            var valid = true
            for (var i = 0; i < count; i++) {
                if (copy[i] !== i) { valid = false; break }
            }
            if (valid) {
                collectionOrder = saved.slice()
                return
            }
        }
        var def = []
        for (var j = 0; j < count; j++) def.push(j)
            collectionOrder = def
            api.memory.set("collectionOrder", def)
    }

    function _loadBackgroundStyle() {
        var saved = api.memory.get("backgroundStyle")
        if (saved === "hills" || saved === "background" || saved === "screenshot" ||
            saved === "ps-symbols" || saved === "firefly" || saved === "pegasus" ||
            saved === "video")
            root.backgroundStyle = saved
            else
                root.backgroundStyle = "background"
    }

    function getWaveColors(baseColor, isDark) {
        if (themeManager.accentColorName === "default") {
            if (isDark) return ["#525252", "#383838", "#242424"]
                else return ["#C0C0C0", "#A0A0A0", "#808080"]
        }
        if (isDark) {
            return [
                Qt.lighter(baseColor, 1.4),
                baseColor,
                Qt.darker(baseColor, 1.4)
            ]
        } else {
            return [
                Qt.lighter(baseColor, 1.2),
                baseColor,
                Qt.darker(baseColor, 1.2)
            ]
        }
    }

    property var _waveColors: getWaveColors(themeManager.accentColorValue, themeManager.currentTheme === "dark")

    Connections {
        target: themeManager
        function onAccentColorChanged() {
            _waveColors = getWaveColors(themeManager.accentColorValue, themeManager.currentTheme === "dark")
        }
        function onThemeChanged() {
            _waveColors = getWaveColors(themeManager.accentColorValue, themeManager.currentTheme === "dark")
        }
    }

    function _findCollectionIndex(realIdx, virtualType) {
        var list = root.fullCollectionList
        for (var i = 0; i < list.length; i++) {
            var e = list[i]
            if (realIdx >= 0 && !e.isVirtual && e.realIndex === realIdx)
                return i
                if (virtualType !== "" && e.isVirtual && e.virtualType === virtualType)
                    return i
        }
        return 0
    }

    Timer {
        id: clearStateTimer
        interval: 1500
        repeat: false
        onTriggered: {
            api.memory.unset("collectionIndex")
            api.memory.unset("gameIndex")
            api.memory.unset("gameTitle")
        }
    }

    function _findGameIndexByTitle(title) {
        var model = root.activeGameModel
        if (!model || !title) return -1
            var count = model.count !== undefined ? model.count : (model.length || 0)
            for (var i = 0; i < count; i++) {
                var g = model.get ? model.get(i) : model[i]
                if (g && g.title === title) return i
            }
            return -1
    }

    Component.onCompleted: {
        _loadRatioMapFromMemory()
        _loadCollectionOrder()
        _loadBackgroundStyle()
        var savedCol = api.memory.get("collectionIndex")
        var savedGame = api.memory.get("gameIndex")
        var savedTitle = api.memory.get("gameTitle")
        var savedMode = api.memory.get("viewMode")
        if (savedCol !== undefined && fullCollectionList.length > 0)
            currentCollectionIndex = Math.max(0, Math.min(savedCol, fullCollectionList.length - 1))
            if (savedMode !== undefined) viewMode = savedMode
                if (savedTitle !== undefined && savedTitle !== "") {
                    Qt.callLater(function() {
                        var idx = _findGameIndexByTitle(savedTitle)
                        currentGameIndex = (idx >= 0) ? idx : 0
                    })
                } else if (savedGame !== undefined) {
                    currentGameIndex = savedGame
                }
                if (savedCol !== undefined || savedGame !== undefined || savedTitle !== undefined) {
                    clearStateTimer.start()
                } else {
                }
                root.forceActiveFocus()
    }

    function persistState() {
        var entry = root.activeCollectionEntry
        api.memory.set("collectionIndex", currentCollectionIndex)
        api.memory.set("viewMode", viewMode)
        if (entry && entry.isVirtual) {
            var model = root.activeGameModel
            var g = model ? (model.get ? model.get(currentGameIndex) : model[currentGameIndex]) : null
            if (g && g.title) {
                api.memory.set("gameTitle", g.title)
                api.memory.unset("gameIndex")
            }
        } else {
            api.memory.set("gameIndex", currentGameIndex)
            api.memory.unset("gameTitle")
        }
    }

    function toggleView() {
        viewMode = (viewMode + 1) % 4
        persistState()
        Qt.callLater(function() { _refocusActiveView() })
    }

    function _refocusActiveView() {
        if (configOpen || contextMenuOpen || searchActive) return
            var loaders = [listViewLoader, gridViewLoader, bubblesLoader, detailListLoader]
            var l = loaders[viewMode]
            if (l && l.item) l.item.forceActiveFocus()
                else root.forceActiveFocus()
    }

    function _giveViewFocusFromSearch(resetToIndex0) {
        if (configOpen || contextMenuOpen) return
            if (resetToIndex0) root.currentGameIndex = 0
                var loaders = [listViewLoader, gridViewLoader, bubblesLoader, detailListLoader]
                var l = loaders[viewMode]
                if (l && l.item) l.item.forceActiveFocus()
                    else root.forceActiveFocus()
    }

    function goNextCollection() {
        var next = Math.min(root.fullCollectionList.length - 1, root.currentCollectionIndex + 1)
        if (next !== root.currentCollectionIndex) {
            root.currentCollectionIndex = next
            root.currentGameIndex = 0
        }
    }

    function goPrevCollection() {
        var prev = Math.max(0, root.currentCollectionIndex - 1)
        if (prev !== root.currentCollectionIndex) {
            root.currentCollectionIndex = prev
            root.currentGameIndex = 0
        }
    }

    function openSettings() {
        footerViewMenu.close()
        settingsLoader.active = true
    }

    function openSearch() {
        footerViewMenu.close()
        searchText = ""
        searchActive = true
        Qt.callLater(function() { searchInput.forceActiveFocus() })
    }

    function closeSearch() {
        searchInput.text = ""
        searchActive = false
        searchText = ""
        Qt.callLater(function() { root._refocusActiveView() })
    }

    readonly property bool configOpen: settingsLoader.active
    property bool contextMenuOpen: false
    property var _activeViewItem: null

    Rectangle { anchors.fill: parent; color: "transparent" }

    Item {
        id: bgArea
        anchors.fill: parent

        property alias _bgA: _bgA
        property alias _bgB: _bgB

        property var currentGame: {
            var model = (root.searchActive && root.searchText.trim() !== "")
            ? root.searchResultModel
            : root.activeGameModel
            if (!model) return null
                if (model.get) return model.get(root.currentGameIndex)
                    var arr = model
                    return (arr && arr.length) ? arr[root.currentGameIndex] : null
        }

        readonly property string _resolvedSrc: {
            var game = currentGame
            if (!game) return ""
                if (_isShaderMode) return ""
                    if (_isVideoMode) return ""
                        if (root.backgroundStyle === "screenshot")
                            return game.assets.screenshot || ""
                            return game.assets.background || game.assets.screenshot || ""
        }

        readonly property string _videoSrc: {
            var game = currentGame
            if (!game) {
                console.log("[bgArea] No current game")
                return ""
            }

            console.log("[bgArea] Current game:", game.title)
            console.log("[bgArea] assets.video:", game.assets.video)
            console.log("[bgArea] assets.videoList:", game.assets.videoList)

            if (game.assets.video) {
                console.log("[bgArea] Found video:", game.assets.video)
                return game.assets.video
            }
            if (game.assets.videoList && game.assets.videoList.length > 0) {
                console.log("[bgArea] Found videoList[0]:", game.assets.videoList[0])
                return game.assets.videoList[0]
            }

            console.log("[bgArea] No video found")
            return ""
        }

        readonly property bool _isShaderMode: {
            var s = root.backgroundStyle
            return s === "hills" || s === "ps-symbols" || s === "firefly" || s === "pegasus"
        }

        readonly property bool _isVideoMode: root.backgroundStyle === "video"

        property bool _showA: true

        Component {
            id: compHills
            HillsShaderEffect {
                anchors.fill: parent
                theme: themeManager.currentTheme === "light" ? 1.0 : 0.0
            }
        }

        Component {
            id: compPlay
            PlayShaderEffect {
                anchors.fill: parent
                theme: themeManager.currentTheme === "light" ? 1.0 : 0.0
            }
        }

        Component {
            id: compFirefly
            FireflyShaderEffect {
                anchors.fill: parent
                theme: themeManager.currentTheme === "light" ? 1.0 : 0.0
            }
        }

        Component {
            id: compPegasus
            PegasusShaderEffect {
                anchors.fill: parent
                theme: themeManager.currentTheme === "light" ? 1.0 : 0.0
            }
        }

        Component {
            id: compVideoBackground

            Item {
                anchors.fill: parent

                property alias videoPlayer: videoPlayer

                Timer {
                    id: videoRevealTimer
                    interval: 500
                    repeat: false
                    onTriggered: {
                        videoPlayer.opacity = 1.0
                    }
                }

                Rectangle {
                    id: baseBg
                    anchors.fill: parent
                    color: themeManager.currentTheme === "dark" ? "#0D0D0D" : "#E8ECEF"
                }

                Image {
                    id: fallbackImage
                    anchors.fill: parent
                    source: bgArea.currentGame
                    ? (bgArea.currentGame.assets.background || bgArea.currentGame.assets.screenshot || "")
                    : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true

                    opacity: videoPlayer.playbackState === MediaPlayer.PlayingState ? 0.0 : 1.0
                    Behavior on opacity {
                        NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
                    }
                }

                Video {
                    id: videoPlayer
                    anchors.fill: parent
                    fillMode: VideoOutput.PreserveAspectCrop
                    loops: MediaPlayer.Infinite
                    autoPlay: false
                    muted: true
                    volume: 0
                    visible: source !== ""

                    opacity: 0.0

                    onStatusChanged: {
                        if (status === MediaPlayer.Loaded) {
                            play()
                            firstFrameTimer.start()
                        } else if (status === MediaPlayer.NoMedia || status === MediaPlayer.InvalidMedia) {
                            opacity = 0.0
                            videoRevealTimer.stop()
                            firstFrameTimer.stop()
                        }
                    }

                    onErrorChanged: {
                        if (error !== MediaPlayer.NoError) {
                            opacity = 0.0
                        }
                    }

                    onSourceChanged: {
                        opacity = 0.0
                        videoRevealTimer.stop()
                        firstFrameTimer.stop()
                    }

                    onPlaybackStateChanged: {
                        if (playbackState === MediaPlayer.PlayingState) {
                        } else if (playbackState === MediaPlayer.StoppedState) {
                            opacity = 0.0
                        }
                    }
                }

                Timer {
                    id: firstFrameTimer
                    interval: 50
                    repeat: false
                    onTriggered: {
                        if (videoPlayer.playbackState === MediaPlayer.PlayingState) {
                            console.log("[Video] Primer frame renderizado - haciendo fade in")
                            fadeInAnimation.start()
                        }
                    }
                }

                PropertyAnimation {
                    id: fadeInAnimation
                    target: videoPlayer
                    property: "opacity"
                    to: 1.0
                    duration: 500
                    easing.type: Easing.InOutQuad
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: themeManager.currentTheme === "dark" ? "#CC000000" : "#CCFFFFFF" }
                        GradientStop { position: 0.5; color: themeManager.currentTheme === "dark" ? "#55000000" : "#55FFFFFF" }
                        GradientStop { position: 1.0; color: themeManager.currentTheme === "dark" ? "#CC000000" : "#CCFFFFFF" }
                    }
                }
            }
        }

        Loader {
            id: shaderLoader
            anchors.fill: parent
            active: bgArea._isShaderMode

            sourceComponent: {
                switch (root.backgroundStyle) {
                    case "hills": return compHills
                    case "ps-symbols": return compPlay
                    case "firefly": return compFirefly
                    case "pegasus": return compPegasus
                    default: return null
                }
            }

            onLoaded: {
                if (root.backgroundStyle === "hills" && item) {
                    item.waveColor1 = _waveColors[0]
                    item.waveColor2 = _waveColors[1]
                    item.waveColor3 = _waveColors[2]
                    var isDefault = themeManager.accentColorName === "default"
                    item.waveOpacity1 = isDefault ? 1.0 : 0.15
                    item.waveOpacity2 = isDefault ? 1.0 : 0.25
                    item.waveOpacity3 = isDefault ? 1.0 : 0.35
                }
                if (root.backgroundStyle === "ps-symbols" && item) {
                    item.accentColor = themeManager.effectiveAccentColor
                }
                if (root.backgroundStyle === "firefly" && item) {
                    item.accentColor = themeManager.effectiveAccentColor
                }
                if (root.backgroundStyle === "pegasus" && item) {
                    item.accentColor = themeManager.effectiveAccentColor
                }
            }

            opacity: active && item ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        Loader {
            id: videoLoader
            anchors.fill: parent
            active: bgArea._isVideoMode
            sourceComponent: compVideoBackground

            onLoaded: {
                if (bgArea._videoSrc !== "") {
                    pendingVideoTimer.restart()
                }
            }

            opacity: active && item ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        Connections {
            target: themeManager
            function onEffectiveAccentColorChanged() {
                if (shaderLoader.item) {
                    if (root.backgroundStyle === "ps-symbols") {
                        shaderLoader.item.accentColor = themeManager.effectiveAccentColor
                    }
                    if (root.backgroundStyle === "firefly") {
                        shaderLoader.item.accentColor = themeManager.effectiveAccentColor
                    }
                    if (root.backgroundStyle === "pegasus") {
                        shaderLoader.item.accentColor = themeManager.effectiveAccentColor
                    }
                }
            }
        }

        Connections {
            target: root
            ignoreUnknownSignals: true
            function on_WaveColorsChanged() {
                if (shaderLoader.item && root.backgroundStyle === "hills") {
                    shaderLoader.item.waveColor1 = _waveColors[0]
                    shaderLoader.item.waveColor2 = _waveColors[1]
                    shaderLoader.item.waveColor3 = _waveColors[2]
                    var isDefault = themeManager.accentColorName === "default"
                    shaderLoader.item.waveOpacity1 = isDefault ? 1.0 : 0.15
                    shaderLoader.item.waveOpacity2 = isDefault ? 1.0 : 0.25
                    shaderLoader.item.waveOpacity3 = isDefault ? 1.0 : 0.35
                }
            }
        }

        Timer {
            id: _shaderUnloadTimer
            interval: 320
            onTriggered: {
                shaderLoader.active = false
                videoLoader.active = false
            }
        }

        Timer {
            id: _videoDebounce
            interval: 150
            onTriggered: {
                bgArea.applyVideoSource()
            }
        }

        function applyVideoSource() {
            if (!videoLoader.item || !videoLoader.item.videoPlayer) {
                pendingVideoTimer.restart()
                return
            }

            var player = videoLoader.item.videoPlayer
            var newSource = bgArea._videoSrc
            player.stop()
            player.source = ""

            if (newSource !== "") {
                setSourceTimer.newSource = newSource
                setSourceTimer.restart()
            }
        }

        Timer {
            id: setSourceTimer
            interval: 50
            repeat: false
            property string newSource: ""
            onTriggered: {
                if (videoLoader.item && videoLoader.item.videoPlayer) {
                    videoLoader.item.videoPlayer.source = newSource
                }
            }
        }

        Timer {
            id: pendingVideoTimer
            interval: 100
            repeat: true
            property int attempts: 0
            onTriggered: {
                attempts++

                if (videoLoader.item && videoLoader.item.videoPlayer) {
                    stop()
                    attempts = 0
                    bgArea.applyVideoSource()
                } else if (attempts > 20) {
                    stop()
                    attempts = 0
                }
            }
        }

        Timer {
            id: reloadTimer
            interval: 30
            repeat: false
            property string newSource: ""
            onTriggered: {
                if (videoLoader.item && videoLoader.item.videoPlayer && newSource !== "") {
                    videoLoader.item.videoPlayer.source = newSource
                    videoLoader.item.videoPlayer.play()
                }
            }
        }

        Connections {
            target: root
            function onBackgroundStyleChanged() {
                if (bgArea._isShaderMode) {
                    _shaderUnloadTimer.stop()
                    shaderLoader.active = true
                    videoLoader.active = false
                    if (_bgA) _bgA.source = ""
                        if (_bgB) _bgB.source = ""
                            bgArea._showA = true
                } else if (bgArea._isVideoMode) {
                    _shaderUnloadTimer.stop()
                    shaderLoader.active = false
                    videoLoader.active = true
                    if (_bgA) _bgA.source = ""
                        if (_bgB) _bgB.source = ""
                            bgArea._showA = true
                            _videoDebounce.restart()
                } else {
                    _shaderUnloadTimer.restart()
                    _bgDebounce.restart()
                }
            }
        }

        Connections {
            target: bgArea
            function onCurrentGameChanged() {
                if (bgArea._isVideoMode) {
                    _videoDebounce.restart()
                }
            }
        }

        Image {
            id: _bgA
            anchors.fill: parent
            fillMode: Image.Stretch
            smooth: true
            asynchronous: true
            visible: !bgArea._isShaderMode && !bgArea._isVideoMode
            opacity: !bgArea._isShaderMode && !bgArea._isVideoMode && bgArea._showA ? 0.60 : 0.0
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
        }

        Image {
            id: _bgB
            anchors.fill: parent
            fillMode: Image.Stretch
            smooth: true
            asynchronous: true
            visible: !bgArea._isShaderMode && !bgArea._isVideoMode
            opacity: !bgArea._isShaderMode && !bgArea._isVideoMode && !bgArea._showA ? 0.60 : 0.0
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
        }

        Timer {
            id: _bgDebounce
            interval: 150
            onTriggered: bgArea._loadNext()
        }

        on_ResolvedSrcChanged: _bgDebounce.restart()

        function _loadNext() {
            var incoming = _showA ? _bgB : _bgA
            incoming.source = _resolvedSrc
            if (_resolvedSrc === "" || incoming.status === Image.Ready)
                _showA = !_showA
        }

        Connections {
            target: _bgA
            function onStatusChanged() {
                if (!bgArea._showA && (_bgA.status === Image.Ready || _bgA.status === Image.Error))
                    bgArea._showA = true
            }
        }

        Connections {
            target: _bgB
            function onStatusChanged() {
                if (bgArea._showA && (_bgB.status === Image.Ready || _bgB.status === Image.Error))
                    bgArea._showA = false
            }
        }

        Rectangle {
            id: rectopa
            anchors.fill: parent
            color: themeManager.currentTheme === "dark" ? "#0D0D0D" : "#E8ECEF"
            opacity: bgArea._isShaderMode || bgArea._isVideoMode
            ? 0.0
            : (themeManager.currentTheme === "dark" ? 0.7 : 0.05)
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        Rectangle {
            anchors.fill: parent
            visible: !bgArea._isShaderMode && !bgArea._isVideoMode
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: themeManager.currentTheme === "dark" ? "#CC000000" : "#CCFFFFFF" }
                GradientStop { position: 0.5; color: themeManager.currentTheme === "dark" ? "#55000000" : "#55FFFFFF" }
                GradientStop { position: 1.0; color: themeManager.currentTheme === "dark" ? "#CC000000" : "#CCFFFFFF" }
            }
        }
    }

    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(100)
        z: 1
        gradient: Gradient {
            GradientStop { position: 0.3; color: themeManager.currentTheme === "dark" ? "#EE000000" : "#EEFFFFFF" }
            GradientStop { position: 1.0; color: themeManager.currentTheme === "dark" ? "#00000000" : "#00FFFFFF" }
        }
    }

    Item {
        id: statusBar
        z: 2
        anchors { top: parent.top; right: parent.right; rightMargin: vpx(32); topMargin: vpx(10) }
        height: vpx(56)
        width: vpx(160)

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: vpx(12)

            Text {
                id: clockLabel
                color: themeManager.color("textSecondary")
                font { family: fontManager.currentFont; pixelSize: vpx(28) }
                Timer {
                    interval: 30000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: clockLabel.text = Qt.formatTime(new Date(), "hh:mm")
                }
            }

            Text {
                text: "•"
                color: themeManager.color("textSecondary")
                font { family: fontManager.currentFont; pixelSize: vpx(18) }
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                id: batteryStatus
                width:  hasBattery ? vpx(32) : acPowerLabel.width
                height: vpx(32)
                anchors.verticalCenter: parent.verticalCenter

                readonly property bool hasBattery: !isNaN(api.device.batteryPercent)
                readonly property int   batteryPct: hasBattery ? Math.round(api.device.batteryPercent * 100) : 0

                readonly property string batteryIcon: {
                    if (!hasBattery) return ""
                        if (api.device.batteryCharging)  return "assets/icon/battery-charging-full.svg"
                            if (batteryPct >= 97)            return "assets/icon/battery-full.svg"
                                if (batteryPct <= 3)             return "assets/icon/battery-alert.svg"
                                    var lvl = Math.min(6, Math.floor(batteryPct / 14))
                                    return "assets/icon/" + lvl + ".svg"
                }

                Image {
                    anchors.fill: parent
                    source: batteryStatus.hasBattery ? batteryStatus.batteryIcon : ""
                    visible: batteryStatus.hasBattery
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: themeManager.color("textSecondary")
                    }
                }

                Text {
                    id: acPowerLabel
                    visible: !batteryStatus.hasBattery
                    anchors.verticalCenter: parent.verticalCenter
                    text: "AC-POWER ⚡"
                    color: themeManager.color("textSecondary")
                    font { family: fontManager.currentFont; pixelSize: vpx(28) }
                }
            }
        }
    }

    Item {
        id: headerAnchor
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(75)
    }

    CollectionList {
        id: collectionBar
        z: 2
        anchors { top: parent.top; left: parent.left; right: statusBar.left }
        height: vpx(75)
        visible: !root.searchActive
        collectionList: root.fullCollectionList
        currentIndex: root.currentCollectionIndex
        hasFocus: false
        onCollectionSelected: {
            if (root.currentCollectionIndex !== index) {
                root.currentCollectionIndex = index
                root.currentGameIndex = 0
            }
        }
    }

    Item {
        id: searchBar
        z: 2
        anchors {
            top: parent.top
            left: parent.left
            leftMargin: vpx(16)
        }
        width: parent.width * 0.6
        height: vpx(75)
        visible: root.searchActive

        Rectangle {
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                right: parent.right
            }
            height: vpx(48)
            radius: vpx(24)
            color: themeManager.currentTheme === "dark" ? "#CC1A1A1A" : "#CCE8ECEF"
            border.color: themeManager.color("border")
            border.width: 1

            Row {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: vpx(14)
                }
                spacing: vpx(10)

                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    source: "assets/icon/search.svg"
                    width: vpx(22)
                    height: vpx(22)
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    layer.enabled: true
                    layer.effect: ColorOverlay { color: themeManager.color("iconSecondary") }
                }

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: searchBar.width - vpx(100)
                    height: vpx(30)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search game"
                        color: themeManager.color("textTertiary")
                        font { family: fontManager.currentFont; pixelSize: vpx(20) }
                        visible: searchInput.text === ""
                    }

                    TextInput {
                        id: searchInput
                        anchors.fill: parent
                        color: themeManager.color("textPrimary")
                        font { family: fontManager.currentFont; pixelSize: vpx(20) }
                        clip: true
                        focus: root.searchActive
                        selectionColor: themeManager.color("accent")

                        onTextChanged: {
                            root.searchText = text
                            if (text.trim().length > 0 && root.searchResultModel.length > 0)
                                Qt.callLater(function() { root._refocusActiveView() })
                        }

                        Keys.onPressed: {
                            if (event.key === Qt.Key_Escape) {
                                event.accepted = true
                                root.closeSearch()
                                return
                            }
                            if (event.key === Qt.Key_Down) {
                                event.accepted = true
                                root._giveViewFocusFromSearch(true)
                                return
                            }
                            if (event.key === Qt.Key_Right && cursorPosition === text.length) {
                                event.accepted = true
                                root._giveViewFocusFromSearch(true)
                                return
                            }
                        }
                    }
                }
            }

            Item {
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                    rightMargin: vpx(10)
                }
                width: vpx(36)
                height: vpx(36)

                Image {
                    anchors.centerIn: parent
                    source: "assets/icon/delete.svg"
                    width: vpx(26)
                    height: vpx(26)
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    visible: root.searchText !== ""
                    layer.enabled: true
                    layer.effect: ColorOverlay { color: themeManager.color("iconSecondary") }
                }

                Image {
                    anchors.centerIn: parent
                    source: "assets/icon/close.svg"
                    width: vpx(26)
                    height: vpx(26)
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    visible: root.searchText === ""
                    layer.enabled: true
                    layer.effect: ColorOverlay { color: themeManager.color("iconSecondary") }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.searchText !== "") {
                            searchInput.text = ""
                            root.searchText = ""
                            searchInput.forceActiveFocus()
                        } else {
                            root.closeSearch()
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: footerBar
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: vpx(80)
        gradient: Gradient {
            GradientStop { position: 0.0; color: themeManager.currentTheme === "dark" ? "#00000000" : "#00FFFFFF" }
            GradientStop { position: 1.0; color: themeManager.currentTheme === "dark" ? "#FF000000" : "#FFFFFFFF" }
        }

        Row {
            anchors {
                left: parent.left
                leftMargin: vpx(16)
                bottom: parent.bottom
                bottomMargin: vpx(14)
            }
            spacing: vpx(20)
            FooterButton { buttonText: "B"; labelText: "Back" }
            FooterButton { buttonText: "Y"; labelText: "Configuration"; onClicked: root.openSettings() }
            FooterButton {
                buttonText: "X"
                labelText: "Game"
                onClicked: {
                    if (!root.configOpen && !root.contextMenuOpen) {
                        var model = root.searchActive ? root.searchResultModel : root.activeGameModel
                        var game = null
                        if (model) {
                            if (model.get) game = model.get(root.currentGameIndex)
                                else if (model.length) game = model[root.currentGameIndex]
                        }
                        if (game) globalContextMenu.open(game)
                    }
                }
            }
            Rectangle {
                width: vpx(5)
                height: vpx(5)
                radius: width / 2
                color: themeManager.color("iconPrimary")
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                id: viewModeButton
                anchors.verticalCenter: parent.verticalCenter
                width: vpx(44)
                height: vpx(44)

                readonly property var _modeIcons: [
                    "assets/icon/gallery.svg",
                    "assets/icon/gridview.svg",
                    "assets/icon/bulles.svg",
                    "assets/icon/listview.svg"
                ]

                Rectangle {
                    anchors.fill: parent
                    radius: vpx(8)
                    color: footerViewMenu._open ? themeManager.color("surfaceHighlight") : "transparent"
                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    source: viewModeButton._modeIcons[root.viewMode] || ""
                    width: vpx(35)
                    height: vpx(35)
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    layer.enabled: true
                    layer.effect: ColorOverlay { color: themeManager.color("iconPrimary") }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: footerViewMenu.toggle()
                }
            }

            Item {
                id: searchButton
                anchors.verticalCenter: parent.verticalCenter
                width: vpx(44)
                height: vpx(44)

                Rectangle {
                    anchors.fill: parent
                    radius: vpx(8)
                    color: root.searchActive ? themeManager.color("surfaceHighlight") : "transparent"
                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                Image {
                    anchors.centerIn: parent
                    source: root.searchActive ? "assets/icon/search-off.svg" : "assets/icon/search.svg"
                    width: vpx(30)
                    height: vpx(30)
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    layer.enabled: true
                    layer.effect: ColorOverlay { color: themeManager.color("iconPrimary") }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.searchActive)
                            root.closeSearch()
                            else
                                root.openSearch()
                    }
                }
            }
        }

        Row {
            anchors { right: parent.right; rightMargin: vpx(16); bottom: parent.bottom; bottomMargin: vpx(14) }
            FooterButton { buttonText: "A"; labelText: "Play" }
        }
    }

    ViewSwitcherMenu {
        id: footerViewMenu
        z: 150
        currentViewMode: root.viewMode
        anchorItem: viewModeButton
        anchorOffsetX: vpx(90)

        onViewSelected: function(mode) {
            root.viewMode = mode
            root.persistState()
            Qt.callLater(function() { root._refocusActiveView() })
        }

        onMenuClosed: {
            Qt.callLater(function() { root._refocusActiveView() })
        }
    }

    function _bindView(item) {
        item.gameModel = Qt.binding(function() {
            return root.searchActive ? root.searchResultModel : root.activeGameModel
        })
        item.currentGameIndex = Qt.binding(function() { return root.currentGameIndex })
        item.collectionEntry = Qt.binding(function() {
            return root.searchActive ? root.searchCollectionEntry : root.activeCollectionEntry
        })
        item.ratioMap = Qt.binding(function() { return root.ratioMap })
        item.fillMap = Qt.binding(function() { return root.fillMap })
        item.onCurrentGameIndexChanged.connect(function() {
            root.currentGameIndex = item.currentGameIndex
        })
        item.onGameSelected.connect(function(game) {
            root.persistState()
            game.launch()
        })
        item.onNextCollectionRequested.connect(function() { root.goNextCollection() })
        item.onPrevCollectionRequested.connect(function() { root.goPrevCollection() })
        item.onContextMenuRequested.connect(function(game) {
            root._activeViewItem = item
            globalContextMenu.open(game)
        })
        item.onFocusRequested.connect(function() {
            if (root.searchActive) root._giveViewFocusFromSearch(false)
        })
        if (!root.configOpen && !root.searchActive) item.forceActiveFocus()
    }

    FocusScope {
        id: carouselWrapper
        anchors { top: headerAnchor.bottom; left: parent.left; right: parent.right; bottom: footerBar.top }
        visible: root.viewMode === 0
        focus: root.viewMode === 0 && !root.configOpen && !root.searchActive

        Row {
            id: listGameTitle
            anchors {
                top: parent.top
                topMargin: vpx(14)
                left: parent.left
                leftMargin: vpx(86)
                right: parent.right
                rightMargin: vpx(48)
            }
            height: vpx(32)
            spacing: vpx(12)
            visible: selGame !== null

            property var selGame: {
                var model = (root.searchActive && root.searchText.trim() !== "")
                ? root.searchResultModel
                : root.activeGameModel
                if (!model) return null
                    var count = model.count !== undefined ? model.count : (model.length || 0)
                    if (count === 0) return null
                        var idx = Math.min(root.currentGameIndex, count - 1)
                        if (model.get) {
                            var g = model.get(idx)
                            return g !== undefined ? g : null
                        }
                        return (model.length && idx < model.length) ? model[idx] : null
            }

            Image {
                id: favoriteIcon
                anchors.verticalCenter: parent.verticalCenter
                width: vpx(28)
                height: vpx(28)
                source: "assets/icon/favorite-on.svg"
                visible: listGameTitle.selGame ? listGameTitle.selGame.favorite === true : false
                fillMode: Image.PreserveAspectFit
                mipmap: true
                layer.enabled: true
                layer.effect: ColorOverlay {
                    color: themeManager.effectiveAccentColor
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - (favoriteIcon.visible ? favoriteIcon.width + parent.spacing : 0)
                text: listGameTitle.selGame ? listGameTitle.selGame.title : ""
                color: themeManager.accentColorName === "default"
                ? themeManager.color("textPrimary")
                : themeManager.accentColorValue
                font { family: fontManager.currentFont; pixelSize: vpx(28); bold: true }
                elide: Text.ElideRight
            }
        }

        Loader {
            id: listViewLoader
            anchors { top: listGameTitle.bottom; left: parent.left; right: parent.right; bottom: listMetaRow.top }
            active: root.viewMode === 0
            focus: true
            source: "GameListView.qml"
            onLoaded: root._bindView(item)
        }

        Item {
            id: listMetaRow
            anchors {
                left: parent.left
                leftMargin: vpx(86)
                right: parent.right
                rightMargin: vpx(48)
                bottom: parent.bottom
                bottomMargin: vpx(-5)
            }
            height: vpx(48)

            property var selGame: {
                var model = (root.searchActive && root.searchText.trim() !== "")
                ? root.searchResultModel
                : root.activeGameModel
                if (!model) return null
                    var count = model.count !== undefined ? model.count : (model.length || 0)
                    if (count === 0) return null
                        var idx = Math.min(root.currentGameIndex, count - 1)
                        if (model.get) {
                            var g = model.get(idx)
                            return g !== undefined ? g : null
                        }
                        return (model.length && idx < model.length) ? model[idx] : null
            }

            Row {
                spacing: vpx(40)

                Column {
                    spacing: vpx(4)
                    visible: listMetaRow.selGame ? listMetaRow.selGame.releaseYear > 0 : false
                    Text {
                        text: "Release date"
                        color: themeManager.color("textSecondary")
                        font { family: fontManager.currentFont; pixelSize: vpx(18) }
                    }
                    Text {
                        text: {
                            if (!listMetaRow.selGame || listMetaRow.selGame.releaseYear === 0) return ""
                                var d = listMetaRow.selGame.release
                                if (d && !isNaN(d.getTime())) return Qt.formatDate(d, "MMM d, yyyy")
                                    return listMetaRow.selGame.releaseYear.toString()
                        }
                        color: themeManager.color("textPrimary")
                        font { family: fontManager.currentFont; pixelSize: vpx(22); bold: true }
                    }
                }

                Column {
                    spacing: vpx(4)
                    visible: listMetaRow.selGame ? listMetaRow.selGame.genre !== "" : false
                    Text {
                        text: "Genre"
                        color: themeManager.color("textSecondary")
                        font { family: fontManager.currentFont; pixelSize: vpx(18) }
                    }
                    Text {
                        text: listMetaRow.selGame ? listMetaRow.selGame.genre : ""
                        color: themeManager.color("textPrimary")
                        font { family: fontManager.currentFont; pixelSize: vpx(22); bold: true }
                        elide: Text.ElideRight
                        width: vpx(280)
                    }
                }

                Column {
                    spacing: vpx(4)
                    visible: listMetaRow.selGame ? listMetaRow.selGame.developer !== "" : false
                    Text {
                        text: "Developer"
                        color: themeManager.color("textSecondary")
                        font { family: fontManager.currentFont; pixelSize: vpx(18) }
                    }
                    Text {
                        text: listMetaRow.selGame ? listMetaRow.selGame.developer : ""
                        color: themeManager.color("textPrimary")
                        font { family: fontManager.currentFont; pixelSize: vpx(22); bold: true }
                    }
                }

                Column {
                    spacing: vpx(4)
                    visible: listMetaRow.selGame ? listMetaRow.selGame.publisher !== "" : false
                    Text {
                        text: "Publisher"
                        color: themeManager.color("textSecondary")
                        font { family: fontManager.currentFont; pixelSize: vpx(18) }
                    }
                    Text {
                        text: listMetaRow.selGame ? listMetaRow.selGame.publisher : ""
                        color: themeManager.color("textPrimary")
                        font { family: fontManager.currentFont; pixelSize: vpx(22); bold: true }
                    }
                }
            }
        }
    }

    Loader {
        id: gridViewLoader
        anchors { top: headerAnchor.bottom; left: parent.left; right: parent.right; bottom: footerBar.top }
        active: root.viewMode === 1
        focus: root.viewMode === 1 && !root.configOpen && !root.searchActive
        source: "GameGridView.qml"
        onLoaded: root._bindView(item)
    }

    Loader {
        id: bubblesLoader
        anchors { top: headerAnchor.bottom; left: parent.left; right: parent.right; bottom: footerBar.top }
        active: root.viewMode === 2
        focus: root.viewMode === 2 && !root.configOpen && !root.searchActive
        source: "GameBulles.qml"
        onLoaded: root._bindView(item)
    }

    Loader {
        id: detailListLoader
        anchors { top: headerAnchor.bottom; left: parent.left; right: parent.right; bottom: footerBar.top }
        active: root.viewMode === 3
        focus: root.viewMode === 3 && !root.configOpen && !root.searchActive
        source: "GameDetailList.qml"
        onLoaded: root._bindView(item)
    }

    Item {
        id: searchEmptyOverlay
        z: 10
        anchors {
            top: searchBar.bottom
            left: parent.left
            right: parent.right
            bottom: footerBar.top
        }
        visible: root.searchActive && root.searchText.trim() === ""

        Text {
            anchors.centerIn: parent
            text: qsTr("Enter a search term.")
            color: themeManager.color("textSecondary")
            font { family: fontManager.currentFont; pixelSize: vpx(26) }
        }
    }

    Loader {
        id: settingsLoader
        anchors.fill: parent
        z: 200
        active: false
        source: "SettingsMenu.qml"

        onLoaded: {
            item.fullCollectionList = Qt.binding(function() { return root.fullCollectionList })
            item.viewMode = root.viewMode
            item.backgroundStyle = root.backgroundStyle
            item.open()
        }
    }



    Connections {
        target: settingsLoader.item

        function onViewModeChanged() {
            var mode = settingsLoader.item ? settingsLoader.item.viewMode : root.viewMode
            if (mode !== root.viewMode) {
                root.viewMode = mode
                root.persistState()
            }
        }

        function onRatioMapChanged() {
            var m = settingsLoader.item ? settingsLoader.item.ratioMap : null
            if (m && Object.keys(m).length > 0)
                root.ratioMap = m
        }

        function onFillMapChanged() {
            var m = settingsLoader.item ? settingsLoader.item.fillMap : null
            if (m) root.fillMap = m
        }

        function onBackgroundStyleChanged() {
            var style = settingsLoader.item ? settingsLoader.item.backgroundStyle : root.backgroundStyle
            if (style !== root.backgroundStyle)
                root.backgroundStyle = style
        }

        function onPlatformOrderChanged() {
            var curEntry = root.fullCollectionList[root.currentCollectionIndex]
            var curRealIdx = (curEntry && !curEntry.isVirtual) ? curEntry.realIndex : -1
            var curVirtType = (curEntry && curEntry.isVirtual) ? curEntry.virtualType : ""

            var saved = api.memory.get("collectionOrder")
            if (saved && Array.isArray(saved) && saved.length === api.collections.count)
                root.collectionOrder = saved.slice()

                Qt.callLater(function() {
                    var idx = root._findCollectionIndex(curRealIdx, curVirtType)
                    root.currentCollectionIndex = idx
                })
        }

        function onClosed() {
            settingsLoader.active = false
            Qt.callLater(function() { root._refocusActiveView() })
        }
    }

    Keys.onPressed: {
        if (api.keys.isFilters(event) && !root.configOpen && !root.contextMenuOpen) {
            event.accepted = true
            root.openSettings()
            return
        }
        if (api.keys.isDetails(event) && !root.configOpen && !root.contextMenuOpen) {
            event.accepted = true
            var model = root.searchActive ? root.searchResultModel : root.activeGameModel
            var game = null
            if (model) {
                if (model.get) game = model.get(root.currentGameIndex)
                    else if (model.length) game = model[root.currentGameIndex]
            }
            if (game) globalContextMenu.open(game)
                return
        }
    }

    Rectangle {
        id: contextMenuOverlay
        anchors.fill: parent
        z: 99
        color: themeManager.currentTheme === "dark" ? "black" : "white"
        opacity: root.contextMenuOpen ? (themeManager.currentTheme === "dark" ? 0.85 : 0.6) : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        MouseArea {
            anchors.fill: parent
            enabled: root.contextMenuOpen
            onClicked: globalContextMenu.close()
        }
    }

    GameContextMenu {
        id: globalContextMenu
        anchors.fill: parent
        z: 100

        onMenuOpenChanged: root.contextMenuOpen = menuOpen

        onPlayRequested: {
            if (game) {
                var gameToLaunch = game
                globalContextMenu.close()
                root.persistState()
                Qt.callLater(function() { gameToLaunch.launch() })
            }
        }

        onCloseRequested: {}

        onFocusRestoreRequested: {
            if (root._activeViewItem && typeof root._activeViewItem.restoreFocus === "function")
                root._activeViewItem.restoreFocus()
                else
                    root._refocusActiveView()
        }
    }
}
