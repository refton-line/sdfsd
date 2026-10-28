import QtQuick
import QtQuick.Templates as T
import CClicker

// Floating Liquid Glass tab bar. The selection is a clear lens that magnifies what is behind
// it, stretches with its speed and swells while it travels.
Item {
    id: bar
    property int currentIndex: 0
    property var items: []          // [{ text, icon }]
    property real reveal: 1
    signal activated(int index)
    readonly property real itemWidth: 92
    readonly property real pad: 6
    width: items.length * itemWidth + pad * 2
    height: 66

    property real lensX: pad + currentIndex * itemWidth
    Behavior on lensX { SpringAnimation { spring: 3.6; damping: 0.3; epsilon: 0.05 } }
    // Lens speed drives stretch and swelling; it relaxes when the lens settles.
    property real lastX: lensX
    property real speed: 0
    FrameAnimation {
        running: Theme.animating && bar.visible
        onTriggered: {
            const dt = Math.max(frameTime, 0.001);
            bar.speed = bar.speed * 0.55 + 0.45 * Math.abs(bar.lensX - bar.lastX) / dt;
            bar.lastX = bar.lensX;
        }
    }
    readonly property real motion: Math.min(1, speed / 1400)
    property bool hovering: hover.hovered
    scale: hovering ? 1.015 : 1
    Behavior on scale { SpringAnimation { spring: 4; damping: 0.35; epsilon: 0.0005 } }
    HoverHandler { id: hover }

    Surface {
        anchors.fill: parent
        radius: height / 2
        floating: true
        elevation: 1.6
        tintAlpha: 0.34
    }
    GlassSurface {
        id: lens
        floating: true
        x: bar.lensX - bar.motion * 10
        y: bar.pad - bar.motion * 5
        width: bar.itemWidth + bar.motion * 20
        height: bar.height - bar.pad * 2 + bar.motion * 10
        radius: height / 2
        frost: 0.2
        magnify: 0.07 + 0.08 * bar.motion
        refraction: 12 + 8 * bar.motion
        tintColor: Qt.rgba(1, 1, 1, 0.16 + 0.1 * (1 - bar.motion))
        rim: 1
        opacity: bar.reveal
    }
    Row {
        x: bar.pad
        height: parent.height
        Repeater {
            id: tabs
            model: bar.items
            T.AbstractButton {
                id: tab
                required property int index
                required property var modelData
                objectName: "nav" + index
                width: bar.itemWidth
                height: bar.height
                hoverEnabled: true
                focusPolicy: Qt.StrongFocus
                Accessible.role: Accessible.PageTab
                Accessible.name: modelData.text
                readonly property bool selected: bar.currentIndex === index
                onClicked: bar.activated(index)
                Keys.onLeftPressed: if (index > 0) { bar.activated(index - 1); tabs.itemAt(index - 1).forceActiveFocus(); }
                Keys.onRightPressed: if (index < bar.items.length - 1) { bar.activated(index + 1); tabs.itemAt(index + 1).forceActiveFocus(); }
                readonly property real local: Math.max(0, Math.min(1, bar.reveal * (bar.items.length + 2) - index))
                opacity: local
                transform: Translate { y: 12 * (1 - tab.local) }
                background: Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: height / 2
                    color: !tab.selected && tab.hovered ? Qt.rgba(1, 1, 1, 0.35) : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                    border.width: tab.visualFocus ? 2 : 0
                    border.color: Theme.focusRing
                }
                contentItem: Item {
                    scale: tab.pressed ? 0.9 : tab.selected ? 1.04 : 1
                    Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
                    Column {
                        anchors.centerIn: parent
                        spacing: 3
                        Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: tab.modelData.icon
                            size: 22
                            stroke: tab.selected ? 2 : 1.7
                            color: tab.selected ? Theme.ink : Theme.inkSoft
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tab.modelData.text
                            font.pixelSize: 11
                            font.weight: tab.selected ? Font.DemiBold : Font.Medium
                            color: tab.selected ? Theme.ink : Theme.inkSoft
                        }
                    }
                }
            }
        }
    }
}
