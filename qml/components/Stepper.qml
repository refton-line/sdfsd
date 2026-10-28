import QtQuick
import QtQuick.Templates as T
import CClicker

// [−] value [+] with direct typing. Holding a button repeats with acceleration.
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
    implicitHeight: 40
    opacity: enabled ? 1 : 0.45

    function commit(v) {
        const bounded = Math.max(from, Math.min(to, v));
        if (!isNaN(bounded) && bounded !== value)
            valueModified(bounded);
        input.text = Qt.binding(() => stepper.display());
    }
    function display() {
        if (value === 0 && zeroText !== "")
            return zeroText;
        return I18n.number(value, decimals);
    }
    Rectangle { anchors.fill: parent; radius: height / 2; color: Theme.well }
    GlassButton {
        id: minus
        compact: true
        width: 32; height: 32
        x: 4; anchors.verticalCenter: parent.verticalCenter
        iconName: "minus"; iconSize: 15
        Accessible.name: "−"
        enabled: stepper.value > stepper.from
        autoRepeat: true
        onClicked: stepper.commit(stepper.value - stepper.step)
    }
    TextInput {
        id: input
        anchors.left: minus.right; anchors.right: plus.left
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        text: stepper.display()
        color: Theme.ink
        font.family: Theme.sans
        font.pixelSize: Theme.body + 1
        font.weight: Font.DemiBold
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
            anchors.left: parent.horizontalCenter
            anchors.leftMargin: parent.contentWidth / 2 + 4
            anchors.baseline: parent.baseline
            text: stepper.value === 0 && stepper.zeroText !== "" ? "" : stepper.unit
            color: Theme.muted
            font.pixelSize: Theme.small
        }
    }
    GlassButton {
        id: plus
        compact: true
        width: 32; height: 32
        anchors.right: parent.right; anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        iconName: "plus"; iconSize: 15
        Accessible.name: "+"
        enabled: stepper.value < stepper.to
        autoRepeat: true
        onClicked: stepper.commit(stepper.value + stepper.step)
    }
}
