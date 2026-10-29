#!/usr/bin/env python3
"""Motion and hover contracts for the Fake Clicker interface.
Hover feedback is instant; motion is short and eased with no springs, bounces or overshoot;
there is no glass, blur or material switching left anywhere. Run: python tests/ui_hover_regression.py
"""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
qml = root / 'qml'
files = sorted(qml.rglob('*.qml'))
checked = 0
for path in files:
    text = path.read_text(encoding='utf-8')
    name = path.relative_to(root)
    # No springy or bouncy motion anywhere.
    for banned in ['SpringAnimation', 'Easing.OutBack', 'Easing.InOutBack', 'Easing.OutElastic', 'Easing.OutBounce', 'easing.overshoot']:
        assert banned not in text, (str(name), banned)
    # No glass, frosting or material switching.
    for banned in ['GlassSurface', 'MultiEffect', 'isGlass', 'setMaterial', 'blurEnabled']:
        assert banned not in text, (str(name), banned)
    # Durations stay short: the only long animations are the countdown sweep and loops.
    for m in re.finditer(r'duration:\s*(\d+)', text):
        assert int(m.group(1)) <= 900, (str(name), m.group(0))
    # Background colours that depend on hover apply their final colour directly.
    for match in re.finditer(r'\bcolor:\s*[^\n]*', text):
        start = match.start()
        end = text.find('\n', start)
        while end >= 0 and re.match(r'\s*[:?]', text[end+1:]):
            end = text.find('\n', end+1)
        binding = text[start:end]
        if '.hovered' not in binding:
            continue
        checked += 1
        next_line = text[end+1:].split('\n', 1)[0]
        assert 'Behavior on color' not in next_line, (str(name), binding)
assert checked >= 15, checked
print(f'PASS: {len(files)} QML files; {checked} hover colour bindings are instantaneous; no springs, overshoot or glass.')

components = qml / 'components'
island = (components / 'DynamicIsland.qml').read_text(encoding='utf-8')
assert 'renderType: Text.NativeRendering' in island
assert 'font.hintingPreference: Font.PreferFullHinting' in island
assert 'layer.enabled:' not in island
assert 'transform: Scale' not in island
assert 'Behavior on shownRate' not in island
assert 'fontSizeMode: Text.HorizontalFit' in island
assert 'function inform(' in island and 'noticeTone' in island
icon = (components / 'Icon.qml').read_text(encoding='utf-8')
assert 'Shape {' not in icon and 'crispicons/' in icon and 'sourceSize: Qt.size' in icon
print('PASS: native grayscale island text; no island FBO, scale transform or frame-by-frame CPS interpolation.')
