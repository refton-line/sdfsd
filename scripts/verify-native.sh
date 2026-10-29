#!/usr/bin/env bash
set -euo pipefail
: "${QT_HOST_PATH:?set native Qt 6.8.3 kit path}"
root="$(cd "$(dirname "$0")/.." && pwd)"
build="${BUILD_DIR:-$root/build-native}"
export LANG=C.UTF-8
export LD_LIBRARY_PATH="$QT_HOST_PATH/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
cmake -S "$root" -B "$build" -DCMAKE_PREFIX_PATH="$QT_HOST_PATH" -DCMAKE_BUILD_TYPE=Release
cmake --build "$build" --parallel 4
QT_QPA_PLATFORM=offscreen ctest --test-dir "$build" --output-on-failure
profile="$(mktemp -d)"
trap 'rm -rf "$profile"' EXIT
# The capture tour renders through OpenGL; Xvfb + Mesa is enough.
# CAPTURE_PACE=2 gives software GL time to render each step.
XDG_CONFIG_HOME="$profile" CAPTURE_PACE="${CAPTURE_PACE:-2}" QT_QPA_PLATFORM=xcb \
  xvfb-run -a -s "-screen 0 1600x1000x24" "$build/bin/FakeClicker" --capture "$build/qa-previews"
echo "Screens: $build/qa-previews"
