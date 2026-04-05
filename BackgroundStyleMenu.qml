import QtQuick 2.15
import QtGraphicalEffects 1.15

Item {
    id: root

    property string currentStyle: "background"
    property var anchorItem: null
    property string openDirection: "up"
    property string anchorAlignment: "center"
    property real anchorOffsetX: 0
    property real anchorOffsetY: 0

    signal styleSelected(string style)
    signal menuClosed()

    readonly property string _memoryKey: "backgroundStyle"

    readonly property var _styles: [
        {
            label: "Hills",
            icon: "assets/icon/hills.svg",
            style: "hills",
            hint: "Animated wave shader",
            description: "Dynamic waving hills effect"
        },
        {
            label: "PS Symbols",
            icon: "assets/icon/ps.svg",
            style: "ps-symbols",
            hint: "Animated geometric symbols",
            description: "PlayStation-inspired symbols"
        },
        {
            label: "Firefly",
            icon: "assets/icon/firefly.svg",
            style: "firefly",
            hint: "Firefly at night",
            description: "Magical fireflies effect"
        },
        {
            label: "Pegasus Frontend",
            icon: "assets/icon/pegasus.svg",
            style: "pegasus",
            hint: "Display the Pegasus logo",
            description: "Show Pegasus branding"
        },
        {
            label: "Background",
            icon: "assets/icon/background.svg",
            style: "background",
            hint: "Game art / screenshot",
            description: "Show game artwork"
        },
        {
            label: "Screenshot",
            icon: "assets/icon/screenshot.svg",
            style: "screenshot",
            hint: "Screenshot only",
            description: "Show game screenshots"
        }
    ]

    readonly property int _itemHeight: vpx(72)
    readonly property int _menuWidth: vpx(320)
    readonly property int _maxVisibleItems: 5
    readonly property int _visibleItems: Math.min(_styles.length, _maxVisibleItems)
    readonly property int _menuHeight: _visibleItems * _itemHeight + vpx(12)

    function _saveToMemory(style) {
        if (style === "hills" || style === "background" || style === "screenshot" ||
            style === "ps-symbols" || style === "firefly" || style === "pegasus") {
            api.memory.set(_memoryKey, style)
            }
    }

    function loadFromMemory() {
        var saved = api.memory.get(_memoryKey)
        if (saved === "hills" || saved === "background" || saved === "screenshot" ||
            saved === "ps-symbols" || saved === "firefly" || saved === "pegasus") {
            currentStyle = saved
            } else {
                currentStyle = "background"
            }
    }

    function open() {
        if (_open) return
            _open = true

            for (var i = 0; i < _styles.length; i++) {
                if (_styles[i].style === currentStyle) {
                    menuList.currentIndex = i
                    break
                }
            }

            Qt.callLater(function() {
                menuList.forceActiveFocus()
                menuList.positionViewAtIndex(menuList.currentIndex, ListView.Center)
            })
    }

    function close() {
        if (!_open) return
            _open = false
            root.menuClosed()
    }

    function toggle() {
        if (_open) close()
            else open()
    }

    property bool _open: false

    anchors.fill: parent
    visible: _open

    MouseArea {
        anchors.fill: parent
        enabled: root._open
        onClicked: root.close()
    }

    Rectangle {
        id: menuPanel

        property point _mapped: root.anchorItem && root._open
        ? root.anchorItem.mapToItem(root, 0, 0)
        : Qt.point(root.width / 2, root.height / 2)

        property real _anchorCX:      _mapped.x + (root.anchorItem ? root.anchorItem.width / 2 : 0)
        property real _anchorTopY:    _mapped.y
        property real _anchorBottomY: _mapped.y + (root.anchorItem ? root.anchorItem.height : 0)

        property real _rawX: {
            if (root.anchorAlignment === "left")
                return _mapped.x
                if (root.anchorAlignment === "right")
                    return _mapped.x + (root.anchorItem ? root.anchorItem.width : 0) - root._menuWidth
                    return _anchorCX - root._menuWidth / 2
        }

        x: Math.max(vpx(8), Math.min(_rawX + anchorOffsetX, root.width - root._menuWidth - vpx(8)))

        y: {
            var targetY
            var spacing = vpx(2)

            if (root.openDirection === "down") {
                targetY = _anchorBottomY - root._menuHeight - spacing + anchorOffsetY
                if (targetY < vpx(8)) {
                    targetY = _anchorBottomY + spacing + anchorOffsetY
                }
            } else {
                targetY = _anchorTopY + spacing + anchorOffsetY
                if (targetY + root._menuHeight > root.height - vpx(8)) {
                    targetY = _anchorTopY - root._menuHeight - spacing + anchorOffsetY
                }
            }
            return Math.max(vpx(8), Math.min(targetY, root.height - root._menuHeight - vpx(1)))
        }

        width: root._menuWidth
        height: root._menuHeight
        radius: vpx(12)
        color: themeManager.color("surfaceElevated")
        border { width: vpx(1); color: themeManager.color("borderLight") }

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: vpx(4)
            radius: vpx(16)
            samples: 32
            color: "#40000000"
            source: menuPanel
        }

        opacity: root._open ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Rectangle {
            id: menuHeader
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
        }

        ListView {
            id: menuList
            anchors {
                top: menuHeader.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: vpx(6)
            }
            clip: true
            focus: root._open
            keyNavigationWraps: true
            spacing: vpx(2)

            model: root._styles

            delegate: Rectangle {
                id: itemDelegate
                width: menuList.width
                height: root._itemHeight
                radius: vpx(8)

                property bool isCurrent: ListView.isCurrentItem
                property bool isActive: modelData.style === root.currentStyle

                color: isCurrent ? themeManager.color("surfaceHover") : "transparent"

                Behavior on color { ColorAnimation { duration: 120 } }

                Rectangle {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    width: isActive ? vpx(3) : 0
                    height: vpx(32)
                    radius: vpx(2)
                    color: themeManager.color("accent")
                    Behavior on width { NumberAnimation { duration: 160 } }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: menuList.currentIndex = index
                    onClicked: {
                        var chosen = modelData.style
                        root._saveToMemory(chosen)
                        root.styleSelected(chosen)
                        root.close()
                    }
                }

                Row {
                    anchors {
                        left: parent.left
                        leftMargin: vpx(16)
                        right: parent.right
                        rightMargin: vpx(12)
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: vpx(14)

                    Item {
                        width: vpx(36)
                        height: vpx(36)

                        Image {
                            id: itemIcon
                            anchors.fill: parent
                            source: modelData.icon
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            visible: false
                        }

                        ColorOverlay {
                            anchors.fill: itemIcon
                            source: itemIcon
                            color: {
                                if (isActive) return themeManager.color("accent")
                                    if (isCurrent) return themeManager.color("iconPrimary")
                                        return themeManager.color("iconDisabled")
                            }
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: vpx(4)

                        Text {
                            text: modelData.label
                            color: {
                                if (isActive) return themeManager.color("textPrimary")
                                    if (isCurrent) return themeManager.color("textPrimary")
                                        return themeManager.color("textTertiary")
                            }
                            font {
                                family: global.fonts.sans
                                pixelSize: vpx(22)
                                weight: (isActive || isCurrent) ? Font.DemiBold : Font.Normal
                            }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            text: modelData.hint
                            color: {
                                if (isActive) return themeManager.color("textSecondary")
                                    if (isCurrent) return themeManager.color("textSecondary")
                                        return themeManager.color("textDisabled")
                            }
                            font {
                                family: global.fonts.sans
                                pixelSize: vpx(14)
                            }
                            Behavior on color { ColorAnimation { duration: 120 } }
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
                if (currentIndex < _styles.length - 1) {
                    incrementCurrentIndex()
                    positionViewAtIndex(currentIndex, ListView.Contain)
                }
                event.accepted = true
            }

            Keys.onPressed: {
                if (api.keys.isAccept(event)) {
                    event.accepted = true
                    var chosen = _styles[currentIndex].style
                    root._saveToMemory(chosen)
                    root.styleSelected(chosen)
                    root.close()
                    return
                }
                if (api.keys.isCancel(event)) {
                    event.accepted = true
                    root.close()
                    return
                }

                if (event.key === Qt.Key_PageUp) {
                    event.accepted = true
                    var newIndex = Math.max(0, currentIndex - _visibleItems)
                    currentIndex = newIndex
                    positionViewAtIndex(currentIndex, ListView.Contain)
                }
                if (event.key === Qt.Key_PageDown) {
                    event.accepted = true
                    var newIndex2 = Math.min(_styles.length - 1, currentIndex + _visibleItems)
                    currentIndex = newIndex2
                    positionViewAtIndex(currentIndex, ListView.Contain)
                }
            }
        }

        Rectangle {
            anchors {
                top: menuList.top
                left: parent.left
                right: parent.right
            }
            height: vpx(8)
            gradient: Gradient {
                GradientStop { position: 0.0; color: themeManager.color("surfaceElevated") }
                GradientStop { position: 1.0; color: "transparent" }
            }
            visible: menuList.contentY > 0
        }

        Rectangle {
            anchors {
                bottom: menuList.bottom
                left: parent.left
                right: parent.right
            }
            height: vpx(8)
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: themeManager.color("surfaceElevated") }
            }
            visible: menuList.contentY + menuList.height < menuList.contentHeight
        }
    }

    Component.onCompleted: {
        loadFromMemory()
    }
}
