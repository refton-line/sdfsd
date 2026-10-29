#!/usr/bin/env bash
set -euo pipefail
: "${QT_HOST_PATH:?set native Qt 6.8.3 kit path}"
root="$(cd "$(dirname "$0")/.." && pwd)"
build="${BUILD_DIR:-$root/build-native}"
output="${UI_CAPTURE_DIR:-$build/ui-regression}"
export LANG=C.UTF-8
export LD_LIBRARY_PATH="$QT_HOST_PATH/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
cmake -S "$root" -B "$build" -DCMAKE_PREFIX_PATH="$QT_HOST_PATH" -DCMAKE_BUILD_TYPE=Release
cmake --build "$build" --parallel 2
QT_QPA_PLATFORM=offscreen ctest --test-dir "$build" --output-on-failure
python3 "$root/tests/ui_hover_regression.py"
profile="$(mktemp -d)"
trap 'rm -rf "$profile"' EXIT
# Uses synthetic engine states only: never injects mouse clicks.
xvfb-run -a -s '-screen 0 2400x1600x24' env \
  XDG_CONFIG_HOME="$profile" QT_QPA_PLATFORM=xcb QSG_RHI_BACKEND=opengl \
  "$build/bin/FakeClicker" --capture-ui-regression "$output"
python3 "$root/tests/check_ui_captures.py" "$output"
echo "Screenshots: $output"
