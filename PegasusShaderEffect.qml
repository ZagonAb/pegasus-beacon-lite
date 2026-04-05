import QtQuick 2.15

Item {
    id: floatingLogos
    anchors.fill: parent

    property real theme: 0.0
    property int logoCount: 24

    Rectangle {
        anchors.fill: parent
        color: floatingLogos.theme === 1.0 ? "#FFFFFF" : "#000000"
        Behavior on color { ColorAnimation { duration: 300 } }
    }

    Repeater {
        model: logoCount

        Image {
            id: logo

            source: "assets/icon/logo.svg"
            width: 120
            height: 120
            mipmap: true
            opacity: 0.35

            property real vx: (Math.random() * 0.4) - 0.2
            property real vy: (Math.random() * 0.4) - 0.2

            x: Math.random() * floatingLogos.width
            y: Math.random() * floatingLogos.height

            Timer {
                interval: 32
                running: true
                repeat: true

                onTriggered: {
                    logo.x += logo.vx
                    logo.y += logo.vy

                    if (logo.x <= 0 || logo.x >= floatingLogos.width - logo.width)
                        logo.vx *= -1

                    if (logo.y <= 0 || logo.y >= floatingLogos.height - logo.height)
                        logo.vy *= -1
                }
            }
        }
    }
}
