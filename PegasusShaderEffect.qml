import QtQuick 2.15
import QtGraphicalEffects 1.15

Item {
    id: rootItem
    anchors.fill: parent

    property real theme: 0.0
    property real speed: 0.25
    property real density: 0.9
    property real time: 0.0
    property real logoScale: 1.1
    property real logoOpacity: 0.75
    property string imageSource: "assets/icon/logo.svg"

    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: rootItem.time += 0.016
    }

    Image {
        id: logoImage
        source: rootItem.imageSource
        visible: false
        asynchronous: false
        cache: true
        smooth: true

        onStatusChanged: {
            if (status === Image.Ready) {
                console.log("Logo cargado correctamente:", source);
            } else if (status === Image.Error) {
                console.error("Error cargando el logo:", source);
            }
        }
    }

    Image {
        source: rootItem.imageSource
        anchors.centerIn: parent
        width: 100
        height: 100
        visible: false
        opacity: 0.5
    }

    ShaderEffect {
        id: shaderEffect
        anchors.fill: parent

        property real u_time: rootItem.time
        property real u_theme: rootItem.theme
        property real u_speed: rootItem.speed
        property real u_density: rootItem.density
        property real u_scale: rootItem.logoScale
        property real u_opacity: rootItem.logoOpacity
        property real u_width: width
        property real u_height: height
        property variant u_texture: logoImage

        fragmentShader: "
        uniform highp float u_time;
        uniform highp float u_theme;
        uniform highp float u_speed;
        uniform highp float u_density;
        uniform highp float u_scale;
        uniform highp float u_opacity;
        uniform highp float u_width;
        uniform highp float u_height;
        uniform sampler2D u_texture;
        varying highp vec2 qt_TexCoord0;

        highp float hash(highp float n) {
        return fract(sin(n * 127.1) * 43758.5453);
    }

    highp vec2 rotate(highp vec2 p, highp float angle) {
    highp float ca = cos(angle);
    highp float sa = sin(angle);
    return vec2(ca * p.x - sa * p.y, sa * p.x + ca * p.y);
    }

    void main() {
    highp vec2 res = vec2(u_width, u_height);
    highp vec2 px = qt_TexCoord0 * res;

    // Colores según tema
    highp vec3 bgLight = vec3(0.96, 0.96, 0.97);
    highp vec3 bgDark  = vec3(0.0, 0.0, 0.0);
    highp vec3 bg = mix(bgDark, bgLight, u_theme);

    // Tamaño de cuadrícula dinámica
    highp float cellW = (res.x / 7.0) / u_density;
    highp float cellH = (res.y / 6.0) / u_density;

    int totalCols = int(res.x / cellW) + 3;
    int totalRows = int(res.y / cellH) + 3;

    highp float logoDim = min(cellW, cellH) * u_scale;
    highp float totalAlpha = 0.0;
    highp vec3 totalColor = vec3(0.0);

    int maxCols = min(totalCols, 14);
    int maxRows = min(totalRows, 12);

    for (int row = 0; row < 12; row++) {
        if (row >= maxRows) break;
        for (int col = 0; col < 14; col++) {
            if (col >= maxCols) break;

            highp float idx = float(row * 14 + col);
        highp float r0 = hash(idx);
        highp float r1 = hash(idx + 123.456);
        highp float r2 = hash(idx + 789.012);
        highp float r3 = hash(idx + 345.678);
        highp float r4 = hash(idx + 901.234);
        highp float r5 = hash(idx + 567.890);

        // Posición base con offset
        highp vec2 base;
        base.x = (float(col) + 0.5 + (r0 - 0.5) * 1.1) * cellW;
        base.y = (float(row) + 0.5 + (r1 - 0.5) * 1.1) * cellH;

        // Movimiento tipo órbita elíptica
        highp float orbitSpeed = 0.4 + r2 * 0.8;
        highp float orbitRadiusX = logoDim * (0.8 + r3 * 0.7);
        highp float orbitRadiusY = logoDim * (0.5 + r4 * 0.6);
        highp float orbitPhase = r5 * 6.28318;

        highp float orbitX = cos(u_time * orbitSpeed * u_speed + orbitPhase) * orbitRadiusX;
        highp float orbitY = sin(u_time * orbitSpeed * u_speed * 0.7 + orbitPhase * 1.3) * orbitRadiusY;

        // Movimiento de respiro adicional
        highp float breath = 0.8 + sin(u_time * 0.5 * u_speed + idx) * 0.2;

        highp vec2 center = base + vec2(orbitX * breath, orbitY * breath);

        // Rotación suave tipo mariposa
        highp float angle = sin(u_time * 0.6 * u_speed + base.x * 0.008) * 0.6 +
        cos(u_time * 0.5 * u_speed + base.y * 0.008) * 0.4 +
        r2 * 0.3;

        highp vec2 lp = (px - center) / logoDim;
        lp = rotate(lp, angle);
        lp += 0.5;

        // Efecto de destello según velocidad
        highp float speedFactor = clamp(abs(orbitX) / logoDim, 0.3, 1.0);

        if (lp.x >= 0.0 && lp.x <= 1.0 && lp.y >= 0.0 && lp.y <= 1.0) {
            highp vec4 texColor = texture2D(u_texture, lp);
            highp float alpha = texColor.a * (0.5 + breath * 0.3) * speedFactor;

            if (alpha > 0.05) {
                totalAlpha += alpha;
                totalColor += texColor.rgb * alpha;
    }
    }
    }
    }

    // Color del símbolo según tema
    highp vec3 symbolColor = mix(vec3(0.85, 0.85, 0.90), vec3(0.70, 0.70, 0.75), u_theme);

    highp vec3 finalColor;
    if (totalAlpha > 0.0) {
        finalColor = totalColor / totalAlpha;
    } else {
        finalColor = symbolColor;
    }

    // Aplicar opacidad global
    highp float intensity = clamp(totalAlpha * 0.4 * u_opacity, 0.0, 1.0);
    highp vec3 color = mix(bg, finalColor, intensity);

    gl_FragColor = vec4(color, 1.0);
    }
    "
    }
}
