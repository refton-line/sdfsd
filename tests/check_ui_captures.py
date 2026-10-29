#!/usr/bin/env python3
"""Check alpha margins and independent overlay frames from --capture-ui-regression.
Requires Pillow. Usage: python tests/check_ui_captures.py CAPTURE_DIR [...]
"""
from pathlib import Path
import sys
from PIL import Image, ImageChops
for arg in sys.argv[1:]:
    root = Path(arg)
    images = list(root.glob('*.png'))
    assert len(images) == 19, (root, len(images))
    for name in ['05-overlay-live', '08-overlay-error', '10-overlay-main-minimized', '11-overlay-independent-frame']:
        image = Image.open(root / (name + '.png')).convert('RGBA')
        alpha = image.getchannel('A')
        assert alpha.getextrema() == (0, 255), name
        bbox = alpha.getbbox()
        assert bbox and bbox[0] > 0 and bbox[1] > 0 and bbox[2] < image.width and bbox[3] < image.height, (name,bbox)
        assert alpha.getpixel((0, 0)) == 0 and alpha.getpixel((image.width-1, image.height-1)) == 0, name
        assert sum(alpha.histogram()[1:255]) > 0, ('missing antialiased edge',name)
    live = Image.open(root/'05-overlay-live.png').convert('RGBA')
    scale = live.width / 520
    rate = live.crop(tuple(round(x * scale) for x in (315, 25, 335, 47)))
    for red, green, blue, alpha in list(rate.get_flattened_data() if hasattr(rate, "get_flattened_data") else rate.getdata()):
        if alpha > 200 and max(red, green, blue) > 100:
            assert max(red, green, blue)-min(red, green, blue) <= 8, 'RGB fringe on island rate'
    first = Image.open(root/'10-overlay-main-minimized.png').convert('RGBA')
    second = Image.open(root/'11-overlay-independent-frame.png').convert('RGBA')
    assert ImageChops.difference(first, second).convert('RGB').getbbox(), 'overlay animation froze'
    print(f'CAPTURE_PASS {root.name}: 19 images, transparent margins, antialiased edges, independent animation.')
