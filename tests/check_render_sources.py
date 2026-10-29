#!/usr/bin/env python3
"""Source contracts: icon tables stay in sync and text/icon rendering stays on the CPU paths."""
from pathlib import Path
import json, re
p = Path(__file__).resolve().parents[1]
js = (p/'qml/components/Icons.js').read_text(encoding='utf-8')
expected = {m[1]: {k: v for k, v in re.findall(r'(d|f): "([^"]*)"', m[2])} for m in re.finditer(r'^    (\w+): \{([^\n]+)\}', js, re.M)}
assert expected == json.loads((p/'assets/icons.json').read_text(encoding='utf-8')), 'Icons.js and icons.json differ'
assert len(expected) == 40 and {'overlay', 'overlayOff', 'gauge', 'hold', 'hash', 'sliders'} <= set(expected)
assert not {'liquidLens', 'drop', 'square'} & set(expected), 'glass-era glyphs are gone'
icon = (p/'qml/components/Icon.qml').read_text(encoding='utf-8')
assert 'Shape {' not in icon and 'crispicons/' in icon and 'sourceSize: Qt.size' in icon
island = (p/'qml/components/DynamicIsland.qml').read_text(encoding='utf-8')
assert 'Text.NativeRendering' in island and 'Text.CurveRendering' not in island
assert 'NoSubpixelAntialias' in (p/'src/main.cpp').read_text(encoding='utf-8')
# The skull mark is three layers on one artboard: bones, jaw (animated), cranium.
for part in ['bones', 'jaw', 'cranium']:
    svg = (p/f'assets/logo/{part}.svg').read_text(encoding='utf-8')
    assert 'viewBox="0 0 128 128"' in svg, part
print('SOURCE_CONTRACTS_PASS: 40 synced glyphs, CPU icon raster, native island text, layered skull mark')
