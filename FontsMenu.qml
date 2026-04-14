import QtQuick 2.15
import QtGraphicalEffects 1.15

Item {
    id: root

    property string currentFont: "roboto"
    property var anchorItem: null
    property string openDirection: "up"
    property string anchorAlignment: "center"
    property real anchorOffsetX: 0
    property real anchorOffsetY: 0

    signal fontSelected(string fontKey)
    signal menuClosed()

    readonly property string _memoryKey: "selectedFont"

    readonly property var _fonts: [
        { label: "Default", key: "default", preview: "Aa" },
        { label: "Montserrat", key: "montserrat", preview: "Aa" },
        { label: "Roboto", key: "roboto", preview: "Aa" },
        { label: "Lato", key: "lato", preview: "Aa" },
        { label: "Poppins", key: "poppins", preview: "Aa" },
        { label: "Inter", key: "inter", preview: "Aa" },
        { label: "Oswald", key: "oswald", preview: "Aa" },
        { label: "Raleway", key: "raleway", preview: "Aa" },
        { label: "Nunito", key: "nunito", preview: "Aa" },
        { label: "Playfair Display", key: "playfair", preview: "Aa" },
        { label: "Merriweather", key: "merriweather", preview: "Aa" },
        { label: "Kanit", key: "kanit", preview: "Aa" },
        { label: "Mukta", key: "mukta", preview: "Aa" },
        { label: "IBM Plex Mono", key: "ibm", preview: "Aa" },
        { label: "PT Serif", key: "ptserif", preview: "Aa" },
        { label: "DM Sans", key: "dmsans", preview: "Aa" },
        { label: "Heebo", key: "heebo", preview: "Aa" },
        { label: "Titillium Web", key: "titillium", preview: "Aa" },
        { label: "Hind", key: "hind", preview: "Aa" },
        { label: "Nanum Gothic", key: "nanumgothic", preview: "Aa" },
        { label: "Bebas Neue", key: "bebasneue", preview: "Aa" },
        { label: "Cairo", key: "cairo", preview: "Aa" },
        { label: "Space Grotesk", key: "spacegrotesk", preview: "Aa" },
        { label: "Anton", key: "anton", preview: "Aa" },
        { label: "EB Garamond", key: "ebgaramond", preview: "Aa" },
        { label: "Assistant", key: "assistant", preview: "Aa" },
        { label: "Maven Pro", key: "mavenpro", preview: "Aa" },
        { label: "Barlow Condensed", key: "barlow", preview: "Aa" },
        { label: "Crimson Text", key: "crimson", preview: "Aa" },
        { label: "Pacifico", key: "pacifico", preview: "Aa" },
        { label: "DM Serif Display", key: "dmserif", preview: "Aa" },
        { label: "Exo 2", key: "exo2", preview: "Aa" },
        { label: "Teko", key: "teko", preview: "Aa" },
        { label: "Prompt", key: "prompt", preview: "Aa" },
        { label: "Rajdhani", key: "rajdhani", preview: "Aa" },
        { label: "Fjalla One", key: "fjallaone", preview: "Aa" },
        { label: "Signika Negative", key: "signika", preview: "Aa" },
        { label: "Comfortaa", key: "comfortaa", preview: "Aa" },
        { label: "Arvo", key: "arvo", preview: "Aa" },
        { label: "Archivo", key: "archivo", preview: "Aa" },
        { label: "Caveat", key: "caveat", preview: "Aa" },
        { label: "Slabo 27px", key: "slabo", preview: "Aa" },
        { label: "Abril Fatface", key: "abrilfatface", preview: "Aa" },
        { label: "Shadows Into Light", key: "shadows", preview: "Aa" },
        { label: "Tajawal", key: "tajawal", preview: "Aa" },
        { label: "Red Hat Display", key: "redhat", preview: "Aa" },
        { label: "DotGothic16", key: "dotgothic", preview: "Aa" },
        { label: "Play", key: "play", preview: "Aa" },
        { label: "Pixelify Sans", key: "pixelify", preview: "Aa" },
        { label: "Tiny5", key: "tiny5", preview: "Aa" },
        { label: "Jacquard 12", key: "jacquard", preview: "Aa" }
    ]

    readonly property int _itemHeight: vpx(72)
    readonly property int _menuWidth: vpx(260)
    readonly property int _maxVisibleItems: 6
    readonly property int _visibleItems:    Math.min(_fonts.length, _maxVisibleItems)
    readonly property int _menuHeight:      _visibleItems * _itemHeight + vpx(12)

    FontLoader { id: _fl_montserrat; source: "assets/fonts/montserrat/montserrat.ttf" }
    FontLoader { id: _fl_roboto; source: "assets/fonts/roboto/roboto.ttf" }
    FontLoader { id: _fl_lato; source: "assets/fonts/lato/lato.ttf" }
    FontLoader { id: _fl_poppins; source: "assets/fonts/poppins/poppins.ttf" }
    FontLoader { id: _fl_inter; source: "assets/fonts/inter/inter.ttf" }
    FontLoader { id: _fl_oswald; source: "assets/fonts/oswald/oswald.ttf" }
    FontLoader { id: _fl_raleway; source: "assets/fonts/raleway/raleway.ttf" }
    FontLoader { id: _fl_nunito; source: "assets/fonts/nunito/nunito.ttf" }
    FontLoader { id: _fl_playfair; source: "assets/fonts/playfair/playfair.ttf" }
    FontLoader { id: _fl_merriweather; source: "assets/fonts/merriweather/merriweather.ttf" }
    FontLoader { id: _fl_kanit; source: "assets/fonts/kanit/kanit.ttf" }
    FontLoader { id: _fl_mukta; source: "assets/fonts/mukta/mukta.ttf" }
    FontLoader { id: _fl_ibm; source: "assets/fonts/ibm/ibmplexmono.ttf" }
    FontLoader { id: _fl_ptserif; source: "assets/fonts/pt_serif/ptserif.ttf" }
    FontLoader { id: _fl_dmsans; source: "assets/fonts/dm_sans/dmsans.ttf" }
    FontLoader { id: _fl_heebo; source: "assets/fonts/heebo/heebo.ttf" }
    FontLoader { id: _fl_titillium; source: "assets/fonts/titillium/titilliumweb.ttf" }
    FontLoader { id: _fl_hind; source: "assets/fonts/hind/hind.ttf" }
    FontLoader { id: _fl_nanumgothic; source: "assets/fonts/nanum_gothic/nanumgothic.ttf" }
    FontLoader { id: _fl_bebasneue; source: "assets/fonts/bebas_neue/bebasneue.ttf" }
    FontLoader { id: _fl_cairo; source: "assets/fonts/cairo/cairo.ttf" }
    FontLoader { id: _fl_spacegrotesk; source: "assets/fonts/space_grotesk/spacegrotesk.ttf" }
    FontLoader { id: _fl_anton; source: "assets/fonts/anton/anton.ttf" }
    FontLoader { id: _fl_ebgaramond; source: "assets/fonts/eb_garamond/ebgaramond.ttf" }
    FontLoader { id: _fl_assistant; source: "assets/fonts/assistant/assistant.ttf" }
    FontLoader { id: _fl_mavenpro; source: "assets/fonts/maven_pro/mavenpro.ttf" }
    FontLoader { id: _fl_barlow; source: "assets/fonts/barlow/barlowcondensed.ttf" }
    FontLoader { id: _fl_crimson; source: "assets/fonts/crimson_text/crimson.ttf" }
    FontLoader { id: _fl_pacifico; source: "assets/fonts/pacifico/pacifico.ttf" }
    FontLoader { id: _fl_dmserif; source: "assets/fonts/dm/dmserifdisplay.ttf" }
    FontLoader { id: _fl_exo2; source: "assets/fonts/exo2/exo2.ttf" }
    FontLoader { id: _fl_teko; source: "assets/fonts/teko/teko.ttf" }
    FontLoader { id: _fl_prompt; source: "assets/fonts/prompt/prompt.ttf" }
    FontLoader { id: _fl_rajdhani; source: "assets/fonts/rajdhani/rajdhani.ttf" }
    FontLoader { id: _fl_fjallaone; source: "assets/fonts/fjalla_one/fjallaone.ttf" }
    FontLoader { id: _fl_signika; source: "assets/fonts/signika/signikanegative.ttf" }
    FontLoader { id: _fl_comfortaa; source: "assets/fonts/comfortaa/comfortaa.ttf" }
    FontLoader { id: _fl_arvo; source: "assets/fonts/arvo/arvo.ttf" }
    FontLoader { id: _fl_archivo; source: "assets/fonts/archivo/archivo.ttf" }
    FontLoader { id: _fl_caveat; source: "assets/fonts/caveat/caveat.ttf" }
    FontLoader { id: _fl_slabo; source: "assets/fonts/slabo_27px/slabo27px.ttf" }
    FontLoader { id: _fl_abrilfatface; source: "assets/fonts/abril_fatface/abrilfatface.ttf" }
    FontLoader { id: _fl_shadows; source: "assets/fonts/shadows_into_light/shadowsintolight.ttf" }
    FontLoader { id: _fl_tajawal; source: "assets/fonts/tajawal/tajawal.ttf" }
    FontLoader { id: _fl_redhat; source: "assets/fonts/red_hat_display/redhatdisplay.ttf" }
    FontLoader { id: _fl_dotgothic; source: "assets/fonts/dotgothic16/dotgothic16.ttf" }
    FontLoader { id: _fl_play; source: "assets/fonts/play/play.ttf" }
    FontLoader { id: _fl_pixelify; source: "assets/fonts/pixelify/pixelify.ttf" }
    FontLoader { id: _fl_tiny5; source: "assets/fonts/tiny5/tiny5.ttf" }
    FontLoader { id: _fl_jacquard; source: "assets/fonts/jacquard/jacquard12.ttf" }

    function _familyForKey(key) {
        switch(key) {
            case "default": return global.fonts.sans
            case "montserrat": return _fl_montserrat.name
            case "lato": return _fl_lato.name
            case "poppins": return _fl_poppins.name
            case "inter": return _fl_inter.name
            case "oswald": return _fl_oswald.name
            case "raleway": return _fl_raleway.name
            case "nunito": return _fl_nunito.name
            case "playfair": return _fl_playfair.name
            case "merriweather": return _fl_merriweather.name
            case "kanit": return _fl_kanit.name
            case "mukta": return _fl_mukta.name
            case "ibm": return _fl_ibm.name
            case "ptserif": return _fl_ptserif.name
            case "dmsans": return _fl_dmsans.name
            case "heebo": return _fl_heebo.name
            case "titillium": return _fl_titillium.name
            case "hind": return _fl_hind.name
            case "nanumgothic": return _fl_nanumgothic.name
            case "bebasneue": return _fl_bebasneue.name
            case "cairo": return _fl_cairo.name
            case "spacegrotesk": return _fl_spacegrotesk.name
            case "anton": return _fl_anton.name
            case "ebgaramond": return _fl_ebgaramond.name
            case "assistant": return _fl_assistant.name
            case "mavenpro": return _fl_mavenpro.name
            case "barlow": return _fl_barlow.name
            case "crimson": return _fl_crimson.name
            case "pacifico": return _fl_pacifico.name
            case "dmserif": return _fl_dmserif.name
            case "exo2": return _fl_exo2.name
            case "teko": return _fl_teko.name
            case "prompt": return _fl_prompt.name
            case "rajdhani": return _fl_rajdhani.name
            case "fjallaone": return _fl_fjallaone.name
            case "signika": return _fl_signika.name
            case "comfortaa": return _fl_comfortaa.name
            case "arvo": return _fl_arvo.name
            case "archivo": return _fl_archivo.name
            case "caveat": return _fl_caveat.name
            case "slabo": return _fl_slabo.name
            case "abrilfatface": return _fl_abrilfatface.name
            case "shadows": return _fl_shadows.name
            case "tajawal": return _fl_tajawal.name
            case "redhat": return _fl_redhat.name
            case "dotgothic": return _fl_dotgothic.name
            case "play": return _fl_play.name
            case "pixelify": return _fl_pixelify.name
            case "tiny5": return _fl_tiny5.name
            case "jacquard": return _fl_jacquard.name
            default: return _fl_roboto.name
        }
    }

    function _saveToMemory(key) {
        var validKeys = ["montserrat", "roboto", "lato", "default", "poppins", "inter", "oswald",
        "raleway", "nunito", "playfair", "merriweather", "kanit", "mukta", "ibm",
        "ptserif", "dmsans", "heebo", "titillium", "hind", "nanumgothic", "bebasneue",
        "cairo", "spacegrotesk", "anton", "ebgaramond", "assistant", "mavenpro", "barlow",
        "crimson", "pacifico", "dmserif", "exo2", "teko", "prompt", "rajdhani", "fjallaone",
        "signika", "comfortaa", "arvo", "archivo", "caveat", "slabo", "abrilfatface",
        "shadows", "tajawal", "redhat", "dotgothic", "play", "pixelify", "tiny5", "jacquard"]
        if (validKeys.indexOf(key) !== -1)
            api.memory.set(_memoryKey, key)
    }

    function loadFromMemory() {
        var saved = api.memory.get(_memoryKey)
        var validKeys = ["montserrat", "roboto", "lato", "default", "poppins", "inter", "oswald",
        "raleway", "nunito", "playfair", "merriweather", "kanit", "mukta", "ibm",
        "ptserif", "dmsans", "heebo", "titillium", "hind", "nanumgothic", "bebasneue",
        "cairo", "spacegrotesk", "anton", "ebgaramond", "assistant", "mavenpro", "barlow",
        "crimson", "pacifico", "dmserif", "exo2", "teko", "prompt", "rajdhani", "fjallaone",
        "signika", "comfortaa", "arvo", "archivo", "caveat", "slabo", "abrilfatface",
        "shadows", "tajawal", "redhat", "dotgothic", "play", "pixelify", "tiny5", "jacquard"]
        if (validKeys.indexOf(saved) !== -1)
            currentFont = saved
            else
                currentFont = "default"
    }

    function open() {
        if (_open) return
            _open = true

            for (var i = 0; i < _fonts.length; i++) {
                if (_fonts[i].key === currentFont) {
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
                if (targetY < vpx(8))
                    targetY = _anchorBottomY + spacing + anchorOffsetY
            } else {
                targetY = _anchorTopY + spacing + anchorOffsetY
                if (targetY + root._menuHeight > root.height - vpx(8))
                    targetY = _anchorTopY - root._menuHeight - spacing + anchorOffsetY
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

        Rectangle { id: menuHeader; anchors { top: parent.top; left: parent.left; right: parent.right } }

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
            model: root._fonts

            delegate: Rectangle {
                id: itemDelegate
                width: menuList.width
                height: root._itemHeight
                radius: vpx(8)

                property bool isCurrent: ListView.isCurrentItem
                property bool isActive:  modelData.key === root.currentFont

                color: isCurrent ? themeManager.color("surfaceHover") : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                Rectangle {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
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
                        var chosen = modelData.key
                        root._saveToMemory(chosen)
                        root.currentFont = chosen
                        root.fontSelected(chosen)
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

                        Text {
                            anchors.centerIn: parent
                            text: "Aa"
                            font {
                                family: root._familyForKey(modelData.key)
                                pixelSize: vpx(16)
                                bold: isActive || isCurrent
                            }
                            color: isActive
                            ? themeManager.color("accent")
                            : isCurrent
                            ? themeManager.color("textPrimary")
                            : themeManager.color("textTertiary")
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: vpx(4)

                        Text {
                            text: modelData.label
                            font {
                                family: root._familyForKey(modelData.key)
                                pixelSize: vpx(22)
                                weight: (isActive || isCurrent) ? Font.DemiBold : Font.Normal
                            }
                            color: isActive || isCurrent
                            ? themeManager.color("textPrimary")
                            : themeManager.color("textTertiary")
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            text: isActive ? "Active" : "Sans-serif"
                            font {
                                family: global.fonts.sans
                                pixelSize: vpx(14)
                            }
                            color: isActive || isCurrent
                            ? themeManager.color("textSecondary")
                            : themeManager.color("textDisabled")
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
                if (currentIndex < _fonts.length - 1) {
                    incrementCurrentIndex()
                    positionViewAtIndex(currentIndex, ListView.Contain)
                }
                event.accepted = true
            }

            Keys.onPressed: {
                if (api.keys.isAccept(event)) {
                    event.accepted = true
                    var chosen = _fonts[currentIndex].key
                    root._saveToMemory(chosen)
                    root.currentFont = chosen
                    root.fontSelected(chosen)
                    root.close()
                    return
                }
                if (api.keys.isCancel(event)) {
                    event.accepted = true
                    root.close()
                    return
                }
            }
        }

        Rectangle {
            anchors { top: menuList.top; left: parent.left; right: parent.right }
            height: vpx(8)
            gradient: Gradient {
                GradientStop { position: 0.0; color: themeManager.color("surfaceElevated") }
                GradientStop { position: 1.0; color: "transparent" }
            }
            visible: menuList.contentY > 0
        }

        Rectangle {
            anchors { bottom: menuList.bottom; left: parent.left; right: parent.right }
            height: vpx(8)
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: themeManager.color("surfaceElevated") }
            }
            visible: menuList.contentY + menuList.height < menuList.contentHeight
        }
    }

    Component.onCompleted: loadFromMemory()
}
