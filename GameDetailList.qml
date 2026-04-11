import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "utils.js" as Utils

FocusScope {
    id: root

    property var gameModel
    property int currentGameIndex: 0
    property var collectionEntry: null
    property var ratioMap: ({})
    property var fillMap: ({})

    signal gameSelected(var game)
    signal focusRequested()
    signal nextCollectionRequested()
    signal prevCollectionRequested()
    signal contextMenuRequested(var game)

    function restoreFocus() { lv.forceActiveFocus() }

    function restorePosition() {
        if (root.currentGameIndex > 0)
            lv.positionViewAtIndex(root.currentGameIndex, ListView.Center)
    }

    Component.onCompleted: Qt.callLater(restorePosition)

    property bool _acceptHeld: false

    Timer {
        id: longPressTimer
        interval: 600
        repeat: false
        onTriggered: {
            root._acceptHeld = false
            var g = lv.model.get ? lv.model.get(lv.currentIndex)
                                 : lv.model[lv.currentIndex]
            if (g) root.contextMenuRequested(g)
        }
    }

    readonly property color dimColor: "#666666"
    readonly property color activeCardColor: {
        if (hasCustomAccent && root.activeFocus) {
            if (themeManager.currentTheme === "dark") {
                return Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
            } else {
                return Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.08)
            }
        }
        return themeManager.color("surfaceHighlight")
    }
    readonly property color activeTitleColor: {
        if (hasCustomAccent && root.activeFocus) {
            return accentColor
        }
        return themeManager.color("textPrimary")
    }

    readonly property color inactiveColor: themeManager.color("textTertiary")
    readonly property color activeAccentBorder: accentColor
    readonly property int activeBorderWidth: hasCustomAccent && root.activeFocus ? 3 : 0
    readonly property int listWidth: Math.floor(parent.width * 0.60)
    readonly property int itemH: Math.floor((listPanel.height - vpx(24) - vpx(22)) / 7)
    readonly property int activeH: itemH + vpx(22)
    readonly property int cardRadius: vpx(10)
    readonly property int imgPanelWidth: parent.width - listWidth - vpx(1)
    readonly property color accentColor: themeManager.effectiveAccentColor
    readonly property color accentBase: themeManager.effectiveAccentColor

    readonly property color accentTitleColor: getAccentTitleColor()
    readonly property color accentBgColor: getAccentBackgroundColor()
    readonly property color accentSecondaryColor: getAccentSecondaryColor()
    readonly property color accentFavoriteColor: getAccentFavoriteColor()
    readonly property bool hasCustomAccent: themeManager.accentColorName !== "default"

    readonly property var selGame: {
        if (!gameModel) return null
        return gameModel.get ? gameModel.get(currentGameIndex)
                             : (gameModel[currentGameIndex] || null)
    }

    function fmtDate(game) {
        if (!game || game.releaseYear <= 0) return ""
        var d = game.release
        if (d && !isNaN(d.getTime())) return Qt.formatDate(d, "MMM d, yyyy")
        return game.releaseYear.toString()
    }
    function getAccentTitleColor() {
        if (themeManager.accentColorName === "default")
            return themeManager.color("textPrimary")

            if (themeManager.currentTheme === "dark") {
                // Dark: color base puro (#10B981 para Emerald)
                return accentBase
            } else {
                // Light: ligeramente más oscuro para contraste
                return Qt.darker(accentBase, 1.15)
            }
    }

    function getAccentBackgroundColor() {
        if (themeManager.accentColorName === "default")
            return themeManager.color("surfaceHighlight")

            if (themeManager.currentTheme === "dark") {
                // Dark: versión muy oscura (#042c1f para Emerald)
                return Qt.darker(accentBase, 3.0)
            } else {
                // Light: versión semi-transparente pero más clara
                var lightVersion = Qt.lighter(accentBase, 1.4)
                return Qt.rgba(lightVersion.r, lightVersion.g, lightVersion.b, 0.65)
            }
    }

    // Función para obtener color de textos secundarios (como #48723e desde #10B981)
    /*function getAccentSecondaryColor() {
        if (themeManager.accentColorName === "default")
            return themeManager.color("textSecondary")

            if (themeManager.currentTheme === "dark") {
                // Para dark: versión más oscura del acento
                return Qt.darker(accentBase, 1.3)
            } else {
                // Para light: versión más suave
                return Qt.rgba(accentBase.r, accentBase.g, accentBase.b, 0.12)
            }
    }*/

    // En la sección de propiedades

    // En la sección de propiedades

    function getAccentSecondaryColor() {
        if (themeManager.accentColorName === "default")
            return themeManager.color("textSecondary")

            if (themeManager.currentTheme === "dark") {
                // Dark: versión muy clara/brillante (#a9ffec para Emerald)
                return Qt.lighter(accentBase, 1.8)
            } else {
                // Light: versión más oscura pero legible
                return Qt.darker(accentBase, 1.2)
            }
    }

    // Bonus: función específica para iconos (más claros)
    function getAccentIconColor() {
        if (themeManager.accentColorName === "default")
            return themeManager.color("iconSecondary")

            if (themeManager.currentTheme === "dark") {
                return Qt.darker(accentBase, 1.2)
            } else {
                // Light: iconos más claros y brillantes
                var desaturated = Qt.rgba(
                    accentBase.r * 0.8 + 0.2,
                    accentBase.g * 0.8 + 0.2,
                    accentBase.b * 0.8 + 0.2,
                    1.0
                )
                return Qt.lighter(desaturated, 1.05)
            }
    }

    function getAccentFavoriteColor() {
        if (themeManager.accentColorName === "default")
            return themeManager.color("iconPrimary")

            return accentBase
    }

    // Función específica para el color del favorito
    function getFavoriteColor() {
        if (themeManager.accentColorName === "default") {
            // Cuando no hay color acento personalizado
            // Puedes usar un color especial para favoritos (ej: dorado)
            if (themeManager.currentTheme === "dark") {
                return "#FFD700"  // Dorado para dark mode
            } else {
                return "#DAA520"  // Dorado más oscuro para light mode
            }
        }

        // Cuando hay color acento personalizado, usar el mismo que el título
        return getAccentTitleColor()
    }

    Item {
        id: listPanel
        anchors { top: parent.top; left: parent.left; bottom: parent.bottom }
        width: root.listWidth
        clip: true

        ListView {
            id: lv
            anchors {
                fill: parent
                topMargin: vpx(12)
                bottomMargin: vpx(12)
                leftMargin: vpx(24)
                rightMargin: vpx(12)
            }

            model: root.gameModel
            currentIndex: root.currentGameIndex
            clip: false
            focus: true
            spacing: 0
            highlightMoveDuration: 180
            preferredHighlightBegin: height * 0.20
            preferredHighlightEnd: height * 0.75
            highlightRangeMode: ListView.ApplyRange

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
                id: row
                property bool isActive: ListView.isCurrentItem && root.activeFocus
                property var game: modelData
                width: lv.width
                height: row.isActive ? root.activeH : root.itemH

                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

                /*Rectangle {
                    anchors { fill: parent; bottomMargin: vpx(4) }
                    radius: root.cardRadius
                    color: row.isActive ? root.activeCardColor : "transparent"
                    opacity: row.isActive ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                }*/

                Rectangle {
                    anchors { fill: parent; bottomMargin: vpx(4) }
                    radius: root.cardRadius
                    color: {
                        if (!row.isActive) return "transparent"
                            if (!root.hasCustomAccent) return themeManager.color("surfaceHighlight")
                                return root.accentBgColor
                    }
                    opacity: row.isActive ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                }

                Item {
                    anchors { fill: parent; leftMargin: vpx(16); rightMargin: vpx(12) }

                    Item {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }
                        height: root.itemH

                        /*Text {
                            id: titleTxt
                            anchors {
                                left: parent.left
                                right: favoriteIcon.left
                                rightMargin: vpx(12)
                                verticalCenter: parent.verticalCenter
                            }
                            text: row.game ? row.game.title : ""
                            color: row.isActive ? root.activeTitleColor : root.inactiveColor
                            font.family: global.fonts.sans
                            font.pixelSize: row.isActive ? vpx(32) : vpx(29)
                            font.bold: row.isActive
                            elide: Text.ElideRight

                            Behavior on color { ColorAnimation  { duration: 160 } }
                            Behavior on font.pixelSize { NumberAnimation { duration: 160 } }
                        }*/

                        Text {
                            id: titleTxt
                            anchors {
                                left: parent.left
                                right: favoriteIcon.left
                                rightMargin: vpx(12)
                                verticalCenter: parent.verticalCenter
                            }
                            text: row.game ? row.game.title : ""
                            color: {
                                if (!row.isActive) return root.inactiveColor
                                    if (!root.hasCustomAccent) return root.activeTitleColor
                                        return root.accentTitleColor
                            }
                            font.family: global.fonts.sans
                            font.pixelSize: row.isActive ? vpx(32) : vpx(29)
                            font.bold: row.isActive
                            elide: Text.ElideRight

                            Behavior on color { ColorAnimation { duration: 160 } }
                            Behavior on font.pixelSize { NumberAnimation { duration: 160 } }
                        }

                        /*Image {
                            id: favoriteIcon
                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            width: row.isActive ? vpx(28) : vpx(24)
                            height: row.isActive ? vpx(28) : vpx(24)
                            source: "assets/icon/favorite-on.svg"
                            visible: row.game ? row.game.favorite === true : false
                            fillMode: Image.PreserveAspectFit
                            mipmap: true

                            Behavior on width { NumberAnimation { duration: 160 } }
                            Behavior on height { NumberAnimation { duration: 160 } }
                        }*/

                        Image {
                            id: favoriteIcon
                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            width: row.isActive ? vpx(28) : vpx(24)
                            height: row.isActive ? vpx(28) : vpx(24)
                            source: "assets/icon/favorite-on.svg"
                            visible: row.game ? row.game.favorite === true : false
                            fillMode: Image.PreserveAspectFit
                            mipmap: true

                            // El ícono favorito SIEMPRE usa el color del título, independientemente de si está seleccionado
                            layer.enabled: root.hasCustomAccent && visible
                            layer.effect: ColorOverlay {
                                color: {
                                    if (!root.hasCustomAccent) {
                                        // Si no hay color personalizado, usar el color primario del tema
                                        return themeManager.color("iconPrimary")
                                    }
                                    // Usar el mismo color que el título
                                    return root.accentTitleColor
                                }
                            }

                            Behavior on width { NumberAnimation { duration: 160 } }
                            Behavior on height { NumberAnimation { duration: 160 } }
                        }
                    }

                    RowLayout {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            topMargin: root.itemH + vpx(-15)
                        }
                        height: vpx(28)
                        spacing: vpx(15)
                        visible: row.isActive
                        opacity: row.isActive ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 180 } }

                        Row {
                            spacing: vpx(6)
                            visible: row.game && row.game.releaseYear > 0
                            Layout.fillWidth: false

                            Item {
                                width: vpx(20)
                                height: vpx(20)

                                Image {
                                    id: releaseYearIcon
                                    source: "assets/icon/releaseyear.svg"
                                    anchors.fill: parent
                                    sourceSize.width: vpx(20)
                                    sourceSize.height: vpx(20)
                                    smooth: true
                                    mipmap: true
                                    visible: false
                                }
                                ColorOverlay {
                                    anchors.fill: releaseYearIcon
                                    source: releaseYearIcon
                                    color: {
                                        if (!row.isActive) return "#555555"
                                            if (!root.hasCustomAccent) return "#555555"
                                                return root.accentSecondaryColor
                                    }
                                }
                            }

                            Text {
                                text: row.game ? root.fmtDate(row.game) : ""
                                color: {
                                    if (!row.isActive) return "#555555"
                                        if (!root.hasCustomAccent) return "#555555"
                                            return root.accentSecondaryColor  // Mismo color que los íconos
                                }
                                font { family: global.fonts.sans; pixelSize: vpx(20) }
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            spacing: vpx(6)
                            visible: row.game && row.game.genre !== ""
                            Layout.fillWidth: false

                            Item {
                                width: vpx(20)
                                height: vpx(20)

                                Image {
                                    id: genreIcon
                                    source: "assets/icon/genre.svg"
                                    anchors.fill: parent
                                    sourceSize.width: vpx(20)
                                    sourceSize.height: vpx(20)
                                    smooth: true
                                    mipmap: true
                                    visible: false
                                }

                                ColorOverlay {
                                    anchors.fill: genreIcon
                                    source: genreIcon
                                    color: {
                                        if (!row.isActive) return "#555555"
                                            if (!root.hasCustomAccent) return "#555555"
                                                return root.accentSecondaryColor
                                    }
                                }
                            }

                            Text {
                                text: row.game ? Utils.getFirstGenre(game) : ""
                                color: {
                                    if (!row.isActive) return "#555555"
                                        if (!root.hasCustomAccent) return "#555555"
                                            return root.accentSecondaryColor  // Mismo color que los íconos
                                }
                                font { family: global.fonts.sans; pixelSize: vpx(20) }
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            spacing: vpx(6)
                            visible: row.game && row.game.developer !== ""
                            Layout.fillWidth: false

                            Item {
                                width: vpx(18)
                                height: vpx(18)

                                Image {
                                    id: developerIcon
                                    source: "assets/icon/developer.svg"
                                    anchors.fill: parent
                                    sourceSize.width: vpx(18)
                                    sourceSize.height: vpx(18)
                                    smooth: true
                                    mipmap: true
                                    visible: false
                                }

                                ColorOverlay {
                                    anchors.fill: developerIcon
                                    source: developerIcon
                                    color: {
                                        if (!row.isActive) return "#555555"
                                            if (!root.hasCustomAccent) return "#555555"
                                                return root.accentSecondaryColor
                                    }
                                }
                            }

                            Text {
                                text: row.game ? row.game.developer : ""
                                color: {
                                    if (!row.isActive) return "#555555"
                                        if (!root.hasCustomAccent) return "#555555"
                                            return root.accentSecondaryColor  // Mismo color que los íconos
                                }
                                font { family: global.fonts.sans; pixelSize: vpx(20) }
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, vpx(170))
                                elide: Text.ElideRight
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            height: parent.height
                            visible: row.game && row.game.publisher !== ""

                            Item {
                                id: publisherIconContainer
                                width: vpx(18)
                                height: vpx(18)
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    id: publisherIcon
                                    source: "assets/icon/publisher.svg"
                                    anchors.fill: parent
                                    sourceSize.width: vpx(18)
                                    sourceSize.height: vpx(18)
                                    smooth: true
                                    mipmap: true
                                    visible: false
                                }

                                ColorOverlay {
                                    anchors.fill: publisherIcon
                                    source: publisherIcon
                                    color: {
                                        if (!row.isActive) return "#555555"
                                            if (!root.hasCustomAccent) return "#555555"
                                                return root.accentSecondaryColor
                                    }
                                }
                            }

                            Text {
                                anchors {
                                    left: publisherIconContainer.right
                                    leftMargin: vpx(6)
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                }
                                text: row.game ? row.game.publisher : ""
                                color: {
                                    if (!row.isActive) return "#555555"
                                        if (!root.hasCustomAccent) return "#555555"
                                            return root.accentSecondaryColor  // Mismo color que los íconos
                                }
                                font { family: global.fonts.sans; pixelSize: vpx(20) }
                                elide: Text.ElideRight
                            }
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
                                root.contextMenuRequested(row.game)
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
                            lv.currentIndex = index
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
                            root.gameSelected(row.game)
                        }
                        longPressTriggered = false
                    }
                }
            }
        }
    }

    Item {
        id: imgPanel
        anchors { top: parent.top; bottom: parent.bottom; left: listPanel.right; right: parent.right }
        clip: true

        Image {
            id: gameImg
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left;  leftMargin:  vpx(20)
                right: parent.right; rightMargin: vpx(20)
            }
            property string targetSrc: root.selGame
                ? (root.selGame.assets.boxFront || root.selGame.assets.screenshot || "")
                : ""

            source: targetSrc
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true

            onTargetSrcChanged: fadeOut.start()

            NumberAnimation {
                id: fadeOut
                target: gameImg
                property: "opacity"
                from: 1.0; to: 0.0
                duration: 120
                onStopped: {
                    gameImg.source = gameImg.targetSrc
                    fadeIn.start()
                }
            }
            NumberAnimation {
                id: fadeIn
                target: gameImg
                property: "opacity"
                from: 0.0; to: 1.0
                duration: 200
            }

            Rectangle {
                anchors.centerIn: parent
                width: vpx(340)
                height: vpx(440)
                radius: vpx(20)
                color: "#191919"
                visible: gameImg.status !== Image.Ready

                // Agrega borde de acento cuando el juego está seleccionado
                border.width: root.hasCustomAccent && root.activeFocus ? vpx(2) : 0
                border.color: root.activeAccentBorder

                Column {
                    anchors.centerIn: parent
                    spacing: vpx(10)

                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: vpx(80)
                        height: vpx(80)

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
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.selGame ? root.selGame.title.charAt(0).toUpperCase() : ""
                        color: themeManager.color("textTertiary")
                        font { pixelSize: vpx(24); bold: true }
                        visible: true
                    }
                }
            }
        }
    }
}
