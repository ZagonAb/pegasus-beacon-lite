varying highp vec2 qt_TexCoord0;
uniform highp float u_time;
uniform highp float u_theme;
uniform highp float u_speed;
uniform highp float u_density;
uniform highp float u_width;
uniform highp float u_height;

highp float hash(highp vec2 p) {
    p = fract(p * vec2(443.897, 441.423));
    p += dot(p, p.yx + 19.19);
    return fract((p.x + p.y) * p.x);
}

void main() {
    highp float w = max(u_width,  1.0);
    highp float h = max(u_height, 1.0);

    highp vec2 uv = qt_TexCoord0 * (vec2(w, h) / 120.0) * u_density;
    highp vec2 id = floor(uv);
    highp vec2 gv = fract(uv) - 0.5;

    highp float t = mod(u_time, 100.0) * u_speed;

    highp float totalGlow = 0.0;

    for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
            highp vec2 nid = id + vec2(float(dx), float(dy));
            highp vec2 ngv = gv  - vec2(float(dx), float(dy));

            highp float n0 = hash(nid);
            highp float n1 = hash(nid + vec2(13.7,  5.3));
            highp float n2 = hash(nid + vec2(27.1, 41.9));
            highp float n3 = hash(nid + vec2(61.3, 19.7));

            highp vec2 pos = vec2(
                sin(t * (0.3 + n1 * 0.4) + n0 * 6.28318) * 0.38,
                cos(t * (0.3 + n2 * 0.4) + n3 * 6.28318) * 0.38
            );

            highp vec2  delta = ngv - pos;
            highp float dist  = length(delta);

            highp float blink = 0.55 + 0.45 * sin(t * (1.5 + n2 * 2.0) + n0 * 6.28318);

            highp float core = smoothstep(0.022, 0.0, dist);
            highp float halo = smoothstep(0.18,  0.0, dist) * 0.25;

            totalGlow += (core + halo) * blink;
        }
    }

    totalGlow = clamp(totalGlow, 0.0, 1.0);

    highp vec3 bg      = (u_theme > 0.5) ? vec3(0.97, 0.97, 0.97) : vec3(0.04, 0.04, 0.05);
    highp vec3 firefly = (u_theme > 0.5) ? vec3(0.10, 0.10, 0.12) : vec3(0.88, 0.92, 1.00);

    gl_FragColor = vec4(mix(bg, firefly, totalGlow), 1.0);
}
