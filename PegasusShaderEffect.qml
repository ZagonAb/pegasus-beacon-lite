import QtQuick 2.15
import QtGraphicalEffects 1.15

Item {
    id: floatingLogos
    anchors.fill: parent

    property real theme: 0.0
    property int logoCount: 24
    property color accentColor: "#FFFFFF"

    Rectangle {
        anchors.fill: parent
        color: floatingLogos.theme === 1.0 ? "#FFFFFF" : "#000000"
        Behavior on color { ColorAnimation { duration: 300 } }
    }

    Repeater {
        model: logoCount

        Item {
            id: logoContainer
            width: 120
            height: 120
            x: Math.random() * floatingLogos.width
            y: Math.random() * floatingLogos.height

            property real vx: (Math.random() * 0.4) - 0.2
            property real vy: (Math.random() * 0.4) - 0.2

            Image {
                id: logoImage
                anchors.fill: parent
                source: "assets/icon/logo.svg"
                fillMode: Image.PreserveAspectFit
                mipmap: true
                opacity: 0.35
                visible: true
            }

            Glow {
                anchors.fill: logoImage
                source: logoImage
                color: floatingLogos.accentColor
                radius: 0
                samples: 0
                spread: 0
                opacity: 0.6
                visible: floatingLogos.accentColor !== "#FFFFFF"
            }

            Timer {
                interval: 32
                running: true
                repeat: true

                onTriggered: {
                    logoContainer.x += logoContainer.vx
                    logoContainer.y += logoContainer.vy

                    if (logoContainer.x <= 0 || logoContainer.x >= floatingLogos.width - logoContainer.width)
                        logoContainer.vx *= -1

                        if (logoContainer.y <= 0 || logoContainer.y >= floatingLogos.height - logoContainer.height)
                            logoContainer.vy *= -1
                }
            }
        }
    }
}
