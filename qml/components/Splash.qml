import QtQuick
import FakeClicker

// Loading screen: the skull bites twice while the bar fills with startup progress.
Item {
    id: splash
    objectName: "splash"
    property real progress: 0          // 0..1
    signal chompFinished()
    function chomp() { skull.chomp(); }

    // Already smooth: Main paces it with an eased ramp. A Behavior here would restart on every
    // tick of that ramp and never move.
    readonly property real shown: Math.max(0, Math.min(1, progress))

    Rectangle { anchors.fill: parent; color: Theme.canvas }
    // Swallow input while loading so nothing underneath reacts.
    MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.AllButtons }

    Column {
        id: stack
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -10
        SkullMark {
            id: skull
            objectName: "splashSkull"
            size: 112
            anchors.horizontalCenter: parent.horizontalCenter
            onChompFinished: splash.chompFinished()
        }
        Item { width: 1; height: 26 }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "FAKE CLICKER"
            font.pixelSize: 19
            font.weight: Font.Black
            font.letterSpacing: 4.5
        }
        Item { width: 1; height: 26 }
        Item {
            id: bar
            objectName: "loadingBar"
            width: 184; height: 2
            anchors.horizontalCenter: parent.horizontalCenter
            Rectangle { anchors.fill: parent; radius: 1; color: Qt.rgba(1, 1, 1, 0.12) }
            Rectangle {
                width: Math.round(parent.width * Math.max(0, Math.min(1, splash.shown)))
                height: parent.height
                radius: 1
                color: Theme.ink
            }
        }
        Item { width: 1; height: 12 }
        Item {
            width: bar.width; height: loadingText.implicitHeight
            anchors.horizontalCenter: parent.horizontalCenter
            Caption { id: loadingText; text: I18n.t("boot.loading") }
            Caption {
                anchors.right: parent.right
                text: Math.round(Math.max(0, Math.min(1, splash.shown)) * 100) + "%"
                color: Theme.inkSoft
                font.features: { "tnum": 1 }
            }
        }
    }
}
