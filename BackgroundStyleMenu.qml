import QtQuick 2.15
import QtGraphicalEffects 1.15

Item {
    id: root

    property string currentStyle: "background"
    property var anchorItem: null
    property string openDirection: "up"
    property string anchorAlignment: "center"
    property real anchorOffsetX: 0

    signal styleSelected(string style)
    signal menuClosed()

    readonly property string _memoryKey: "backgroundStyle"

    function _saveToMemory(style) {
        api.memory.set(_memoryKey, style)
    }

    function loadFromMemory() {
        var saved = api.memory.get(_memoryKey)
        if (saved === "hills" || saved === "background" || saved === "screenshot" ||
            saved === "ps-symbols" || saved === "pegasus")
            currentStyle = saved
            else
                currentStyle = "background"
    }

    function open() {
        if (_open) return
            _open = true
            menuList.forceActiveFocus()
    }

    function close() {
        if (!_open) return
            _open = false
            root.menuClosed()
    }

    function toggle() { if (_open) close(); else open() }

    property bool _open: false

    readonly property var _styles: [
        {
            label: "Hills",
            icon: "assets/icon/hills.svg",
            style: "hills",
            hint: "Animated wave shader"
        },
        {
            label: "PS Symbols",
            icon: "assets/icon/ps.svg",
            style: "ps-symbols",
            hint: "Animated geometric symbols"
        },
        {
            label: "Pegasus",
            icon: "assets/icon/pegasus.svg",
            style: "pegasus",
            hint: "Flying Pegasus logos"
        },
        {
            label: "Background",
            icon: "assets/icon/background.svg",
            style: "background",
            hint: "Game art / screenshot"
        },
        {
            label: "Screenshot",
            icon: "assets/icon/screenshot.svg",
            style: "screenshot",
            hint: "Screenshot only"
        }
    ]

    readonly property int _itemH:  vpx(70)
    readonly property int _menuW:  vpx(260)
    readonly property int _menuH:  _styles.length * _itemH + vpx(16)

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

        property real _anchorCX:      _mapped.x + (root.anchorItem ? root.anchorItem.width  / 2 : 0)
        property real _anchorTopY:    _mapped.y
        property real _anchorBottomY: _mapped.y + (root.anchorItem ? root.anchorItem.height : 0)

        property real _rawX: {
            if (root.anchorAlignment === "left")
                return _mapped.x
                if (root.anchorAlignment === "right")
                    return _mapped.x + (root.anchorItem ? root.anchorItem.width : 0) - root._menuW
                    return _anchorCX - root._menuW / 2
        }

        x: Math.max(vpx(8), Math.min(_rawX, root.width - root._menuW - vpx(8))) + anchorOffsetX
        y: root.openDirection === "down"
        ? _anchorBottomY + vpx(8)
        : _anchorTopY - root._menuH - vpx(8)

        width: root._menuW
        height: root._menuH
        radius: vpx(6)
        color: themeManager.color("surfaceElevated")
        border { width: vpx(1); color: themeManager.color("borderLight") }

        opacity: root._open ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        Item {
            anchors { fill: parent; margins: vpx(8) }

            ListView {
                id: menuList
                anchors.fill: parent
                model: root._styles
                clip: true
                interactive: false
                focus: root._open
                keyNavigationWraps: true

                Keys.onUpPressed: { decrementCurrentIndex(); event.accepted = true }
                Keys.onDownPressed: { incrementCurrentIndex(); event.accepted = true }

                Keys.onPressed: {
                    if (api.keys.isAccept(event)) {
                        event.accepted = true
                        var chosen = root._styles[currentIndex].style
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
                }

                delegate: Rectangle {
                    id: row
                    width: menuList.width
                    height: root._itemH
                    radius: vpx(4)

                    property bool isCurrent: ListView.isCurrentItem
                    property bool isActive:  modelData.style === root.currentStyle

                    color: isCurrent ? themeManager.color("surfaceHover") : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

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
                            leftMargin: vpx(18)
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: vpx(14)

                        Image {
                            source: modelData.icon
                            width: vpx(32)
                            height: vpx(32)
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: row.isActive
                                ? themeManager.color("iconPrimary")
                                : row.isCurrent
                                ? themeManager.color("iconPrimary")
                                : themeManager.color("iconDisabled")
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: vpx(2)

                            Text {
                                text:  modelData.label
                                color: row.isActive
                                ? themeManager.color("textPrimary")
                                : row.isCurrent
                                ? themeManager.color("textPrimary")
                                : themeManager.color("textTertiary")
                                font {
                                    family: global.fonts.sans
                                    pixelSize: vpx(26)
                                    bold: row.isActive || row.isCurrent
                                }
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            Text {
                                text:  modelData.hint
                                color: row.isActive
                                ? themeManager.color("textSecondary")
                                : themeManager.color("textDisabled")
                                font {
                                    family: global.fonts.sans
                                    pixelSize: vpx(16)
                                }
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                        }
                    }
                }
            }
        }
    }
}
