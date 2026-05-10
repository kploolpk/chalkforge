import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Shapes
import HoldDetector 1.0

ApplicationWindow {
    visible: true
    width: 400
    height: 800
    title: "Chalkforge"

    color: "#1e1e1e"
    HoldDetector {
        id: detector
    }

    property var currentContour: []

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
            text: "Upload Wall"
            Layout.alignment: Qt.AlignHCenter
            onClicked: {
                fileDialog.open()
            }
        }
        FileDialog {
            id: fileDialog
            title: "Select a wall image"

            nameFilters: ["Images (*.png *.jpg *.jpeg)"]

            onAccepted: {
                wallImage.source = selectedFile
            }
        }
        Rectangle {
            id: container

            Layout.fillWidth: true
            Layout.preferredHeight: 350
            Layout.margins: 20

            color: "#2a2a2a"
            radius: 12
            clip: true

            border.color: "#444444"
            border.width: 2

            property real currentScale: 1.0

            function clampPosition() {

                let scaledWidth = wallImage.width * currentScale
                let scaledHeight = wallImage.height * currentScale

                // Horizontal clamp
                if (scaledWidth <= container.width) {

                    wallImage.x = (container.width - scaledWidth) / 2

                } else {

                    let minX = container.width - scaledWidth

                    if (wallImage.x > 0)
                        wallImage.x = 0

                    if (wallImage.x < minX)
                        wallImage.x = minX
                }

                // Vertical clamp
                if (scaledHeight <= container.height) {

                    wallImage.y = (container.height - scaledHeight) / 2

                } else {

                    let minY = container.height - scaledHeight

                    if (wallImage.y > 0)
                        wallImage.y = 0

                    if (wallImage.y < minY)
                        wallImage.y = minY
                }
            }

            PinchArea {
                anchors.fill: parent

                property real startScale: 1.0

                onPinchStarted: {
                    startScale = container.currentScale
                }

                onPinchUpdated: {

                    let newScale = startScale * pinch.scale

                    newScale = Math.max(1.0, Math.min(newScale, 5.0))

                    let scaleFactor = newScale / container.currentScale

                    // Zoom around pinch centre
                    wallImage.x = pinch.center.x
                                  - (pinch.center.x - wallImage.x) * scaleFactor

                    wallImage.y = pinch.center.y
                                  - (pinch.center.y - wallImage.y) * scaleFactor

                    container.currentScale = newScale

                    container.clampPosition()
                }

                Image {
                    id: wallImage

                    x: 0
                    y: 0

                    width: parent.width
                    height: parent.height

                    fillMode: Image.PreserveAspectCrop
                    smooth: true

                    transform: Scale {
                        origin.x: 0
                        origin.y: 0
                        xScale: container.currentScale
                        yScale: container.currentScale
                    }
                }
                Shape {

                    anchors.fill: parent

                    ShapePath {

                        strokeWidth: 3
                        strokeColor: "lime"
                        fillColor: "#3300ff00"

                        PathPolyline {

                            path: {

                                let pts = currentContour.map(function(p) {

                                    return Qt.point(
                                        wallImage.x
                                        + p.x * container.currentScale,

                                        wallImage.y
                                        + p.y * container.currentScale
                                    )
                                })

                                if (pts.length > 0)
                                    pts.push(pts[0])

                                return pts
                            }
                        }
                    }
                }
                Repeater {
                    model: holdModel

                    Rectangle {

                        width: 20
                        height: 20
                        radius: 10

                        color: "red"
                        border.color: "white"
                        border.width: 2

                        x: wallImage.x
                           + model.xPos
                           * wallImage.width
                           * container.currentScale
                           - width / 2

                        y: wallImage.y
                           + model.yPos
                           * wallImage.height
                           * container.currentScale
                           - height / 2
                    }
                }
                MouseArea {
                    anchors.fill: parent

                    property real lastX
                    property real lastY

                    onPressed: (mouse) => {
                        lastX = mouse.x
                        lastY = mouse.y
                    }

                    onPositionChanged: (mouse) => {

                        if (pressed) {

                            wallImage.x += mouse.x - lastX
                            wallImage.y += mouse.y - lastY

                            container.clampPosition()

                            lastX = mouse.x
                            lastY = mouse.y
                        }
                    }
                    onDoubleClicked: (mouse) => {

                        let imageX =
                            (mouse.x - wallImage.x)
                            / container.currentScale

                        let imageY =
                            (mouse.y - wallImage.y)
                            / container.currentScale

                        currentContour = detector.detectHold(
                            wallImage.source.toString(),
                            Math.floor(imageX),
                            Math.floor(imageY)
                        )

                        console.log(currentContour.length)
                    }
                }
            }

            Component.onCompleted: {
                container.clampPosition()
            }

            onWidthChanged: {
                container.clampPosition()
            }

            onHeightChanged: {
                container.clampPosition()
            }
        }
        ListModel {
            id: holdModel
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
