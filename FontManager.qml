import QtQuick 2.15

Item {
    id: root

    readonly property string _memoryKey: "selectedFont"
    property string currentFont: _robotoLoader.name

    readonly property var _fonts: [
        { label: "Montserrat", key: "montserrat", source: "assets/fonts/montserrat/montserrat.ttf" },
        { label: "Roboto", key: "roboto", source: "assets/fonts/roboto/roboto.ttf" },
        { label: "Lato", key: "lato", source: "assets/fonts/lato/lato.ttf" },
        { label: "Poppins", key: "poppins", source: "assets/fonts/poppins/poppins.ttf" },
        { label: "Inter", key: "inter", source: "assets/fonts/inter/inter.ttf" },
        { label: "Oswald", key: "oswald", source: "assets/fonts/oswald/oswald.ttf" },
        { label: "Raleway", key: "raleway", source: "assets/fonts/raleway/raleway.ttf" },
        { label: "Nunito", key: "nunito", source: "assets/fonts/nunito/nunito.ttf" },
        { label: "Playfair Display", key: "playfair", source: "assets/fonts/playfair/playfair.ttf" },
        { label: "Merriweather", key: "merriweather", source: "assets/fonts/merriweather/merriweather.ttf" },
        { label: "Kanit", key: "kanit", source: "assets/fonts/kanit/kanit.ttf" },
        { label: "Mukta", key: "mukta", source: "assets/fonts/mukta/mukta.ttf" },
        { label: "IBM Plex Mono", key: "ibm", source: "assets/fonts/ibm/ibmplexmono.ttf" },
        { label: "PT Serif", key: "ptserif", source: "assets/fonts/pt_serif/ptserif.ttf" },
        { label: "DM Sans", key: "dmsans", source: "assets/fonts/dm_sans/dmsans.ttf" },
        { label: "Heebo", key: "heebo", source: "assets/fonts/heebo/heebo.ttf" },
        { label: "Titillium Web", key: "titillium", source: "assets/fonts/titillium/titilliumweb.ttf" },
        { label: "Hind", key: "hind", source: "assets/fonts/hind/hind.ttf" },
        { label: "Nanum Gothic", key: "nanumgothic", source: "assets/fonts/nanum_gothic/nanumgothic.ttf" },
        { label: "Bebas Neue", key: "bebasneue", source: "assets/fonts/bebas_neue/bebasneue.ttf" },
        { label: "Cairo", key: "cairo", source: "assets/fonts/cairo/cairo.ttf" },
        { label: "Space Grotesk", key: "spacegrotesk", source: "assets/fonts/space_grotesk/spacegrotesk.ttf" },
        { label: "Anton", key: "anton", source: "assets/fonts/anton/anton.ttf" },
        { label: "EB Garamond", key: "ebgaramond", source: "assets/fonts/eb_garamond/ebgaramond.ttf" },
        { label: "Assistant", key: "assistant", source: "assets/fonts/assistant/assistant.ttf" },
        { label: "Maven Pro", key: "mavenpro", source: "assets/fonts/maven_pro/mavenpro.ttf" },
        { label: "Barlow Condensed", key: "barlow", source: "assets/fonts/barlow/barlowcondensed.ttf" },
        { label: "Crimson Text", key: "crimson", source: "assets/fonts/crimson_text/crimson.ttf" },
        { label: "Pacifico", key: "pacifico", source: "assets/fonts/pacifico/pacifico.ttf" },
        { label: "DM Serif Display", key: "dmserif", source: "assets/fonts/dm/dmserifdisplay.ttf" },
        { label: "Exo 2", key: "exo2", source: "assets/fonts/exo2/exo2.ttf" },
        { label: "Teko", key: "teko", source: "assets/fonts/teko/teko.ttf" },
        { label: "Prompt", key: "prompt", source: "assets/fonts/prompt/prompt.ttf" },
        { label: "Rajdhani", key: "rajdhani", source: "assets/fonts/rajdhani/rajdhani.ttf" },
        { label: "Fjalla One", key: "fjallaone", source: "assets/fonts/fjalla_one/fjallaone.ttf" },
        { label: "Signika Negative", key: "signika", source: "assets/fonts/signika/signikanegative.ttf" },
        { label: "Comfortaa", key: "comfortaa", source: "assets/fonts/comfortaa/comfortaa.ttf" },
        { label: "Arvo", key: "arvo", source: "assets/fonts/arvo/arvo.ttf" },
        { label: "Archivo", key: "archivo", source: "assets/fonts/archivo/archivo.ttf" },
        { label: "Caveat", key: "caveat", source: "assets/fonts/caveat/caveat.ttf" },
        { label: "Slabo 27px", key: "slabo", source: "assets/fonts/slabo_27px/slabo27px.ttf" },
        { label: "Abril Fatface", key: "abrilfatface", source: "assets/fonts/abril_fatface/abrilfatface.ttf" },
        { label: "Shadows Into Light", key: "shadows", source: "assets/fonts/shadows_into_light/shadowsintolight.ttf" },
        { label: "Tajawal", key: "tajawal", source: "assets/fonts/tajawal/tajawal.ttf" },
        { label: "Red Hat Display", key: "redhat", source: "assets/fonts/red_hat_display/redhatdisplay.ttf" },
        { label: "DotGothic16", key: "dotgothic", source: "assets/fonts/dotgothic16/dotgothic16.ttf" },
        { label: "Play", key: "play", source: "assets/fonts/play/play.ttf" },
        { label: "Pixelify Sans", key: "pixelify", source: "assets/fonts/pixelify/pixelify.ttf" },
        { label: "Tiny5", key: "tiny5", source: "assets/fonts/tiny5/tiny5.ttf" },
        { label: "Jacquard 12", key: "jacquard", source: "assets/fonts/jacquard/jacquard12.ttf" }
    ]

    FontLoader { id: _montserratLoader; source: "assets/fonts/montserrat/montserrat.ttf" }
    FontLoader { id: _robotoLoader; source: "assets/fonts/roboto/roboto.ttf" }
    FontLoader { id: _latoLoader; source: "assets/fonts/lato/lato.ttf" }
    FontLoader { id: _poppinsLoader; source: "assets/fonts/poppins/poppins.ttf" }
    FontLoader { id: _interLoader; source: "assets/fonts/inter/inter.ttf" }
    FontLoader { id: _oswaldLoader; source: "assets/fonts/oswald/oswald.ttf" }
    FontLoader { id: _ralewayLoader; source: "assets/fonts/raleway/raleway.ttf" }
    FontLoader { id: _nunitoLoader;  source: "assets/fonts/nunito/nunito.ttf" }
    FontLoader { id: _playfairLoader; source: "assets/fonts/playfair/playfair.ttf" }
    FontLoader { id: _merriweatherLoader; source: "assets/fonts/merriweather/merriweather.ttf" }
    FontLoader { id: _kanitLoader; source: "assets/fonts/kanit/kanit.ttf" }
    FontLoader { id: _muktaLoader; source: "assets/fonts/mukta/mukta.ttf" }
    FontLoader { id: _ibmLoader; source: "assets/fonts/ibm/ibmplexmono.ttf" }
    FontLoader { id: _ptserifLoader; source: "assets/fonts/pt_serif/ptserif.ttf" }
    FontLoader { id: _dmsansLoader; source: "assets/fonts/dm_sans/dmsans.ttf" }
    FontLoader { id: _heeboLoader; source: "assets/fonts/heebo/heebo.ttf" }
    FontLoader { id: _titilliumLoader; source: "assets/fonts/titillium/titilliumweb.ttf" }
    FontLoader { id: _hindLoader; source: "assets/fonts/hind/hind.ttf" }
    FontLoader { id: _nanumgothicLoader; source: "assets/fonts/nanum_gothic/nanumgothic.ttf" }
    FontLoader { id: _bebasneueLoader; source: "assets/fonts/bebas_neue/bebasneue.ttf" }
    FontLoader { id: _cairoLoader; source: "assets/fonts/cairo/cairo.ttf" }
    FontLoader { id: _spacegroteskLoader; source: "assets/fonts/space_grotesk/spacegrotesk.ttf" }
    FontLoader { id: _antonLoader; source: "assets/fonts/anton/anton.ttf" }
    FontLoader { id: _ebgaramondLoader; source: "assets/fonts/eb_garamond/ebgaramond.ttf" }
    FontLoader { id: _assistantLoader; source: "assets/fonts/assistant/assistant.ttf" }
    FontLoader { id: _mavenproLoader; source: "assets/fonts/maven_pro/mavenpro.ttf" }
    FontLoader { id: _barlowLoader; source: "assets/fonts/barlow/barlowcondensed.ttf" }
    FontLoader { id: _crimsonLoader; source: "assets/fonts/crimson_text/crimson.ttf" }
    FontLoader { id: _pacificoLoader; source: "assets/fonts/pacifico/pacifico.ttf" }
    FontLoader { id: _dmserifLoader;source: "assets/fonts/dm/dmserifdisplay.ttf" }
    FontLoader { id: _exo2Loader; source: "assets/fonts/exo2/exo2.ttf" }
    FontLoader { id: _tekoLoader; source: "assets/fonts/teko/teko.ttf" }
    FontLoader { id: _promptLoader; source: "assets/fonts/prompt/prompt.ttf" }
    FontLoader { id: _rajdhaniLoader; source: "assets/fonts/rajdhani/rajdhani.ttf" }
    FontLoader { id: _fjallaoneLoader; source: "assets/fonts/fjalla_one/fjallaone.ttf" }
    FontLoader { id: _signikaLoader; source: "assets/fonts/signika/signikanegative.ttf" }
    FontLoader { id: _comfortaaLoader; source: "assets/fonts/comfortaa/comfortaa.ttf" }
    FontLoader { id: _arvoLoader; source: "assets/fonts/arvo/arvo.ttf" }
    FontLoader { id: _archivoLoader; source: "assets/fonts/archivo/archivo.ttf" }
    FontLoader { id: _caveatLoader; source: "assets/fonts/caveat/caveat.ttf" }
    FontLoader { id: _slaboLoader; source: "assets/fonts/slabo_27px/slabo27px.ttf" }
    FontLoader { id: _abrilfatfaceLoader; source: "assets/fonts/abril_fatface/abrilfatface.ttf" }
    FontLoader { id: _shadowsLoader; source: "assets/fonts/shadows_into_light/shadowsintolight.ttf" }
    FontLoader { id: _tajawalLoader; source: "assets/fonts/tajawal/tajawal.ttf" }
    FontLoader { id: _redhatLoader; source: "assets/fonts/red_hat_display/redhatdisplay.ttf" }
    FontLoader { id: _dotgothicLoader; source: "assets/fonts/dotgothic16/dotgothic16.ttf" }
    FontLoader { id: _playLoader; source: "assets/fonts/play/play.ttf" }
    FontLoader { id: _pixelifyLoader; source: "assets/fonts/pixelify/pixelify.ttf" }
    FontLoader { id: _tiny5Loader; source: "assets/fonts/tiny5/tiny5.ttf" }
    FontLoader { id: _jacquardLoader; source: "assets/fonts/jacquard/jacquard12.ttf" }

    function _nameForKey(key) {
        switch(key) {
            case "default": return global.fonts.sans
            case "montserrat": return _montserratLoader.name
            case "lato": return _latoLoader.name
            case "poppins": return _poppinsLoader.name
            case "inter": return _interLoader.name
            case "oswald": return _oswaldLoader.name
            case "raleway": return _ralewayLoader.name
            case "nunito": return _nunitoLoader.name
            case "playfair": return _playfairLoader.name
            case "merriweather": return _merriweatherLoader.name
            case "kanit": return _kanitLoader.name
            case "mukta": return _muktaLoader.name
            case "ibm": return _ibmLoader.name
            case "ptserif": return _ptserifLoader.name
            case "dmsans": return _dmsansLoader.name
            case "heebo": return _heeboLoader.name
            case "titillium": return _titilliumLoader.name
            case "hind": return _hindLoader.name
            case "nanumgothic": return _nanumgothicLoader.name
            case "bebasneue": return _bebasneueLoader.name
            case "cairo": return _cairoLoader.name
            case "spacegrotesk": return _spacegroteskLoader.name
            case "anton": return _antonLoader.name
            case "ebgaramond": return _ebgaramondLoader.name
            case "assistant": return _assistantLoader.name
            case "mavenpro": return _mavenproLoader.name
            case "barlow": return _barlowLoader.name
            case "crimson": return _crimsonLoader.name
            case "pacifico": return _pacificoLoader.name
            case "dmserif": return _dmserifLoader.name
            case "exo2": return _exo2Loader.name
            case "teko": return _tekoLoader.name
            case "prompt": return _promptLoader.name
            case "rajdhani": return _rajdhaniLoader.name
            case "fjallaone": return _fjallaoneLoader.name
            case "signika": return _signikaLoader.name
            case "comfortaa": return _comfortaaLoader.name
            case "arvo": return _arvoLoader.name
            case "archivo": return _archivoLoader.name
            case "caveat": return _caveatLoader.name
            case "slabo": return _slaboLoader.name
            case "abrilfatface": return _abrilfatfaceLoader.name
            case "shadows": return _shadowsLoader.name
            case "tajawal": return _tajawalLoader.name
            case "redhat": return _redhatLoader.name
            case "dotgothic": return _dotgothicLoader.name
            case "play": return _playLoader.name
            case "pixelify": return _pixelifyLoader.name
            case "tiny5": return _tiny5Loader.name
            case "jacquard": return _jacquardLoader.name
            default: return _robotoLoader.name
        }
    }

    function setFont(key) {
        var validKeys = ["montserrat", "roboto", "lato", "default", "poppins", "inter", "oswald",
        "raleway", "nunito", "playfair", "merriweather", "kanit", "mukta", "ibm",
        "ptserif", "dmsans", "heebo", "titillium", "hind", "nanumgothic", "bebasneue",
        "cairo", "spacegrotesk", "anton", "ebgaramond", "assistant", "mavenpro", "barlow",
        "crimson", "pacifico", "dmserif", "exo2", "teko", "prompt", "rajdhani", "fjallaone",
        "signika", "comfortaa", "arvo", "archivo", "caveat", "slabo", "abrilfatface",
        "shadows", "tajawal", "redhat", "dotgothic", "play", "pixelify", "tiny5", "jacquard"]
        if (validKeys.indexOf(key) === -1) return
            currentFont = _nameForKey(key)
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
            currentFont = _nameForKey(saved)
            else
                currentFont = global.fonts.sans
    }

    Component.onCompleted: loadFromMemory()
}
