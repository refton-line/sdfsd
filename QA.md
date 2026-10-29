# QA — 0.8.0

## Automated (Linux, Qt 6.8.3 gcc_64): `ctest` 4/4 PASS
- Controller: 740 assertions — click timing, configuration, hotkeys, profiles (incl. Light clicker v4
  import) and sounds: clicker updates → cues (countdown, start, stop, cancel, finish on a limit,
  errors), every cue is a valid 48 kHz mono PCM WAV, muted/silent/unknown/doubled cues stay quiet.
- Raster icons: 10 281 checks / 1 680 renders; 42 glyphs at 12–32 px, DPR 100/125/150/200 %, no corner specks.
- Source contracts: icon tables in sync, CPU icon raster, native island text, layered skull mark;
  the 14 sound cues match the C++ table, every cue QML or the clicker asks for, and the WAV files
  (mono 48 kHz 16-bit, 15 ms–1.2 s, peaks −24…−5 dBFS, no click at either edge).
- Motion contracts: 28 QML files; hover colour changes are instant; no springs, overshoot, glass or blur.

## Screenshots (`--capture`, Linux/Xvfb/Mesa OpenGL, synthetic engine states, no real clicks)
- `screenshots/`: 41 PNGs — launch, Legit/Blatant, island (expanded, notices, countdown, running, summary,
  error), hotkeys and key sheet, profiles and save sheet, settings with the Sound panel, Russian pages,
  overlay island, window picker, the sounds-off and volume notices, closing fade. The sidebar holds
  only the four pages.
- `screenshots/launch/`: 13 slow-motion launch frames (`FAKECLICKER_MOTION_SCALE=6`): two jaw bites,
  loading bar, fade into the interface. `screenshots/sheets/` holds contact sheets.
- Sound log of the tour (`FAKECLICKER_SOUND_LOG`): `jaw`, `jaw2` at launch, then `count`, `start`,
  `done`, `error`, `confirm` at the matching steps; no QML warnings.

## Windows x64 build
- Cross-built with MinGW-w64 GCC 13 (posix) on Ubuntu 24.04 against Qt 6.8.3 mingw_64.
- Static PE import audit: 110 PE files, 53 DLLs copied, 0 unresolved non-system DLLs (`dependency-audit.json`).
  Sound adds no DLL: `xaudio2_9.dll` is loaded from System32 at run time.
- Wine 9.0 smoke run (Xvfb + Mesa): the packaged `FakeClicker.exe --capture` finished the same 41-screen
  tour with exit code 0. Against the Linux screenshots, Hotkeys and Settings differ by 0 px and the
  other compared screens by under 1 % (anti-aliasing). Contact sheet: `screenshots/sheets/windows-wine.png`.
- Wine audio, recorded from a PulseAudio null sink: every cue after launch was found in the recording
  by cross-correlation with its WAV (r = 0.60–1.00, three full tours). The two launch clacks reached
  the recording in 3 of 5 runs; a Wine trace shows XAudio2 received them on time (`SubmitSourceBuffer`
  at the logged moments), so those misses and the short exact-zero gaps inside some cues come from
  the Wine/PulseAudio stream under the tour's full CPU load (2 vCPU, software rendering), not from
  the playback code. The same cue played clean elsewhere, also with `QT_QUICK_BACKEND=software`.
- No audio device: Wine's XAudio2 crashed inside `CreateMasteringVoice` (divide by zero in
  `xaudio2_9.dll`) when neither PulseAudio nor ALSA had an output. Found by the final check and fixed
  by asking MMDevAPI for a default output device first; the packaged tour now finishes with no device
  (exit 0, 41 screens, sounds stay off) and with one (sounds play).

## Not verified
Not run on real Windows 10/11; Wine is not Windows. Real `SendInput` delivery and rates, Raw Input
hotkeys on physical keyboards, focus/cursor safety with real windows, the click-through overlay over
other apps, DPI scaling, the Windows 11 frame colour, SmartScreen (the EXE is unsigned) and how the
sounds actually sound through XAudio2 on real hardware (level, latency, switching audio devices)
need a check on Windows. `FakeClickerReceiver.exe` helps measure the delivered rate.
