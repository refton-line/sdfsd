import QtQuick
import FakeClicker

// Interface text. Native grayscale rasterisation keeps small Geist sizes crisp on dark surfaces;
// nothing in the interface scales text, so distance-field rendering is not needed.
Text {
    color: Theme.ink
    font.family: Theme.sans
    font.pixelSize: Theme.body
    textFormat: Text.PlainText
    renderType: Text.NativeRendering
    font.hintingPreference: Font.PreferFullHinting
}
