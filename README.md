# Light clicker 0.7.0

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
Two materials, and switching between them changes the whole app. The new look washes over the old one in a circle that grows from the pointer and has a bright liquid front. Labels are kept to names and values; there are no hint or subtitle lines.

**Logo and launch.** The mark is a five-point star split down the middle: the left half is Liquid Glass that refracts what is behind it, the right half is plain ink. The app icon uses the same split, with a frosted-glass | white tile. Launch starts softly: the plain window warms up into the wallpaper while the star fades in and its ink half fills from the bottom up; then it flies into the title bar (glass) or the sidebar (solid) and stays there as the logo. Closing plays the same story backwards (the star returns to the centre, drains and fades). Minimize, maximize, restore and Snap are the standard Windows animations.

| | **Liquid Glass** (iOS 26/27) | **Solid** (iOS 14) |
|---|---|---|
| Surfaces | Everything is glass. Panels, buttons, chips, tracks, badges, key caps, switches, the Start button and the island all refract and frost what is behind them, with a specular rim and slight dispersion. Coloured parts are tinted glass; tracks are recessed glass | Opaque white inset-grouped sections on `#f2f2f7` |
| Navigation | Floating glass tab bar at the bottom. The selection is a clear lens that magnifies, stretches and swells as it moves | iPadOS 14 sidebar with the logo, blue line icons and a filled blue selection |
| Controls | Glass capsules; switch knobs turn into a clear lens while pressed | iOS 14 controls: segmented thumb, classic switch, stepper pill, blue tint |
| Motion | Springs with overshoot; pages lift and settle; sheets spring in over a blurred window | Eased curves without overshoot; pages slide like a push; sheets slide up over a dimmed window |

**Dynamic Island.** It grows out of a dot in the title bar as the launch star lands. On glass it is smoked Liquid Glass; on solid it is black. It morphs on springs with a velocity-driven squash and stretch, and its content is clipped to the moving shape. All motion is continuous: the waveform, the countdown ring and the pulse never step or pause.
- Compact views: mode and target CPS, countdown ring, live waveform with measured CPS, notices, errors, run summary.
- **Hover expands it at once** (a click pins it, Esc unpins it) into a control panel: Legit/Blatant switch, a large CPS readout with −/+, live clicks and time, and a big Start/Cancel/Stop button.
- **Island over other windows:** while you click in another app, a copy sits at the top of the screen. It never takes focus or mouse input. Windows does not let it sample the desktop behind it, so there it is drawn as lit smoked glass without refraction.

**Target window.** The button above Start opens a window picker with live thumbnails (like choosing a window to share on Discord). With a window chosen, Start brings it to the front, clicks only while it stays in front, and the island over other windows sits at the top of that window. "Any window" keeps the old behaviour: whatever is in front when the countdown ends.

**Island notices.** Every real change shows up in the island: CPS, button, variance, hold, limits, countdown, shortcuts, target window, overlay, mode, language and material. Hover expands it; it collapses as soon as the pointer leaves, also after a click.

**Language:** English (default) or Русский.

## Hotkeys and profiles
The physical-key binding engine from 0.4.x is unchanged: Raw Input, 1–3 keys per shortcut, up to 8
alternatives each for start and stop, side-specific Ctrl/Alt/Shift, AltGr and PrintScreen. Defaults
are F6 to start and F8 to stop. **Reset** next to the countdown puts the countdown back to its default (3 s); it does not touch shortcuts. Profiles are JSON (format `light-clicker`, v4). Profiles from earlier versions
(v1–v4) still load: an old fixed interval becomes Blatant at the same rate.

## Safety behaviour
Clicking runs only while the window that was in front at the end of the countdown keeps focus and
the cursor stays inside it. A press is always followed by its release. Closing the app stops input
before the closing animation plays. The EXE is unsigned; do not disable Windows protection to run it.

## Build
Requires CMake ≥ 3.24, C++20 and Qt 6.8.3 (Quick, QuickControls2, Concurrent, ShaderTools for build-time shader compilation).
```sh
# Native (Linux/Windows) build and tests
cmake -S . -B build -DCMAKE_PREFIX_PATH=/path/to/Qt/6.8.3/gcc_64 -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel
QT_QPA_PLATFORM=offscreen ctest --test-dir build --output-on-failure
# Windows EXE from Linux (MinGW-w64 13 posix + Qt 6.8.3 mingw_64 kit)
QT_HOST_PATH=/opt/Qt/6.8.3/gcc_64 QT_WIN_PATH=/opt/Qt/6.8.3/mingw_64 scripts/build-cross.sh
python3 scripts/package-windows.py --qt "$QT_WIN_PATH" --exe build-cross/bin/LightClicker.exe \
  --receiver build-cross/LightClickerReceiver.exe --runtime <dir with MinGW runtime DLLs> --output dist/C-clicker
# Screenshot tour (needs X11/Xvfb and OpenGL): writes PNGs for every screen and state
xvfb-run -a build/bin/LightClicker --capture shots
```
`LightClickerReceiver.exe` is a test window that counts the clicks it receives, so you can check the real
delivered rate on Windows.

## Limitations
Built and packaged by cross-compiling. The Windows build was smoke-tested only (see QA.md); physical
Windows input (SendInput delivery, Raw Input on real keyboards, DPI) needs testing on real Windows.
Fn and OS-intercepted keys are not guaranteed; Win and F12 cannot be bound. Raw Input does not
reserve hotkeys exclusively.
