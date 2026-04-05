import QtQuick 2.15

Item {
    id: rootItem
    anchors.fill: parent

    property real theme: 0.0
    property real speed: 1.0
    property real density: 1.0
    property real time: 0.0

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

        fragmentShader: "
        varying highp vec2 qt_TexCoord0;
        uniform highp float u_time;
        uniform mediump float u_theme;
        uniform mediump float u_speed;
        uniform mediump float u_density;
        uniform highp float u_width;
        uniform highp float u_height;

        highp float hash(highp vec2 p) {
            p = fract(p * vec2(443.897, 441.423));
            p += dot(p, p.yx + 19.19);
            return fract((p.x + p.y) * p.x);
        }

        void main() {
            highp float w = max(u_width, 1.0);
            highp float h = max(u_height, 1.0);
            highp vec2 res = vec2(w, h);

            highp vec2 uv = qt_TexCoord0 * (res / 120.0) * u_density;
            highp vec2 id = floor(uv);
            highp vec2 gv = fract(uv) - 0.5;

            highp float n = hash(id);
            highp float t = mod(u_time, 100.0) * u_speed;

            gv += vec2(sin(t + n * 6.2), cos(t * 0.8 + n * 6.2)) * 0.2;

            highp float d = 1.0;
            highp float size = 0.18;
            highp float thick = 0.04;

            if (n < 0.25) {
                // Circulo
                d = abs(length(gv) - size) - thick;

            } else if (n < 0.50) {
                // Cuadrado
                highp vec2 q = abs(gv) - size;
                d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - thick;

            } else if (n < 0.75) {
                // Triangulo equilatero apuntando hacia arriba
                highp vec2 p = gv;
                p.y -= size * 0.2;
                const highp float k = 1.7320508;
                highp float r = size * 1.1;
                p.x = abs(p.x) - r;
                p.y = p.y + r / k;
                if (p.x + k * p.y > 0.0)
                    p = vec2(p.x - k * p.y, -k * p.x - p.y) * 0.5;
                p.x -= clamp(p.x, -2.0 * r, 0.0);
                d = abs(-length(p) * sign(p.y)) - thick;

            } else {
                // Cruz X (rotada 45 grados)
                highp vec2 p = vec2(gv.x + gv.y, gv.x - gv.y) * 0.70711;
                highp float arm = size * 1.3;
                highp vec2 d1 = abs(p) - vec2(arm, thick);
                highp float a1 = length(max(d1, 0.0)) + min(max(d1.x, d1.y), 0.0);
                highp vec2 d2 = abs(p) - vec2(thick, arm);
                highp float a2 = length(max(d2, 0.0)) + min(max(d2.x, d2.y), 0.0);
                d = min(a1, a2) - thick * 0.3;
            }

            mediump float mask = smoothstep(0.02, -0.02, d);

            mediump vec3 colBg  = (u_theme > 0.5) ? vec3(0.95) : vec3(0.05);
            mediump vec3 colSym = (u_theme > 0.5) ? vec3(0.6)  : vec3(0.3);

            mediump vec3 finalCol = mix(colBg, colSym, mask * 0.4);

            gl_FragColor = vec4(finalCol, 1.0);
        }
        "
    }
}
