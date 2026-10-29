#!/usr/bin/env bash
# Renders assets/app.ico and assets/app-icon.png from the skull mark in assets/logo: the white
# skull over grey crossbones on a black rounded tile. 16 and 24 px drop the bones so the skull
# stays readable. Needs python3, rsvg-convert (librsvg) and ImageMagick.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT
python3 - "$root/assets/logo" "$out" <<'PY'
import re, sys
logo, out = sys.argv[1], sys.argv[2]
def body(name):
    return re.search(r'<svg[^>]*>(.*)</svg>', open(f'{logo}/{name}.svg').read(), re.S).group(1)
tile = '<rect x="4" y="4" width="248" height="248" rx="58" fill="#0A0A0A" stroke="#2A2A2A" stroke-width="6"/>'
full = body('bones') + body('jaw') + body('cranium')
head = body('jaw') + body('cranium')
svg = '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">{}</svg>'
open(f'{out}/full.svg', 'w').write(svg.format(tile + f'<g transform="translate(30 30) scale(1.53)">{full}</g>'))
# Small sizes: skull only, larger and centred on the same tile.
open(f'{out}/small.svg', 'w').write(svg.format(tile + f'<g transform="translate(14.1 34.7) scale(1.78)">{head}</g>'))
PY
for s in 32 48 64 128 256 1024; do rsvg-convert -w $s -h $s "$out/full.svg" -o "$out/icon-$s.png"; done
for s in 16 24; do rsvg-convert -w $s -h $s "$out/small.svg" -o "$out/icon-$s.png"; done
convert "$out"/icon-{16,24,32,48,64,128,256}.png "$root/assets/app.ico"
convert "$out/icon-1024.png" -resize 512x512 "$root/assets/app-icon.png"
mkdir -p "${ICON_PREVIEW_DIR:-$out/preview}" && cp "$out"/icon-*.png "${ICON_PREVIEW_DIR:-$out/preview}/"
echo "Icon: $root/assets/app.ico, $root/assets/app-icon.png"
