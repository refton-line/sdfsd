#!/usr/bin/env python3
"""Source contracts: icon tables stay in sync and text/icon rendering stays on the CPU paths."""
from pathlib import Path
import json, re
p = Path(__file__).resolve().parents[1]
js = (p/'qml/components/Icons.js').read_text(encoding='utf-8')
expected = {m[1]: {k: v for k, v in re.findall(r'(d|f): "([^"]*)"', m[2])} for m in re.finditer(r'^    (\w+): \{([^\n]+)\}', js, re.M)}
assert expected == json.loads((p/'assets/icons.json').read_text(encoding='utf-8')), 'Icons.js and icons.json differ'
assert len(expected) == 42 and {'overlay', 'overlayOff', 'gauge', 'hold', 'hash', 'sliders', 'volume', 'volumeOff'} <= set(expected)
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
# Interface sounds: the cue table, the cues QML and the clicker ask for, and the WAV files agree;
# every file is short, mono 48 kHz 16-bit, starts and ends near silence and keeps its level.
import wave, array, math
engine = (p/'src/SoundEngine.cpp').read_text(encoding='utf-8')
table = set(re.findall(r'"(\w+)"', re.search(r'static const QStringList list = \{([^}]*)\}', engine).group(1)))
session = re.search(r'QStringList SoundEngine::sessionCues.*?\n\}', engine, re.S).group(0)
used = set(re.findall(r'QStringList\{"(\w+)"\}|return \{"(\w+)"\}', session))
used = {name for pair in used for name in pair if name}
for path in (p/'qml').rglob('*.qml'):
    text = path.read_text(encoding='utf-8')
    for call in re.findall(r'sounds\.(?:play|preview)\(([^)]*)\)', text):
        used |= set(re.findall(r'"(\w+)"', call)) - {'deleted'}
    for line in re.findall(r'\bcue:\s*([^\n]*)', text):
        used |= set(re.findall(r'"(\w+)"', line))
assert used == table, ('cue table and uses differ', sorted(used ^ table))
assert {p.stem for p in (p/'assets/sounds').glob('*.wav')} == table, 'one WAV per cue'
for name in sorted(table):
    with wave.open(str(p/f'assets/sounds/{name}.wav')) as w:
        assert (w.getnchannels(), w.getsampwidth(), w.getframerate()) == (1, 2, 48000), name
        samples = array.array('h', w.readframes(w.getnframes()))
    assert 0.015 <= len(samples) / 48000 <= 1.2, (name, len(samples))
    peak = 20 * math.log10(max(abs(v) for v in samples) / 32767)
    assert -24 <= peak <= -5, (name, peak)
    assert abs(samples[0]) < 330 and abs(samples[-1]) < 330, (name, 'clicks at an edge')
print('SOURCE_CONTRACTS_PASS: 42 synced glyphs, CPU icon raster, native island text, layered skull mark, ' + str(len(table)) + ' sound cues')
