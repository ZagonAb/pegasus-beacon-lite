import QtQuick 2.15
import QtGraphicalEffects 1.15

Item {
    id: root

    property string currentColor: "default"
    property var anchorItem: null
    property string openDirection: "up"
    property string anchorAlignment: "center"
    property real anchorOffsetX: 0
    property real anchorOffsetY: 0

    signal colorSelected(string colorName)
    signal menuClosed()

    readonly property string _memoryKey: "themeColor"

    readonly property var _colors: [
        { label: "Emerald", colorValue: "#10B981", style: "emerald" },
        { label: "Amber", colorValue: "#F59E0B", style: "amber" },
        { label: "Fuchsia", colorValue: "#D946EF", style: "fuchsia" },
        { label: "Sky Blue", colorValue: "#0EA5E9", style: "skyblue" },
        { label: "Ruby", colorValue: "#EF4444", style: "ruby" },
        { label: "Purple", colorValue: "#8B5CF6", style: "purple" },
        { label: "Default", colorValue: "", style: "default" }
    ]

    readonly property int _itemHeight: vpx(72)
    readonly property int _menuWidth: vpx(220)
    readonly property int _maxVisibleItems: 4
    readonly property int _visibleItems: Math.min(_colors.length, _maxVisibleItems)
    readonly property int _menuHeight: _visibleItems * _itemHeight + vpx(12)

    function _saveToMemory(colorName) {
        if (colorName === "emerald" || colorName === "amber" || colorName === "fuchsia" ||
            colorName === "skyblue" || colorName === "ruby" || colorName === "purple" ||
            colorName === "default") {
            api.memory.set(_memoryKey, colorName)
            }
    }

    function loadFromMemory() {
        var saved = api.memory.get(_memoryKey)
        if (saved === "emerald" || saved === "amber" || saved === "fuchsia" ||
            saved === "skyblue" || saved === "ruby" || saved === "purple" ||
            saved === "default") {
            currentColor = saved
            } else {
                currentColor = "default"
            }
    }

    function open() {
        if (_open) return
            _open = true

            for (var i = 0; i < _colors.length; i++) {
                if (_colors[i].style === currentColor) {
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

        property real _anchorCX: _mapped.x + (root.anchorItem ? root.anchorItem.width / 2 : 0)
        property real _anchorTopY: _mapped.y
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

            model: root._colors

            delegate: Rectangle {
                id: itemDelegate
                width: menuList.width
                height: root._itemHeight
                radius: vpx(8)

                property bool isCurrent: ListView.isCurrentItem
                property bool isActive: modelData.style === root.currentColor

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
                        root.colorSelected(chosen)
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

                        Rectangle {
                            anchors.fill: parent
                            radius: vpx(6)
                            border.width: vpx(1)
                            border.color: themeManager.color("borderLight")
                            color: "transparent"
                        }

                        Image {
                            id: dropIcon
                            anchors.centerIn: parent
                            width: vpx(24)
                            height: vpx(24)
                            source: "assets/icon/drop.svg"
                            sourceSize: Qt.size(width, height)
                            fillMode: Image.PreserveAspectFit
                            visible: false
                        }

                        ColorOverlay {
                            anchors.fill: dropIcon
                            source: dropIcon
                            color: {
                                if (modelData.style === "default") {
                                    return themeManager.currentTheme === "dark" ? "#FFFFFF" : "#212529"
                                }
                                return modelData.colorValue
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
                                family: fontManager.currentFont
                                pixelSize: vpx(22)
                                weight: (isActive || isCurrent) ? Font.DemiBold : Font.Normal
                            }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            text: modelData.style === "default" ? "System default" : "Accent color"
                            color: {
                                if (isActive) return themeManager.color("textSecondary")
                                    if (isCurrent) return themeManager.color("textSecondary")
                                        return themeManager.color("textDisabled")
                            }
                            font {
                                family: fontManager.currentFont
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
                if (currentIndex < _colors.length - 1) {
                    incrementCurrentIndex()
                    positionViewAtIndex(currentIndex, ListView.Contain)
                }
                event.accepted = true
            }

            Keys.onPressed: {
                if (api.keys.isAccept(event)) {
                    event.accepted = true
                    var chosen = _colors[currentIndex].style
                    root._saveToMemory(chosen)
                    root.colorSelected(chosen)
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
                    var newIndex2 = Math.min(_colors.length - 1, currentIndex + _visibleItems)
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
