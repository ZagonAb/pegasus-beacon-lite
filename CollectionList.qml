import QtQuick 2.15

FocusScope {
    id: root

    property var  collectionList: []
    property int  currentIndex:   0
    property bool hasFocus:       false

    signal collectionSelected(int index)

    implicitHeight: vpx(75)
    clip: true

    readonly property int pillH:   vpx(50)
    readonly property int pillR:   vpx(25)
    readonly property int _edgeMargin: vpx(24)

    NumberAnimation {
        id: scrollAnim
        target: listView
        property: "contentX"
        duration: 200
        easing.type: Easing.InOutQuad
    }

    function _doScroll(idx) {
        var item = listView.itemAtIndex(idx)
        if (!item) {
            Qt.callLater(_doScroll, idx)
            return
        }

        var itemLeft  = item.x
        var itemRight = item.x + item.width

        var refX      = scrollAnim.running ? scrollAnim.to : listView.contentX
        var viewLeft  = refX
        var viewRight = refX + listView.width
        var margin    = root._edgeMargin

        var lastIdx  = listView.count - 1
        var lastItem = listView.itemAtIndex(lastIdx)
        var totalW
        if (lastItem) {
            totalW = lastItem.x + lastItem.width
        } else {
            totalW = listView.contentWidth + vpx(40)
        }
        var maxScroll = Math.max(0, totalW - listView.width)

        var target

        if (itemRight > viewRight - margin) {
            target = itemRight - listView.width + margin
        } else if (itemLeft < viewLeft + margin) {
            target = itemLeft - margin
        } else {
            return
        }

        target = Math.max(0, Math.min(target, maxScroll))

        scrollAnim.stop()
        scrollAnim.to = target
        scrollAnim.start()
    }

    onCurrentIndexChanged: Qt.callLater(_doScroll, currentIndex)

    Item {
        id: btnL1
        anchors {
            left: parent.left
            leftMargin: vpx(15)
            verticalCenter: parent.verticalCenter
        }
        width: vpx(46)
        height: vpx(40)

        property bool pressed: false

        readonly property string bgColor: btnL1.pressed
            ? themeManager.color("surfaceHover")
            : themeManager.color("iconPrimary")

        readonly property string fgColor: themeManager.currentTheme === "light"
            ? "#FFFFFF"
            : themeManager.color("surface")

        Canvas {
            id: canvasL1
            anchors.fill: parent

            Component.onCompleted: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var rBig   = height * 0.42
                var rSmall = height * 0.20
                var w = width, h = height
                ctx.beginPath()
                ctx.moveTo(rBig, 0)
                ctx.lineTo(w - rSmall, 0)
                ctx.arcTo(w, 0, w, rSmall, rSmall)
                ctx.lineTo(w, h - rSmall)
                ctx.arcTo(w, h, w - rSmall, h, rSmall)
                ctx.lineTo(rBig, h)
                ctx.arcTo(0, h, 0, h - rBig, rBig)
                ctx.lineTo(0, rBig)
                ctx.arcTo(0, 0, rBig, 0, rBig)
                ctx.closePath()
                ctx.fillStyle = btnL1.bgColor
                ctx.fill()
            }

            Connections {
                target: btnL1
                function onPressedChanged() { canvasL1.requestPaint() }
                function onBgColorChanged()  { canvasL1.requestPaint() }
            }
            Connections {
                target: themeManager
                function onCurrentThemeChanged() { canvasL1.requestPaint() }
            }
        }

        Text {
            anchors.centerIn: parent
            text:  "RB"
            color: btnL1.fgColor
            font {
                family:    globalFonts.condensed
                pixelSize: vpx(25)
                bold:      true
            }
        }

        MouseArea {
            anchors.fill: parent
            onPressed:  btnL1.pressed = true
            onReleased: btnL1.pressed = false
            onClicked: {
                if (root.currentIndex > 0)
                    root.collectionSelected(root.currentIndex - 1)
            }
        }
    }

    ListView {
        id: listView
        anchors {
            left: btnL1.right
            right: btnR1.left
            leftMargin: vpx(20)
            rightMargin: vpx(45)
            top: parent.top
            bottom: parent.bottom
        }

        orientation: ListView.Horizontal
        spacing: vpx(4)
        clip: true
        focus: false
        interactive: false
        cacheBuffer: 999999
        currentIndex: root.currentIndex
        model: root.collectionList

        delegate: Item {
            id: tabItem
            width: label.implicitWidth + vpx(30)
            height: listView.height

            property bool isActive: index === root.currentIndex
            property bool hovered: false

            Rectangle {
                anchors.centerIn: parent
                width: tabItem.width
                height: root.pillH
                radius: root.pillR
                color: tabItem.isActive ? themeManager.color("surfaceHighlight") : "transparent"
            }

            Text {
                id: label
                anchors.centerIn: parent
                text: modelData.shortName.toUpperCase()
                font {
                    family: globalFonts.condensed
                    pixelSize: vpx(32)
                    letterSpacing: vpx(1.2)
                    bold: tabItem.isActive
                }
                color: tabItem.isActive
                       ? themeManager.color("textPrimary")
                       : (tabItem.hovered ? themeManager.color("textSecondary") : themeManager.color("textTertiary"))
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: tabItem.hovered = true
                onExited: tabItem.hovered = false
                onClicked: root.collectionSelected(index)
            }
        }
    }

    Item {
        id: btnR1
        anchors {
            right: parent.right
            rightMargin: vpx(55)
            verticalCenter: parent.verticalCenter
        }
        width: vpx(46)
        height: vpx(40)

        property bool pressed: false

        readonly property string bgColor: btnR1.pressed
            ? themeManager.color("surfaceHover")
            : themeManager.color("iconPrimary")

        readonly property string fgColor: themeManager.currentTheme === "light"
            ? "#FFFFFF"
            : themeManager.color("surface")

        Canvas {
            id: canvasR1
            anchors.fill: parent

            Component.onCompleted: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var rBig   = height * 0.42
                var rSmall = height * 0.20
                var w = width, h = height
                ctx.beginPath()
                ctx.moveTo(rSmall, 0)
                ctx.lineTo(w - rBig, 0)
                ctx.arcTo(w, 0, w, rBig, rBig)
                ctx.lineTo(w, h - rBig)
                ctx.arcTo(w, h, w - rBig, h, rBig)
                ctx.lineTo(rSmall, h)
                ctx.arcTo(0, h, 0, h - rSmall, rSmall)
                ctx.lineTo(0, rSmall)
                ctx.arcTo(0, 0, rSmall, 0, rSmall)
                ctx.closePath()
                ctx.fillStyle = btnR1.bgColor
                ctx.fill()
            }

            Connections {
                target: btnR1
                function onPressedChanged() { canvasR1.requestPaint() }
                function onBgColorChanged()  { canvasR1.requestPaint() }
            }
            Connections {
                target: themeManager
                function onCurrentThemeChanged() { canvasR1.requestPaint() }
            }
        }

        Text {
            anchors.centerIn: parent
            text: "LB"
            color: btnR1.fgColor
            font {
                family: globalFonts.condensed
                pixelSize: vpx(25)
                bold: true
            }
        }

        MouseArea {
            anchors.fill: parent
            onPressed: btnR1.pressed = true
            onReleased: btnR1.pressed = false
            onClicked: {
                if (root.currentIndex < root.collectionList.length - 1)
                    root.collectionSelected(root.currentIndex + 1)
            }
        }
    }
}
