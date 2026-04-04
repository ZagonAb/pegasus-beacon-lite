import QtQuick 2.15
import QtGraphicalEffects 1.15

Item {
    id: root

    property int currentViewMode: 0
    property var anchorItem: null
    property string openDirection: "up"
    property string anchorAlignment: "center"

    signal viewSelected(int mode)
    signal menuClosed()

    function open() {
        if (_open) return
            _open = true
            menuList.currentIndex = _modeToIndex(currentViewMode)
            menuList.forceActiveFocus()
    }

    function close() {
        if (!_open) return
            _open = false
            root.menuClosed()
    }

    function toggle() { if (_open) close(); else open() }

    property bool _open: false

    readonly property var _views: [
        { label: "Gallery", icon: "assets/icon/gallery.svg", mode: 0 },
        { label: "List", icon: "assets/icon/listview.svg", mode: 3 },
        { label: "Grid", icon: "assets/icon/gridview.svg", mode: 1 },
        { label: "Bubbles", icon: "assets/icon/bulles.svg", mode: 2 }
    ]

    function _modeToIndex(mode) {
        for (var i = 0; i < _views.length; i++)
            if (_views[i].mode === mode) return i
                return 0
    }

    readonly property int _itemH: vpx(80)
    readonly property int _menuW: vpx(220)
    readonly property int _menuH: _views.length * _itemH + vpx(16)
    property real anchorOffsetX: 0

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
                    return _mapped.x + (root.anchorItem ? root.anchorItem.width : 0) - root._menuW
                    return _anchorCX - root._menuW / 2
        }

        x: Math.max(vpx(8), Math.min(_rawX, root.width - root._menuW - vpx(8))) + anchorOffsetX

        property real _targetY: root.openDirection === "down"
        ? _anchorBottomY + vpx(8)
        : _anchorTopY - root._menuH - vpx(8)

        y: _targetY

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
                model: root._views
                clip: true
                interactive: false
                focus: root._open
                keyNavigationWraps: true

                Keys.onUpPressed: { decrementCurrentIndex(); event.accepted = true }
                Keys.onDownPressed: { incrementCurrentIndex(); event.accepted = true }
                Keys.onPressed: {
                    if (api.keys.isAccept(event)) {
                        event.accepted = true
                        root.viewSelected(root._views[currentIndex].mode)
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
                    property bool isActive: modelData.mode === root.currentViewMode
                    color: isCurrent ? themeManager.color("surfaceHover") : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: menuList.currentIndex = index
                        onClicked: {
                            root.viewSelected(modelData.mode)
                            root.close()
                        }
                    }

                    Row {
                        anchors { left: parent.left; leftMargin: vpx(18); verticalCenter: parent.verticalCenter }
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
                                color: row.isActive || row.isCurrent ? themeManager.color("iconPrimary") : themeManager.color("iconDisabled")
                            }
                        }

                        Text {
                            text: modelData.label
                            color: row.isActive || row.isCurrent ? themeManager.color("textPrimary") : themeManager.color("textTertiary")
                            font { family: global.fonts.sans; pixelSize: vpx(28); bold: row.isActive || row.isCurrent }
                            Behavior on color { ColorAnimation { duration: 120 } }
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
