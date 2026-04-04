import QtQuick 2.15

Item {
    id: rootItem
    anchors.fill: parent

    property real theme: 0.0
    property real speed: 3.0
    property real density: 1.0
    property real time: 0.0
    property real cornerRadius: 0.3

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
        property real u_corner: rootItem.cornerRadius

        fragmentShader: "
        uniform highp float u_time;
        uniform highp float u_theme;
        uniform highp float u_speed;
        uniform highp float u_density;
        uniform highp float u_width;
        uniform highp float u_height;
        uniform highp float u_corner;
        varying highp vec2 qt_TexCoord0;

        highp float hash(highp float n) {
        return fract(sin(n * 127.1) * 43758.5453);
    }

    // Ancho de trazo = 2·thick (referencia para los demás)
    highp float sdfCircle(highp vec2 p, highp float r, highp float thick) {
    return abs(length(p) - r) - thick;
    }

    // SDF euclídeo exacto (Inigo Quilez). Negativo dentro, positivo fuera.
    highp float sdEquilTri(highp vec2 p, highp float r) {
    highp float k = 1.73205;
    p.x = abs(p.x) - r;
    p.y = p.y + r / k;
    if (p.x + k * p.y > 0.0)
        p = vec2(p.x - k * p.y, -k * p.x - p.y) * 0.5;
        p.x -= clamp(p.x, -2.0 * r, 0.0);
    return -length(p) * sign(p.y);
    }
    // cr  → radio de esquinas (expansión del contorno → redondea vértices)
    // Trazo = abs(sdf_redondeado) - thick  →  ancho uniforme = 2·thick
    highp float sdfTriangle(highp vec2 p, highp float r,
    highp float thick, highp float cr) {
    highp float d = sdEquilTri(p, r) - cr;
    return abs(d) - thick;
    }

    // Caja redondeada de semi-lado r y radio de esquina cr.
    highp float sdRoundBox(highp vec2 p, highp float r, highp float cr) {
    highp vec2 d = abs(p) - vec2(r - cr);
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - cr;
    }
    // Mismo patrón abs() → trazo uniforme = 2·thick
    highp float sdfSquare(highp vec2 p, highp float r,
    highp float thick, highp float cr) {
    highp float d = sdRoundBox(p, r, cr);
    return abs(d) - thick;
    }

    // Rectángulo redondeado (caps en extremos de cada brazo).
    // cr debe ser <= thick para que los caps queden dentro del brazo.
    highp float sdRoundRect(highp vec2 p, highp vec2 b, highp float cr) {
    highp vec2 d = abs(p) - b + vec2(cr);
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - cr;
    }
    // La X es un + girado 45°.  Ancho de brazo = 2·thick → igual al círculo.
    highp float sdfCross(highp vec2 p, highp float r,
    highp float thick, highp float cr) {
    highp vec2 q = vec2(p.x + p.y, p.x - p.y) * 0.70711;
    highp float arm1 = sdRoundRect(q, vec2(r, thick), cr);
    highp float arm2 = sdRoundRect(q, vec2(thick, r), cr);
    return min(arm1, arm2);
    }

    void main() {
    highp vec2 res = vec2(u_width, u_height);
    highp vec2 px  = qt_TexCoord0 * res;

    highp vec3 bgLight = vec3(0.96, 0.96, 0.97);
    highp vec3 bgDark  = vec3(0.0,  0.0,  0.0);
    highp vec3 bg = mix(bgDark, bgLight, u_theme);

    highp vec3 symLight = vec3(0.65, 0.65, 0.70);
    highp vec3 symDark  = vec3(0.30, 0.30, 0.38);
    highp vec3 symColor = mix(symDark, symLight, u_theme);

    // density achica las celdas → más símbolos en pantalla
    const int COLS = 7;
    const int ROWS = 6;
    highp float cellW = (res.x / float(COLS)) / u_density;
    highp float cellH = (res.y / float(ROWS)) / u_density;

    // calcular cuántas celdas caben realmente
    int totalCols = int(res.x / cellW) + 2;
    int totalRows = int(res.y / cellH) + 2;

    highp float SZ    = min(cellW, cellH) * 0.23;
    highp float THICK = SZ * 0.17;
    // u_corner: rango sugerido 0.0 → 3.0
    // CR_cross se mantiene siempre < THICK para que los caps no se desborden
    highp float CR_shape = THICK * u_corner;
    highp float CR_cross = THICK * u_corner * 0.57;

    highp float totalMask = 0.0;

    for (int row = 0; row < 14; row++) {
        if (float(row) >= float(totalRows)) break;
        for (int col = 0; col < 16; col++) {
            if (float(col) >= float(totalCols)) break;

            highp float idx = float(row * 16 + col);

        highp float r0 = hash(idx * 1.0);
        highp float r1 = hash(idx * 2.0 + 111.0);
        highp float r2 = hash(idx * 3.0 + 222.0);
        highp float r3 = hash(idx * 4.0 + 333.0);
        highp float r4 = hash(idx * 5.0 + 444.0);
        highp float r5 = hash(idx * 6.0 + 555.0);

        int kind = int(floor(r0 * 4.0));

        highp vec2 base;
        base.x = (float(col) + 0.5 + (r1 - 0.5) * 1.20) * cellW;
        base.y = (float(row) + 0.5 + (r2 - 0.5) * 1.20) * cellH;

        highp float driftAng = r3 * 6.28318;
        highp float driftSpd = (0.15 + r4 * 0.20) * u_speed;
        highp vec2 drift;
        drift.x = cos(driftAng + u_time * driftSpd) * SZ * 1.25;
        drift.y = sin(driftAng + u_time * driftSpd * 0.75) * SZ * 1.25;

        highp vec2 center = base + drift;

        highp float rotSpd = (r5 - 0.5) * 0.55 * u_speed;
        highp float angle  = r3 * 6.28318 + u_time * rotSpd;
        highp float ca = cos(angle);
        highp float sa = sin(angle);

        highp vec2 lp = px - center;
        lp = vec2( ca * lp.x + sa * lp.y,
        -sa * lp.x + ca * lp.y);

        highp float d = 9999.0;
        if (kind == 0) d = sdfCircle(lp,   SZ, THICK);
        if (kind == 1) d = sdfTriangle(lp,  SZ, THICK, CR_shape);
        if (kind == 2) d = sdfSquare(lp,    SZ, THICK, CR_shape);
        if (kind == 3) d = sdfCross(lp, SZ * 1.4, THICK, CR_cross);

        highp float mask = 1.0 - smoothstep(-0.8, 0.8, d);
        totalMask = totalMask + mask * 0.95;
    }
    }

    highp vec3 color = mix(bg, symColor, totalMask * 0.35);
    gl_FragColor = vec4(color, 1.0);
    }
    "
    }
}


