import QtQuick
import FakeClicker

// A keyboard key: graphite cap with a firmer lower edge and a mono legend.
Rectangle {
    id: cap
    property string text
    property real size: 24
    property color textColor: Theme.ink
    implicitHeight: size
    implicitWidth: Math.max(size, legend.implicitWidth + 14)
    radius: Theme.smallRadius
    color: Theme.control
    border.width: 1
    border.color: Theme.hairlineStrong
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 2 * parent.radius; height: 1
        color: "#3A3A3A"
    }
    Label {
        id: legend
        anchors.centerIn: parent
        width: Math.min(implicitWidth, cap.width - 10)
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        text: cap.text
        color: cap.textColor
        font.family: Theme.mono
        font.pixelSize: Math.max(10, Math.round(cap.size * 0.46))
        font.weight: Font.DemiBold
    }
}
