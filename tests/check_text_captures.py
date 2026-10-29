#!/usr/bin/env python3
"""Validate --capture-text-regression evidence. Requires Pillow."""
import json, math, sys
from pathlib import Path
from PIL import Image, ImageChops
for directory in sys.argv[1:]:
    root = Path(directory)
    shots = json.loads((root/'text-bounds.json').read_text())
    assert len(shots) == 16, (root,len(shots))
    neutral_count = 0
    for shot in shots:
        image = Image.open(root/shot['file']).convert('RGBA')
        assert shot['labels'], shot['file']
        if shot['overlay']:
            alpha = image.getchannel('A')
            assert alpha.getpixel((0,0)) == 0
            assert alpha.getextrema() == (0,255)
        for label in shot['labels']:
            if not label['neutral']: continue
            x,y,w,h = (label[n] for n in ('x','y','width','height'))
            box=(max(0,math.floor(x)+1),max(0,math.floor(y)+1),min(image.width,math.ceil(x+w)-1),min(image.height,math.ceil(y+h)-1))
            if box[2] <= box[0] or box[3] <= box[1]: continue
            region = image.crop(box)
            pixels=region.get_flattened_data() if hasattr(region,'get_flattened_data') else region.getdata()
            chroma=[max(r,g,b)-min(r,g,b) for r,g,b,a in pixels if a>220 and max(r,g,b)>90]
            assert not chroma or max(chroma)<=12, (root.name,shot['file'],label['text'],max(chroma))
            neutral_count+=1
    first = next(s for s in shots if s['file']=='10-overlay-ru-a.png')
    second = next(s for s in shots if s['file']=='11-overlay-ru-b.png')
    for a in first['labels']:
        if a['text'] != '12,34': continue
        b = next(b for b in second['labels'] if b['text']==a['text'])
        def glyph(shot,label):
            x,y,w,h=(label[n] for n in ('x','y','width','height'))
            return Image.open(root/shot['file']).convert('RGB').crop((math.floor(x),math.floor(y),math.ceil(x+w),math.ceil(y+h)))
        ga,gb=glyph(first,a),glyph(second,b)
        assert ga.size==gb.size and ImageChops.difference(ga,gb).getbbox() is None, 'stationary CPS glyphs shimmer between frames'
        break
    else: raise AssertionError('missing stable CPS sample')
    print(f'TEXT_PIXELS_PASS {root.name}: 16 scenes; {neutral_count} neutral text regions; stable CPS pixels; transparent overlay.')
