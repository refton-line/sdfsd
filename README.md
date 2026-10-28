# C clicker 0.5.0

Native C++20 / Qt Quick 6.8.3 auto clicker for Windows 10/11 x64. Grey-white Liquid Glass interface,
an iPhone-style Dynamic Island, two click engines and an uncapped custom rate. English by default,
Russian included.

## Click modes
| Mode | What it does |
|---|---|
| **Legit** | Human emulation. Each gap gets log-normal jitter around the target rate, a slow tempo drift, rare hesitations and quick doubles, a short warm-up, and a finger-like press duration that shrinks as the rate rises. A mean correction keeps the long-run average within ~2% of the target. *Variance*: Tight / Natural / Loose. |
| **Blatant** | Direct clicking, no emulation. Exact fixed grid with no drift. When the rate outruns the Windows timer, due clicks are sent together in one `SendInput` batch (up to 128 pairs per wake), so very high rates are reachable. Optional hold in ms (0 = press and release together). |

**Custom CPS.** Type any positive value (decimals allowed) into the large number or use the − / + buttons
and presets. There is no upper limit in the UI; the only technical bound is one click per nanosecond.
What a target app actually receives depends on Windows and that app. Legit is timer-paced and
practically tops out around ~1000 CPS. Uncapped throughput is a Blatant feature.

## Interface
- **Dynamic Island.** It boots at the centre of the window, then rises into the title bar. Its views are idle (mode + target), countdown ring, live (mode, activity bars, measured CPS), expanded on hover or click (CPS, clicks, time, stop), mode/profile/material notices, errors and a run summary. All views morph with springs and fade through blur.
- **Island over other windows.** While you click in another app, a copy sits at the top of the screen. It never takes focus or mouse input, so the target window keeps foreground. You can turn it off in Appearance.
- **Material.** *Liquid Glass*: translucent, with specular rims and drifting light (iOS 26/27 style). *Solid*: opaque iOS 14-style cards. Switching between them morphs instead of snapping.
- **Language.** English (default) or Русский. The content cross-fades when you switch.
- Pages: Clicker, Hotkeys, Profiles, Appearance, Language. Each one has its own icon.

## Hotkeys and profiles
The physical-key binding engine from 0.4.x is unchanged: Raw Input, 1–3 keys per shortcut, up to 8
alternatives each for start and stop, side-specific Ctrl/Alt/Shift, AltGr and PrintScreen. Defaults
are F6 to start and F8 to stop. Profiles are JSON (v4). v1–v3 profiles still load: an old fixed
interval becomes Blatant at the same rate.

## Safety behaviour
Clicking runs only while the window that was in front at the end of the countdown keeps focus and
the cursor stays inside it. A press is always followed by its release. Closing the app stops input
before the closing animation plays. The EXE is unsigned; do not disable Windows protection to run it.

## Build
Requires CMake ≥ 3.24, C++20 and Qt 6.8.3 (Quick, QuickControls2, Concurrent).
```sh
# Native (Linux/Windows) build and tests
cmake -S . -B build -DCMAKE_PREFIX_PATH=/path/to/Qt/6.8.3/gcc_64 -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel
QT_QPA_PLATFORM=offscreen ctest --test-dir build --output-on-failure
# Windows EXE from Linux (MinGW-w64 13 posix + Qt 6.8.3 mingw_64 kit)
QT_HOST_PATH=/opt/Qt/6.8.3/gcc_64 QT_WIN_PATH=/opt/Qt/6.8.3/mingw_64 scripts/build-cross.sh
python3 scripts/package-windows.py --qt "$QT_WIN_PATH" --exe build-cross/bin/CClicker.exe \
  --receiver build-cross/CClickerReceiver.exe --runtime <dir with MinGW runtime DLLs> --output dist/C-clicker
# Screenshot tour (needs X11/Xvfb and OpenGL): writes PNGs for every screen and state
xvfb-run -a build/bin/CClicker --capture shots
```
`CClickerReceiver.exe` is a test window that counts the clicks it receives, so you can check the real
delivered rate on Windows.

## Limitations
Built and packaged by cross-compiling. The Windows build was smoke-tested only (see QA.md); physical
Windows input (SendInput delivery, Raw Input on real keyboards, DPI) needs testing on real Windows.
Fn and OS-intercepted keys are not guaranteed; Win and F12 cannot be bound. Raw Input does not
reserve hotkeys exclusively.
