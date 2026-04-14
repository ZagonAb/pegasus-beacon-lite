import QtQuick 2.15

Item {
    id: fb
    property string buttonText: ""
    property string labelText: ""
    signal clicked()

    implicitWidth: btnCircle.width + (labelText !== "" ? lbl.implicitWidth + vpx(6) : 0)
    implicitHeight: vpx(32)

    Rectangle {
        id: btnCircle
        width: vpx(31)
        height: vpx(31)
        radius: vpx(24)
        color: themeManager.color("iconPrimary")
        border { width: vpx(1); color: themeManager.color("iconPrimary") }
        anchors.verticalCenter: parent.verticalCenter

        Text {
            anchors.centerIn: parent
            text: fb.buttonText
            color: themeManager.color("surface")
            font {
                family: fontManager.currentFont
                pixelSize: vpx(22)
                bold: true
            }
        }
    }

    Text {
        id: lbl
        anchors {
            left: btnCircle.right
            leftMargin: vpx(6)
            verticalCenter: parent.verticalCenter
        }
        visible: fb.labelText !== ""
        text: fb.labelText
        color: themeManager.color("textPrimary")
        font {
            family: fontManager.currentFont
            pixelSize: vpx(26)
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: fb.clicked()
    }
}
