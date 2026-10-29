# QA — 0.8.0

## Automated (Linux, Qt 6.8.3 gcc_64): `ctest` 4/4 PASS
- Controller: 698 assertions — click timing, configuration, hotkeys, profiles (incl. Light clicker v4 import).
- Raster icons: 9 801 checks / 1 600 renders; 40 glyphs at 12–32 px, DPR 100/125/150/200 %, no corner specks.
- Source contracts: icon tables in sync, CPU icon raster, native island text, layered skull mark.
- Motion contracts: 28 QML files; hover colour changes are instant; no springs, overshoot, glass or blur.

## Screenshots (`--capture`, Linux/Xvfb/Mesa OpenGL, synthetic engine states, no real clicks)
- `screenshots/`: 39 PNGs — launch, Legit/Blatant, island (expanded, notices, countdown, running, summary,
  error), hotkeys and key sheet, profiles and save sheet, settings, Russian pages, overlay island,
  window picker, closing fade.
- `screenshots/launch/`: 13 slow-motion launch frames (`FAKECLICKER_MOTION_SCALE=6`): two jaw bites,
  loading bar, fade into the interface. `screenshots/sheets/` holds contact sheets.

## Windows x64 build
- Cross-built with MinGW-w64 GCC 13 (posix) on Ubuntu 24.04 against Qt 6.8.3 mingw_64.
- Static PE import audit: 110 PE files, 53 DLLs copied, 0 unresolved non-system DLLs (`dependency-audit.json`).
- Wine 9.0 smoke run (Xvfb + Mesa): the packaged `FakeClicker.exe --capture` finished the same 39-screen
  tour with exit code 0. QML modules, plugins, Geist fonts, icons, Cyrillic text and the overlay window
  load from the package; settings and profiles persisted between runs. Against the Linux screenshots,
  Hotkeys and Settings differ by 0 px and the other compared screens by under 1 % (anti-aliasing).
  Contact sheet: `screenshots/sheets/windows-wine.png`.

## Not verified
Not run on real Windows 10/11; Wine is not Windows. Real `SendInput` delivery and rates, Raw Input
hotkeys on physical keyboards, focus/cursor safety with real windows, the click-through overlay over
other apps, DPI scaling, the Windows 11 frame colour and SmartScreen (the EXE is unsigned) need a
check on Windows. `FakeClickerReceiver.exe` helps measure the delivered rate.
