import QtQuick
import QtQuick.Templates as T
import FakeClicker

// [− value unit +] field. Values can be typed; holding a button repeats.
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
    implicitWidth: 160
    implicitHeight: 36
    opacity: enabled ? 1 : 0.4

    function commit(v) {
        const bounded = Math.max(from, Math.min(to, v));
        if (!isNaN(bounded) && bounded !== value)
            valueModified(bounded);
        input.text = Qt.binding(() => stepper.display());
    }
    function display() {
        return value === 0 && zeroText !== "" ? zeroText : I18n.number(value, decimals);
    }
    readonly property bool showsUnit: unit !== "" && !(value === 0 && zeroText !== "") && !input.activeFocus

    Rectangle {
        anchors.fill: parent
        radius: Theme.controlRadius
        color: Theme.raised
        border.width: 1
        border.color: input.activeFocus ? Qt.rgba(1, 1, 1, 0.32) : Theme.hairline
    }
    StepButton {
        x: 3; anchors.verticalCenter: parent.verticalCenter
        glyph: "minus"
        enabled: stepper.value > stepper.from
        onClicked: stepper.commit(stepper.value - stepper.step)
    }
    Item {
        x: 34; width: parent.width - 68; height: parent.height
        Row {
            anchors.centerIn: parent
            spacing: 4
            TextInput {
                id: input
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(Math.max(contentWidth, 12), stepper.width - 76 - (stepper.showsUnit ? unitLabel.implicitWidth + 4 : 0))
                horizontalAlignment: Text.AlignHCenter
                clip: true
                text: stepper.display()
                color: Theme.ink
                font.family: Theme.sans
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
                renderType: Text.NativeRendering
                selectByMouse: true
                selectionColor: Theme.selection
                selectedTextColor: Theme.ink
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
            }
            Label {
                id: unitLabel
                visible: stepper.showsUnit
                anchors.baseline: input.baseline
                text: stepper.unit
                color: Theme.muted
                font.family: Theme.mono
                font.pixelSize: Theme.small
            }
        }
    }
    StepButton {
        anchors.right: parent.right; anchors.rightMargin: 3
        anchors.verticalCenter: parent.verticalCenter
        glyph: "plus"
        enabled: stepper.value < stepper.to
        onClicked: stepper.commit(stepper.value + stepper.step)
    }

    component StepButton: T.AbstractButton {
        id: button
        property string glyph
        width: 30; height: 30
        hoverEnabled: true
        autoRepeat: true
        focusPolicy: Qt.NoFocus
        Accessible.name: glyph === "plus" ? "+" : "−"
        opacity: enabled ? 1 : 0.3
        background: Rectangle {
            radius: Theme.controlRadius - 3
            color: button.pressed ? Theme.controlActive : button.hovered ? Theme.control : "transparent"
        }
        contentItem: Item {
            Icon { anchors.centerIn: parent; name: button.glyph; size: 14; stroke: 2; color: Theme.inkSoft }
        }
    }
}
