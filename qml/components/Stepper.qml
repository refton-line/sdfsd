import QtQuick
import CClicker

// Glass: [− value +] capsule. Solid: value, then the iOS stepper pill.
// Values can be typed; holding a button repeats.
Item {
    id: stepper
    property real value: 0
    property real from: 0
    property real to: 100
    property real step: 1
    property string unit: ""
    property string zeroText: ""
    property int decimals: 0
    signal valueModified(real value)
    implicitWidth: 168
    implicitHeight: Theme.isGlass ? 38 : 32
    opacity: enabled ? 1 : 0.45

    function commit(v) {
        const bounded = Math.max(from, Math.min(to, v));
        if (!isNaN(bounded) && bounded !== value)
            valueModified(bounded);
        input.text = Qt.binding(() => stepper.display());
    }
    function display() {
        return value === 0 && zeroText !== "" ? zeroText : I18n.number(value, decimals);
    }
    readonly property real buttonsWidth: Theme.isGlass ? 0 : 94

    Rectangle {
        visible: Theme.isGlass
        anchors.fill: parent
        radius: height / 2
        color: Theme.well
    }
    TextInput {
        id: input
        x: Theme.isGlass ? 36 : 0
        width: Theme.isGlass ? parent.width - 72 : parent.width - stepper.buttonsWidth - 14 - (unitLabel.visible ? unitLabel.implicitWidth : 0)
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Theme.isGlass ? Text.AlignHCenter : Text.AlignRight
        text: stepper.display()
        color: Theme.ink
        font.family: Theme.sans
        font.pixelSize: Theme.isGlass ? 14 : 15
        font.weight: Theme.isGlass ? Font.DemiBold : Font.Normal
        font.features: { "tnum": 1 }
        selectByMouse: true
        selectionColor: Theme.focusRing
        validator: RegularExpressionValidator { regularExpression: /^[0-9]{0,13}([.,][0-9]{0,2})?$/ }
        onActiveFocusChanged: {
            if (activeFocus) {
                text = stepper.value === 0 && stepper.zeroText !== "" ? "0" : String(stepper.value);
                selectAll();
            } else {
                stepper.commit(parseFloat(text.replace(",", ".")));
            }
        }
        onAccepted: focus = false
        Label {
            visible: Theme.isGlass && text !== ""
            anchors.left: parent.horizontalCenter
            anchors.leftMargin: parent.contentWidth / 2 + 4
            anchors.baseline: parent.baseline
            text: stepper.value === 0 && stepper.zeroText !== "" ? "" : stepper.unit
            color: Theme.muted
            font.pixelSize: Theme.small
        }
    }
    Label {
        id: unitLabel
        visible: !Theme.isGlass && stepper.unit !== "" && !(stepper.value === 0 && stepper.zeroText !== "")
        anchors.left: input.right
        anchors.leftMargin: 4
        anchors.baseline: input.baseline
        text: stepper.unit
        color: Theme.muted
        font.pixelSize: 13
    }
    // Glass buttons
    AppButton {
        visible: Theme.isGlass
        compact: true
        width: 30; height: 30
        x: 4; anchors.verticalCenter: parent.verticalCenter
        iconName: "minus"; iconSize: 14
        Accessible.name: "−"
        enabled: stepper.value > stepper.from
        autoRepeat: true
        onClicked: stepper.commit(stepper.value - stepper.step)
    }
    AppButton {
        visible: Theme.isGlass
        compact: true
        width: 30; height: 30
        anchors.right: parent.right; anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        iconName: "plus"; iconSize: 14
        Accessible.name: "+"
        enabled: stepper.value < stepper.to
        autoRepeat: true
        onClicked: stepper.commit(stepper.value + stepper.step)
    }
    // Solid stepper pill
    Rectangle {
        visible: !Theme.isGlass
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: stepper.buttonsWidth; height: 32; radius: 8
        color: Theme.fill
        Rectangle { anchors.centerIn: parent; width: 1; height: 18; color: Qt.rgba(0.235, 0.235, 0.263, 0.29) }
        Repeater {
            model: 2
            MouseArea {
                id: half
                required property int index
                x: index * parent.width / 2
                width: parent.width / 2; height: parent.height
                readonly property bool allowed: index === 0 ? stepper.value > stepper.from : stepper.value < stepper.to
                enabled: allowed
                Accessible.role: Accessible.Button
                Accessible.name: index === 0 ? "−" : "+"
                onPressed: { stepper.commit(stepper.value + (index === 0 ? -stepper.step : stepper.step)); repeat.start(); }
                onReleased: repeat.stop()
                onCanceled: repeat.stop()
                Timer { id: repeat; interval: 380; repeat: true; triggeredOnStart: false; onTriggered: { interval = 90; stepper.commit(stepper.value + (half.index === 0 ? -stepper.step : stepper.step)); } onRunningChanged: if (!running) interval = 380 }
                Rectangle { anchors.fill: parent; radius: 8; color: Qt.rgba(0, 0, 0, half.pressed ? 0.08 : 0) }
                Icon { anchors.centerIn: parent; name: half.index === 0 ? "minus" : "plus"; size: 16; stroke: 2; color: half.allowed ? Theme.ink : Theme.faint }
            }
        }
    }
}
