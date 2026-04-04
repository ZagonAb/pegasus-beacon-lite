import QtQuick 2.15

Item {
    id: rootItem
    anchors.fill: parent

    property real theme: 0.0
    property real time: 0

    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: rootItem.time += 0.1
    }

    ShaderEffect {
        anchors.fill: parent

        property real u_time: rootItem.time
        property real u_theme: rootItem.theme

        fragmentShader: "
        uniform float u_time;
        uniform float u_theme;
        varying vec2 qt_TexCoord0;

        void main() {
        vec2 uv = qt_TexCoord0;

        float x = uv.x * 6.28318;

        float w1 = sin(x * 0.6  + u_time * 0.03) * 0.055
        + cos(x * 1.1  + u_time * 0.02) * 0.025;

        float w2 = sin(x * 1.3  - u_time * 0.05 + 1.0) * 0.045
        + sin(x * 0.5  - u_time * 0.03 + 2.5) * 0.030;

        float w3 = cos(x * 0.8  + u_time * 0.07 + 0.5) * 0.050
        + sin(x * 1.7  + u_time * 0.04 + 3.8) * 0.020;

        float y1 = 0.52 + w1;
        float y2 = 0.64 + w2;
        float y3 = 0.76 + w3;

        float edge = 0.002;
        float m1 = smoothstep(y1 - edge, y1 + edge, uv.y);
        float m2 = smoothstep(y2 - edge, y2 + edge, uv.y);
        float m3 = smoothstep(y3 - edge, y3 + edge, uv.y);

        vec3 bgColor = mix(vec3(0.0), vec3(1.0), u_theme);

        vec3 darkWave1  = vec3(0.32, 0.32, 0.32);
        vec3 darkWave2  = vec3(0.22, 0.22, 0.22);
        vec3 darkWave3  = vec3(0.14, 0.14, 0.14);

        vec3 lightWave1 = vec3(0.78, 0.78, 0.78);
        vec3 lightWave2 = vec3(0.65, 0.65, 0.65);
        vec3 lightWave3 = vec3(0.52, 0.52, 0.52);

        vec3 c1 = mix(darkWave1, lightWave1, u_theme);
        vec3 c2 = mix(darkWave2, lightWave2, u_theme);
        vec3 c3 = mix(darkWave3, lightWave3, u_theme);

        vec3 color = bgColor;
        color = mix(color, c1, m1);
        color = mix(color, c2, m2);
        color = mix(color, c3, m3);

        gl_FragColor = vec4(color, 1.0);
    }
    "
    }
}




