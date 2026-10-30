#!/usr/bin/env bash
# Renders assets/app.ico and assets/app-icon.png from shaders/mark.frag, so the icon is the same
# split star as the in-app logo. Needs Qt 6.8 (qsb, qml), Xvfb and ImageMagick.
set -euo pipefail
: "${QT_HOST_PATH:?set native Qt 6.8.3 kit path}"
root="$(cd "$(dirname "$0")/.." && pwd)"
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT
"$QT_HOST_PATH/bin/qsb" --glsl "100 es,120,150" -o "$out/mark.frag.qsb" "$root/shaders/mark.frag"
LD_LIBRARY_PATH="$QT_HOST_PATH/lib" QT_QPA_PLATFORM=xcb xvfb-run -a -s "-screen 0 1600x1200x24" \
  "$QT_HOST_PATH/bin/qml" "$root/tools/icon/RenderIcon.qml" -- "$out/mark.frag.qsb" "$out"
convert "$out"/icon-{16,24,32,48,64,128,256}.png "$root/assets/app.ico"
convert "$out/icon-1024.png" -resize 512x512 "$root/assets/app-icon.png"
echo "Icon: $root/assets/app.ico, $root/assets/app-icon.png"
