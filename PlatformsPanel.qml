import QtQuick 2.15
import QtGraphicalEffects 1.15

FocusScope {
    id: root

    signal backRequested()
    signal orderChanged()

    property int draggedIndex: -1
    property int draggedRealIdx: -1
    property real dragY: 0
    property bool dragActive: false
    property bool pendingDrag: false
    property bool gamepadGrab: false
    property var orderedIndices: []
    readonly property real itemStride: vpx(85) + vpx(6)
    readonly property real autoScrollZone: vpx(100)
    readonly property real autoScrollStep: vpx(8)

    function loadOrder() {
        var count = api.collections.count
        var saved = api.memory.get("collectionOrder")

        if (saved && Array.isArray(saved) && saved.length === count) {
            var copy = saved.slice().sort(function(a, b) { return a - b })
            var valid = true
            for (var i = 0; i < count; i++) {
                if (copy[i] !== i) { valid = false; break }
            }
            if (valid) {
                orderedIndices = saved.slice()
                return
            }
        }
        var def = []
        for (var j = 0; j < count; j++) def.push(j)
            orderedIndices = def
    }

    function saveOrder() {
        api.memory.set("collectionOrder", orderedIndices.slice())
        root.orderChanged()
    }

    function moveItem(fromPos, toPos) {
        if (fromPos === toPos) return
            fromPos = Math.max(0, Math.min(fromPos, orderedIndices.length - 1))
            toPos = Math.max(0, Math.min(toPos, orderedIndices.length - 1))
            var arr = orderedIndices.slice()
            var item = arr.splice(fromPos, 1)[0]
            arr.splice(toPos, 0, item)
            orderedIndices = arr
    }

    function tryAutoScroll(ghostYInList) {
        var maxContent = Math.max(0, platformList.contentHeight - platformList.height)

        if (ghostYInList > platformList.height - root.autoScrollZone) {
            platformList.contentY = Math.min(maxContent, platformList.contentY + root.autoScrollStep)
        } else if (ghostYInList < root.autoScrollZone) {
            platformList.contentY = Math.max(0, platformList.contentY - root.autoScrollStep)
        }
    }

    Component.onCompleted: {
        loadOrder()
        platformList.currentIndex = 0
    }

    ListView {
        id: platformList
        anchors {
            fill: parent
            topMargin: vpx(10)
            bottomMargin: vpx(10)
            leftMargin: vpx(14)
            rightMargin: vpx(14)
        }
        clip: true
        spacing: vpx(6)
        focus: root.activeFocus
        interactive: !root.dragActive && !root.pendingDrag && !root.gamepadGrab
        model: root.orderedIndices.length

        Keys.onUpPressed: {
            event.accepted = true
            if (root.gamepadGrab && currentIndex > 0) {
                var ni = currentIndex - 1
                root.moveItem(currentIndex, ni)
                currentIndex = ni
                positionViewAtIndex(currentIndex, ListView.Contain)
            } else if (!root.gamepadGrab) {
                decrementCurrentIndex()
            }
        }

        Keys.onDownPressed: {
            event.accepted = true
            if (root.gamepadGrab && currentIndex < root.orderedIndices.length - 1) {
                var ni2 = currentIndex + 1
                root.moveItem(currentIndex, ni2)
                currentIndex = ni2
                positionViewAtIndex(currentIndex, ListView.Contain)
            } else if (!root.gamepadGrab) {
                incrementCurrentIndex()
            }
        }

        Keys.onPressed: {
            if (api.keys.isCancel(event) || event.key === Qt.Key_Left) {
                event.accepted = true
                if (root.gamepadGrab) {
                    root.gamepadGrab = false
                    root.saveOrder()
                } else {
                    root.backRequested()
                }
                return
            }
            if (api.keys.isAccept(event)) {
                event.accepted = true
                if (!root.gamepadGrab) {
                    root.gamepadGrab = true
                } else {
                    root.gamepadGrab = false
                    root.saveOrder()
                }
                return
            }
        }

        highlight: Rectangle { radius: vpx(10); color: "transparent" }
        highlightMoveDuration: 140

        delegate: Item {
            id: delegateItem
            width: platformList.width
            height: vpx(85)

            property int listIndex: index
            property var collData: api.collections.get(root.orderedIndices[index] !== undefined ? root.orderedIndices[index] : 0)
            property bool isCurrent: ListView.isCurrentItem
            property bool isActive: isCurrent && root.activeFocus
            property bool isGrabbed: root.gamepadGrab && isCurrent
            property bool isDragging: root.dragActive && root.draggedIndex === index

            opacity: isDragging ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 80 } }

            Rectangle {
                id: itemBg
                anchors.fill: parent
                radius: vpx(10)
                color: delegateItem.isGrabbed ? themeManager.color("surfaceSelected")
                : delegateItem.isActive ? themeManager.color("surfaceHighlight")
                : themeManager.color("surface")
                border {
                    width: delegateItem.isGrabbed ? vpx(1) : 0
                    color: themeManager.color("accent")
                }
                Behavior on color { ColorAnimation { duration: 130 } }

                Item {
                    id: dragHandle
                    anchors {
                        left: parent.left
                        leftMargin: vpx(10)
                        verticalCenter: parent.verticalCenter
                    }
                    width: vpx(40)
                    height: parent.height

                    Image {
                        id: handleIcon
                        anchors.centerIn: parent
                        source: "assets/icon/select.svg"
                        width: vpx(32)
                        height: vpx(32)
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                        visible: true
                    }

                    ColorOverlay {
                        anchors.fill: handleIcon
                        source: handleIcon
                        color: handleArea.containsPress || delegateItem.isGrabbed
                        ? themeManager.color("accent")
                        : themeManager.color("iconDisabled")
                        Behavior on color { ColorAnimation { duration: 130 } }
                    }

                    MouseArea {
                        id: handleArea
                        anchors.fill: parent
                        propagateComposedEvents: false
                        preventStealing: true
                        pressAndHoldInterval: 350

                        onPressed: { root.pendingDrag = true }

                        onPressAndHold: {
                            if (root.dragActive) return
                                platformList.currentIndex = delegateItem.listIndex
                                root.draggedRealIdx = root.orderedIndices[delegateItem.listIndex]
                                root.draggedIndex = delegateItem.listIndex
                                root.dragActive = true
                                root.pendingDrag = false
                                var gpos = mapToItem(root, mouseX, mouseY)
                                root.dragY = gpos.y
                        }

                        onPositionChanged: {
                            if (!root.dragActive) return

                                var gpos = mapToItem(root, mouseX, mouseY)
                                root.dragY = gpos.y

                                var lpos = mapToItem(platformList, mouseX, mouseY)
                                root.tryAutoScroll(lpos.y)

                                var contentRelY = lpos.y + platformList.contentY
                                var targetIdx = Math.floor(contentRelY / root.itemStride)
                                targetIdx = Math.max(0, Math.min(targetIdx, root.orderedIndices.length - 1))

                                if (targetIdx !== root.draggedIndex) {
                                    root.moveItem(root.draggedIndex, targetIdx)

                                    for (var i = 0; i < root.orderedIndices.length; i++) {
                                        if (root.orderedIndices[i] === root.draggedRealIdx) {
                                            root.draggedIndex = i
                                            platformList.currentIndex = i
                                            break
                                        }
                                    }
                                }
                        }

                        onReleased: {
                            root.pendingDrag = false
                            if (!root.dragActive) return
                                root.dragActive = false
                                root.draggedIndex = -1
                                root.saveOrder()
                                platformList.positionViewAtIndex(platformList.currentIndex, ListView.Contain)
                        }

                        onCanceled: {
                            root.pendingDrag = false
                            if (!root.dragActive) return
                                root.dragActive = false
                                root.draggedIndex = -1
                                root.saveOrder()
                                platformList.positionViewAtIndex(platformList.currentIndex, ListView.Contain)
                        }
                    }
                }

                Rectangle {
                    id: badge
                    anchors {
                        left: dragHandle.right
                        leftMargin: vpx(6)
                        verticalCenter: parent.verticalCenter
                    }
                    width: vpx(65)
                    height: vpx(65)
                    radius: width / 2
                    color: delegateItem.isActive ? themeManager.color("surfaceHover") : themeManager.color("surfaceElevated")
                    Behavior on color { ColorAnimation { duration: 130 } }

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (!delegateItem.collData) return "?"
                                var sn = delegateItem.collData.shortName || delegateItem.collData.name
                                return sn.substring(0, 3).toUpperCase()
                        }
                        color: delegateItem.isActive ? themeManager.color("textPrimary") : themeManager.color("textSecondary")
                        font { family: fontManager.currentFont; pixelSize: vpx(18); bold: true }
                    }
                }

                Column {
                    anchors {
                        left: badge.right
                        leftMargin: vpx(12)
                        right: parent.right
                        rightMargin: vpx(16)
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: vpx(3)

                    Text {
                        width: parent.width
                        text: delegateItem.collData ? delegateItem.collData.name : ""
                        color: delegateItem.isActive ? themeManager.color("textPrimary") : themeManager.color("textSecondary")
                        elide: Text.ElideRight
                        font { family: fontManager.currentFont; pixelSize: vpx(28); bold: delegateItem.isActive }
                        Behavior on color { ColorAnimation { duration: 130 } }
                    }

                    Text {
                        text: delegateItem.collData ? (delegateItem.collData.games.count + " games") : ""
                        color: themeManager.color("textTertiary")
                        font { family: fontManager.currentFont; pixelSize: vpx(20) }
                    }
                }

                MouseArea {
                    anchors {
                        left: badge.left
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }
                    onClicked: platformList.currentIndex = delegateItem.listIndex
                }
            }
        }
    }

    Rectangle {
        id: ghostItem
        visible: root.dragActive
        z: 20
        width: platformList.width
        height: vpx(85)
        x: vpx(14)
        y: Math.max(platformList.y, Math.min(root.dragY - height / 2, platformList.y + platformList.height - height))
        radius: vpx(10)
        color: themeManager.color("surfaceSelected")
        border { width: vpx(1); color: themeManager.color("accent") }
        opacity: 0.93

        layer.enabled: true
        layer.effect: DropShadow {
            radius: vpx(12)
            samples: 17
            color: themeManager.currentTheme === "dark" ? "#80000000" : "#40AAAAAA"
            verticalOffset: vpx(4)
        }

        property var ghostData: {
            if (root.draggedRealIdx < 0 || root.draggedRealIdx >= api.collections.count)
                return null
                return api.collections.get(root.draggedRealIdx)
        }

        Row {
            anchors {
                left: parent.left
                leftMargin: vpx(10)
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(6)

            Image {
                id: ghostHandleIcon
                source: "assets/icon/select.svg"
                width: vpx(32)
                height: vpx(32)
                fillMode: Image.PreserveAspectFit
                smooth: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: vpx(65)
                height: vpx(65)
                radius: width / 2
                color: themeManager.color("surfaceHover")
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.centerIn: parent
                    text: {
                        if (!ghostItem.ghostData) return "?"
                            var sn = ghostItem.ghostData.shortName || ghostItem.ghostData.name
                            return sn.substring(0, 3).toUpperCase()
                    }
                    color: themeManager.color("textPrimary")
                    font { family: fontManager.currentFont; pixelSize: vpx(18); bold: true }
                }
            }

            Text {
                text: ghostItem.ghostData ? ghostItem.ghostData.name : ""
                color: themeManager.color("textPrimary")
                font { family: fontManager.currentFont; pixelSize: vpx(28); bold: true }
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
