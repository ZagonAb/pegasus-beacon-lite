import QtQuick 2.15

Item {
    id: rootItem
    anchors.fill: parent

    property real theme: 0.0
    property real speed: 1.0
    property real density: 1.0
    property real time: 0.0
    property color accentColor: "#88FFFFFF"

    Timer {
        interval: 33
        running: true
        repeat: true
        onTriggered: rootItem.time += 0.033
    }

    ShaderEffect {
        anchors.fill: parent

        property real u_time: rootItem.time
        property real u_theme: rootItem.theme
        property real u_speed: rootItem.speed
        property real u_density: rootItem.density
        property real u_width: width
        property real u_height: height
        property color u_accentColor: rootItem.accentColor

        fragmentShader: "
        #ifdef GL_ES
        precision highp float;
        #endif

        varying vec2 qt_TexCoord0;
        uniform float u_time;
        uniform float u_theme;
        uniform float u_speed;
        uniform float u_density;
        uniform float u_width;
        uniform float u_height;
        uniform vec4 u_accentColor;

        float hash(vec2 p) {
        return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
    }

    float fastSin(float x) {
    x = fract(x / 6.28318) * 6.28318 - 3.14159;
    float x2 = x * x;
    return x * (0.999996 - x2 * (0.166666 - x2 * 0.008333));
    }

    void main() {
    float w = max(u_width, 1.0);
    float h = max(u_height, 1.0);

    vec2 uv = qt_TexCoord0 * (vec2(w, h) / 160.0) * u_density;
    vec2 id = floor(uv);
    vec2 gv = fract(uv) - 0.5;

    float t = mod(u_time, 100.0) * u_speed;
    float totalGlow = 0.0;

    vec2 offsets[3];
    offsets[0] = vec2(0.0, 0.0);
    offsets[1] = vec2(1.0, 0.0);
    offsets[2] = vec2(0.0, 1.0);

    vec2 nid0 = id + offsets[0];
    vec2 ngv0 = gv - offsets[0];
    float n00 = hash(nid0);
    float n01 = hash(nid0 + vec2(13.7, 5.3));
    float phaseX0 = t * (0.3 + n01 * 0.4) + n00 * 6.28318;
    vec2 pos0 = vec2(fastSin(phaseX0), fastSin(phaseX0 + 1.5708)) * 0.38;
    float dist0 = length(ngv0 - pos0);
    float blink0 = 0.55 + 0.45 * fastSin(t * (1.5 + n01 * 2.0) + n00 * 6.28318);

    float core0 = clamp(1.0 - dist0 / 0.022, 0.0, 1.0);
    float halo0 = clamp(1.0 - dist0 / 0.18, 0.0, 1.0) * 0.25;
    totalGlow += (core0 + halo0) * blink0;

    vec2 nid1 = id + offsets[1];
    vec2 ngv1 = gv - offsets[1];
    float n10 = hash(nid1);
    float n11 = hash(nid1 + vec2(13.7, 5.3));
    float phaseX1 = t * (0.3 + n11 * 0.4) + n10 * 6.28318;
    vec2 pos1 = vec2(fastSin(phaseX1), fastSin(phaseX1 + 1.5708)) * 0.38;
    float dist1 = length(ngv1 - pos1);
    float blink1 = 0.55 + 0.45 * fastSin(t * (1.5 + n11 * 2.0) + n10 * 6.28318);
    float core1 = clamp(1.0 - dist1 / 0.022, 0.0, 1.0);
    float halo1 = clamp(1.0 - dist1 / 0.18, 0.0, 1.0) * 0.25;
    totalGlow += (core1 + halo1) * blink1;

    vec2 nid2 = id + offsets[2];
    vec2 ngv2 = gv - offsets[2];
    float n20 = hash(nid2);
    float n21 = hash(nid2 + vec2(13.7, 5.3));
    float phaseX2 = t * (0.3 + n21 * 0.4) + n20 * 6.28318;
    vec2 pos2 = vec2(fastSin(phaseX2), fastSin(phaseX2 + 1.5708)) * 0.38;
    float dist2 = length(ngv2 - pos2);
    float blink2 = 0.55 + 0.45 * fastSin(t * (1.5 + n21 * 2.0) + n20 * 6.28318);
    float core2 = clamp(1.0 - dist2 / 0.022, 0.0, 1.0);
    float halo2 = clamp(1.0 - dist2 / 0.18, 0.0, 1.0) * 0.25;
    totalGlow += (core2 + halo2) * blink2;

    totalGlow = min(totalGlow, 0.85);

    vec3 bg;
    vec3 fireflyColor;

    if (u_theme > 0.5) {
        bg = vec3(0.97, 0.97, 0.97);
        fireflyColor = u_accentColor.rgb * 0.35;
    } else {
        bg = vec3(0.04, 0.04, 0.05);
        fireflyColor = u_accentColor.rgb;
    }

    gl_FragColor = vec4(mix(bg, fireflyColor, totalGlow), 1.0);
    }
    "
    }
}
