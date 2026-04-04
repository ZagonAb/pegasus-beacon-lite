import QtQuick 2.15
import QtGraphicalEffects 1.15

Item {
    id: root

    property var game: null
    property bool menuOpen: false

    signal playRequested()
    signal closeRequested()
    signal focusRestoreRequested()

    readonly property int _radius: vpx(20)
    readonly property int _btnH: vpx(64)
    readonly property int _btnRadius: vpx(32)
    readonly property int _spacing: vpx(14)
    readonly property int _panelW: vpx(560)
    readonly property int _imgW: vpx(240)
    readonly property int _imgH: vpx(320)

    property int _focusIndex: 0
    readonly property int _btnCount: 3

    visible: menuOpen

    function open(g) {
        if (g !== undefined) game = g
            _focusIndex = 0
            menuOpen = true
            root.forceActiveFocus()
    }

    function close() {
        menuOpen = false
        root.closeRequested()
        root.focusRestoreRequested()
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: root._panelW
        height: vpx(100) + titleText.implicitHeight + vpx(16) + contentRow.height
        radius: root._radius
        color: themeManager.color("surfaceElevated")
        opacity: root.menuOpen ? 1.0 : 0.0
        scale: root.menuOpen ? 1.0 : 0.92

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: vpx(8)
            radius: vpx(32)
            samples: 33
            color: themeManager.currentTheme === "dark" ? "#AA000000" : "#40AAAAAA"
        }

        MouseArea { anchors.fill: parent; onClicked: {} }

        Item {
            id: centerWrapper
            anchors.centerIn: parent
            width: parent.width - vpx(48)
            height: titleText.implicitHeight + vpx(16) + contentRow.height

            Text {
                id: titleText
                anchors { top: parent.top; left: parent.left; right: parent.right }
                text: root.game ? root.game.title : ""
                color: themeManager.color("textPrimary")
                font { family: global.fonts.sans; pixelSize: vpx(26); bold: true }
                elide: Text.ElideRight
            }

            Item {
                id: contentRow
                anchors {
                    top: titleText.bottom
                    topMargin: vpx(16)
                    left: parent.left
                    right: parent.right
                }
                height: root._imgH

                Item {
                    id: coverArea
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: root._imgW

                    Rectangle {
                        anchors.fill: parent
                        radius: vpx(10)
                        color: themeManager.color("surfaceHighlight")
                        visible: coverImg.status !== Image.Ready
                        Text {
                            anchors.centerIn: parent
                            text: root.game ? root.game.title.charAt(0) : ""
                            color: themeManager.color("textTertiary")
                            font { family: global.fonts.condensed; pixelSize: vpx(52); bold: true }
                        }
                    }

                    Image {
                        id: coverImg
                        anchors.centerIn: parent
                        width: root._imgW
                        height: root._imgH
                        source: root.game ? (root.game.assets.boxFront || "") : ""
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                        asynchronous: true
                        visible: true
                    }
                }

                Column {
                    id: btnCol
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    width: (parent.width - root._imgW - vpx(20)) * 0.92
                    spacing: root._spacing

                    GameMenuButton {
                        width: parent.width
                        height: root._btnH
                        btnRadius: root._btnRadius
                        isFocused: root._focusIndex === 0 && root.menuOpen
                        iconSource: "assets/icon/play.svg"
                        labelText: "Play"
                        onActivated: root.playRequested()
                    }

                    GameMenuButton {
                        width: parent.width
                        height: root._btnH
                        btnRadius: root._btnRadius
                        isFocused: root._focusIndex === 1 && root.menuOpen
                        iconSource: (root.game && root.game.favorite)
                        ? "assets/icon/favorite-on.svg"
                        : "assets/icon/favorite-off.svg"
                        labelText: (root.game && root.game.favorite)
                        ? "Remove favorite" : "Add favorite"
                        onActivated: { if (root.game) root.game.favorite = !root.game.favorite }
                    }

                    GameMenuButton {
                        width: parent.width
                        height: root._btnH
                        btnRadius: root._btnRadius
                        isFocused: root._focusIndex === 2 && root.menuOpen
                        iconSource: "assets/icon/close.svg"
                        labelText: "Close"
                        onActivated: root.close()
                    }
                }
            }
        }
    }

    Keys.onPressed: {
        if (!root.menuOpen) return
            if (event.key === Qt.Key_Up || event.key === Qt.Key_Left) {
                event.accepted = true
                root._focusIndex = (root._focusIndex - 1 + root._btnCount) % root._btnCount
                return
            }
            if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
                event.accepted = true
                root._focusIndex = (root._focusIndex + 1) % root._btnCount
                return
            }
            if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true
                if (root._focusIndex === 0) { root.playRequested() }
                else if (root._focusIndex === 1) { if (root.game) root.game.favorite = !root.game.favorite }
                else { root.close() }
                return
            }
            if (api.keys.isCancel(event)) {
                event.accepted = true
                root.close()
                return
            }
            event.accepted = true
    }
}
