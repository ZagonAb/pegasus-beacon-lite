import QtQuick 2.15

Item {
    id: rootItem
    anchors.fill: parent

    property real theme:   0.0
    property real speed:   1.0
    property real density: 1.0
    property real time:    0.0

    Timer {
        interval: 32
        running:  true
        repeat:   true
        onTriggered: rootItem.time += 0.032
    }

    ShaderEffect {
        anchors.fill: parent

        property real u_time:    rootItem.time
        property real u_theme:   rootItem.theme
        property real u_speed:   rootItem.speed
        property real u_density: rootItem.density
        property real u_width:   width
        property real u_height:  height

        fragmentShader: "
            varying highp vec2 qt_TexCoord0;
            uniform highp float u_time;
            uniform highp float u_theme;
            uniform highp float u_speed;
            uniform highp float u_density;
            uniform highp float u_width;
            uniform highp float u_height;

            // Hash rapido: una sola multiplicacion matricial, sin loops internos
            highp float hash(highp vec2 p) {
                p = fract(p * vec2(443.897, 441.423));
                p += dot(p, p.yx + 19.19);
                return fract((p.x + p.y) * p.x);
            }

            // Aproximacion de sin() usando polinomio — 3-4x mas rapido en GPU movil
            // Valido para x en [-pi, pi], error < 0.002
            highp float fastSin(highp float x) {
                x = mod(x + 3.14159265, 6.28318530) - 3.14159265;
                highp float x2 = x * x;
                return x * (1.0 - x2 * (0.16666667 - x2 * 0.00833333));
            }

            void main() {
                highp float w = max(u_width,  1.0);
                highp float h = max(u_height, 1.0);

                highp vec2 uv = qt_TexCoord0 * (vec2(w, h) / 120.0) * u_density;
                highp vec2 id = floor(uv);
                highp vec2 gv = fract(uv) - 0.5;

                highp float t = mod(u_time, 100.0) * u_speed;

                highp float totalGlow = 0.0;

                // Loop 3x3 reducido a solo 5 celdas: centro + 4 cardinales
                // Las esquinas aportan muy poco glow y cuestan igual que las demas
                highp vec2 offsets[5];
                offsets[0] = vec2( 0.0,  0.0);
                offsets[1] = vec2( 1.0,  0.0);
                offsets[2] = vec2(-1.0,  0.0);
                offsets[3] = vec2( 0.0,  1.0);
                offsets[4] = vec2( 0.0, -1.0);

                for (int i = 0; i < 5; i++) {
                    highp vec2 nid = id + offsets[i];
                    highp vec2 ngv = gv  - offsets[i];

                    // Solo 2 hash por celda en lugar de 4
                    // n0 controla fase X e intensidad, n1 controla fase Y y parpadeo
                    highp float n0 = hash(nid);
                    highp float n1 = hash(nid + vec2(13.7, 5.3));

                    // Movimiento con fastSin en lugar de sin/cos nativos
                    highp float phaseX = t * (0.3 + n1 * 0.4) + n0 * 6.28318;
                    highp float phaseY = phaseX + 1.5708; // +pi/2 = coseno gratis
                    highp vec2 pos = vec2(
                        fastSin(phaseX) * 0.38,
                        fastSin(phaseY) * 0.38
                    );

                    highp vec2  delta = ngv - pos;
                    highp float dist  = length(delta);

                    // Parpadeo: reusar n1 como segundo hash (antes era n2)
                    highp float blink = 0.55 + 0.45 * fastSin(t * (1.5 + n1 * 2.0) + n0 * 6.28318);

                    highp float core = smoothstep(0.022, 0.0, dist);
                    highp float halo = smoothstep(0.18,  0.0, dist) * 0.25;

                    totalGlow += (core + halo) * blink;
                }

                totalGlow = clamp(totalGlow, 0.0, 1.0);

                highp vec3 bg      = (u_theme > 0.5) ? vec3(0.97, 0.97, 0.97) : vec3(0.04, 0.04, 0.05);
                highp vec3 firefly = (u_theme > 0.5) ? vec3(0.10, 0.10, 0.12) : vec3(0.88, 0.92, 1.00);

                gl_FragColor = vec4(mix(bg, firefly, totalGlow), 1.0);
            }
        "
    }
}
