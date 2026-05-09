import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 400
    height: 800
    title: "Chalkforge"

    color: "#1e1e1e"

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        Rectangle {
            Layout.fillWidth: true
            height: 70
            color: "#2b2b2b"

            Text {
                text: "Chalkforge"
                anchors.centerIn: parent
                color: "white"
                font.pixelSize: 28
                font.bold: true
            }
        }

        Button {
            text: "Upload Wall Image"
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: "Recent Walls"
            color: "white"
            font.pixelSize: 22

            Layout.leftMargin: 20
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true

            contentHeight: wallColumn.height

            Column {
                id: wallColumn
                width: parent.width
                spacing: 10

                Repeater {
                    model: 5

                    Rectangle {
                        width: parent.width - 40
                        height: 120
                        radius: 12
                        color: "#333333"

                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            text: "Wall " + (index + 1)
                            anchors.centerIn: parent
                            color: "white"
                        }
                    }
                }
            }
        }
    }
}
