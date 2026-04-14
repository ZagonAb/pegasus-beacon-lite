import QtQuick 2.15
import QtGraphicalEffects 1.15

Item {
    id: btn

    property bool isFocused: false
    property string iconSource: ""
    property string labelText: ""
    property int btnRadius: 32

    signal activated()

    scale: isFocused ? 1.03 : 1.0
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

    Rectangle {
        anchors.fill: parent
        radius: btn.btnRadius
        color: btn.isFocused ? themeManager.color("accent") : themeManager.color("surfaceHighlight")
        Behavior on color { ColorAnimation { duration: 120 } }

        Row {
            anchors.centerIn: parent
            spacing: vpx(10)

            Item {
                width: vpx(26) + vpx(14) + labelTxt.implicitWidth
                height: vpx(26)
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    id: btnIcon
                    width: vpx(26)
                    height: vpx(26)
                    anchors.verticalCenter: parent.verticalCenter
                    source: btn.iconSource
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    visible: true
                }

                ColorOverlay {
                    anchors.fill: btnIcon
                    source: btnIcon
                    color: btn.isFocused ? themeManager.color("surface") : themeManager.color("iconPrimary")
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                Text {
                    id: labelTxt
                    anchors { left: btnIcon.right; leftMargin: vpx(14); verticalCenter: parent.verticalCenter }
                    text: btn.labelText
                    color: btn.isFocused ? themeManager.color("surface") : themeManager.color("textPrimary")
                    font { family: fontManager.currentFont; pixelSize: vpx(20); bold: true }
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: btn.activated()
    }
}
