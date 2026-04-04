import QtQuick 2.15
import QtGraphicalEffects 1.15

Item {
    id: root

    property color reflectionColor: "#FFFFFF"
    property real reflectionWidth: 0.35
    property real intensity: 0.5
    property real glowOpacity: 0.8

    property real  cornerRadius: 0
    readonly property real _maskRadius: cornerRadius > 0 ? cornerRadius : width / 2

    function startAnimation() {
        _shader.reflectionProgress = 0.0
        _shader.timerRunning = true
        root.visible = true
    }

    function stopAnimation() {
        _shader.timerRunning = false
        _sweepTimer.stop()
        _fadeTimer.stop()
        root.visible = false
    }

    visible: false

    ShaderEffect {
        id: _shader
        anchors.fill: parent

        visible: false
        opacity: root.glowOpacity

        property real reflectionProgress: 0.0
        property color reflectionColor: root.reflectionColor
        property real reflectionWidth: root.reflectionWidth
        property real intensity: root.intensity
        property bool timerRunning: false

        Timer {
            id: _sweepTimer
            interval: 15
            running: _shader.timerRunning
            repeat: true
            onTriggered: {
                _shader.reflectionProgress += 0.04
                if (_shader.reflectionProgress >= 1.5) {
                    _shader.reflectionProgress = 1.5
                    _shader.timerRunning       = false
                    _fadeTimer.start()
                }
            }
        }

        Timer {
            id: _fadeTimer
            interval: 200
            onTriggered: root.visible = false
        }

        vertexShader: "
            uniform highp mat4 qt_Matrix;
            attribute highp vec4 qt_Vertex;
            attribute highp vec2 qt_MultiTexCoord0;
            varying highp vec2 coord;
            void main() {
                coord       = qt_MultiTexCoord0;
                gl_Position = qt_Matrix * qt_Vertex;
            }"

        fragmentShader: "
            varying highp vec2 coord;
            uniform lowp float qt_Opacity;
            uniform lowp float reflectionProgress;
            uniform lowp float reflectionWidth;
            uniform lowp float intensity;
            uniform lowp vec4  reflectionColor;

            void main() {
                // Una vez finalizado el barrido, píxel transparente
                if (reflectionProgress >= 1.5) {
                    gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
                    return;
                }

                // Posición del haz diagonal (esquina sup-izq → inf-der)
                highp float diagonal          = coord.x + coord.y;
                highp float reflectionPos     = diagonal * 0.5;
                highp float movingReflection  = reflectionProgress - reflectionPos;
                highp float dist              = abs(movingReflection);

                // Gradiente suavizado dentro del ancho del haz
                highp float g = (dist < reflectionWidth)
                    ? smoothstep(0.0, 1.0, 1.0 - dist / reflectionWidth)
                    : 0.0;

                highp float alpha = g * intensity * reflectionColor.a * qt_Opacity;
                gl_FragColor = vec4(reflectionColor.rgb * alpha, alpha);
            }"
    }

    OpacityMask {
        anchors.fill: _shader
        source: _shader
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: root._maskRadius
            visible: false
        }
    }
}
