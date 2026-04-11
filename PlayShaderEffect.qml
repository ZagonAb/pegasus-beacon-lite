import QtQuick 2.15

Item {
    id: rootItem
    anchors.fill: parent

    property real theme: 0.0
    property real speed: 1.0
    property real density: 1.0
    property real time: 0.0
    property color accentColor: "#FFFFFF"

    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: rootItem.time += 0.016
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
        p = fract(p * vec2(443.897, 441.423));
        p += dot(p, p.yx + 19.19);
        return fract((p.x + p.y) * p.x);
    }

    void main() {
    float w = max(u_width, 1.0);
    float h = max(u_height, 1.0);
    vec2 res = vec2(w, h);

    vec2 uv = qt_TexCoord0 * (res / 120.0) * u_density;
    vec2 id = floor(uv);
    vec2 gv = fract(uv) - 0.5;

    float n = hash(id);
    float t = mod(u_time, 100.0) * u_speed;

    gv += vec2(sin(t + n * 6.2), cos(t * 0.8 + n * 6.2)) * 0.2;

    float d = 1.0;
    float size = 0.18;
    float thick = 0.04;

    if (n < 0.25) {
        d = abs(length(gv) - size) - thick;
    } else if (n < 0.50) {
        vec2 q = abs(gv) - size;
        d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - thick;
    } else if (n < 0.75) {
        vec2 p = gv;
        p.y -= size * 0.2;
        const float k = 1.7320508;
        float r = size * 1.1;
        p.x = abs(p.x) - r;
        p.y = p.y + r / k;
        if (p.x + k * p.y > 0.0)
            p = vec2(p.x - k * p.y, -k * p.x - p.y) * 0.5;
        p.x -= clamp(p.x, -2.0 * r, 0.0);
        d = abs(-length(p) * sign(p.y)) - thick;
    } else {
        vec2 p = vec2(gv.x + gv.y, gv.x - gv.y) * 0.70711;
        float arm = size * 1.3;
        vec2 d1 = abs(p) - vec2(arm, thick);
        float a1 = length(max(d1, 0.0)) + min(max(d1.x, d1.y), 0.0);
        vec2 d2 = abs(p) - vec2(thick, arm);
        float a2 = length(max(d2, 0.0)) + min(max(d2.x, d2.y), 0.0);
        d = min(a1, a2) - thick * 0.3;
    }

    float mask = smoothstep(0.02, -0.02, d);

    vec3 colBg;
    vec3 colSym;

    if (u_theme > 0.5) {
        colBg = vec3(0.95);
        colSym = u_accentColor.rgb;
    } else {
        colBg = vec3(0.05);
        colSym = u_accentColor.rgb;
    }

    vec3 finalCol = mix(colBg, colSym, mask * 0.4);
    gl_FragColor = vec4(finalCol, 1.0);
    }
    "
    }
}
