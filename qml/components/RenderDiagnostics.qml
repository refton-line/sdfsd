import QtQuick
import QtQuick.Window
import QtQuick.Shapes
import FakeClicker
import "Icons.js" as Icons
Window {
    id: win
    width: 1280; height: 1040; visible: true
    readonly property bool dark: Qt.application.arguments.indexOf("--dark-icons") >= 0
    readonly property color fg: dark ? "#f5f5f7" : "#202023"
    color: dark ? "#101012" : "#f3f3f6"
    Label { x: 24; y: 18; color: win.fg; text: "Fake Clicker raster diagnostics / top: GPU curve / bottom: CPU SVG / sizes 16, 20, 24"; font.pixelSize: 18 }
    Grid {
        x: 24; y: 64; columns: 10; spacing: 8
        Repeater {
            model: Object.keys(Icons.set)
            Column {
                id: cell
                required property string modelData
                width: 115; height: 88; spacing: 4
                Label { text: cell.modelData; color: win.fg; font.pixelSize: 11 }
                Row {
                    spacing: 10
                    Repeater {
                        model: [16,20,24]
                        Item {
                            required property int modelData
                            width: 26; height: 26
                            Shape {
                                anchors.centerIn: parent; width: 24; height: 24
                                scale: parent.modelData / 24
                                preferredRendererType: Shape.CurveRenderer
                                visible: cell.modelData !== "stop"
                                ShapePath { strokeColor: win.fg; strokeWidth: 1.8; fillColor: "transparent"; capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin; PathSvg { path: Icons.get(cell.modelData).d || "" } }
                                ShapePath { strokeColor: "transparent"; fillColor: win.fg; PathSvg { path: Icons.get(cell.modelData).f || "" } }
                            }
                            Rectangle { anchors.centerIn: parent; visible: cell.modelData === "stop"; width: parent.modelData*11/24; height: width; radius: parent.modelData*1.8/24; color: win.fg; antialiasing: true }
                        }
                    }
                }
                Row {
                    spacing: 10
                    Repeater {
                        model: [16,20,24]
                        Item { required property int modelData; width: 26; height: 26; Icon { anchors.centerIn: parent; name: cell.modelData; size: parent.modelData; color: win.fg } }
                    }
                }
            }
        }
    }
    Label { x: 24; y: 568; text: "Geist / curve vs native grayscale / 14, 20, 28 px"; color: win.fg; font.pixelSize: 18 }
    Column {
        x: 24; y: 606; spacing: 16
        Repeater {
            model: [{label:"Curve",rt:2},{label:"Native",rt:1}]
            Row {
                id: sample
                required property var modelData
                spacing: 16
                Label { width: 150; text: sample.modelData.label; color: win.fg; font.pixelSize: 14 }
                Rectangle {
                    width: 1050; height: 136; radius: 10; color: "#08080a"
                    Column {
                        x: 16; y: 12; spacing: 8
                        Repeater {
                            model: [14,20,28]
                            Text { required property int modelData; text: "12,34 CPS · Легит · Остановлено: окно потеряло фокус"; color: "#f5f5f7"; font.family: Theme.sans; font.pixelSize: modelData; font.hintingPreference: sample.modelData.rt === 1 ? Font.PreferFullHinting : Font.PreferDefaultHinting; renderType: sample.modelData.rt }
                        }
                    }
                }
            }
        }
    }
}
