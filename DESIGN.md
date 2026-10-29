# Fake Clicker 0.8 design

**Direction.** One dark theme in pure monochrome, after projectreal.gg and the Nike system on
getdesign.md. Black canvas, graphite panels with hairline edges, white type, one white pill for
the main action. Colour appears only where it carries state. No glass, blur, gradients-as-decoration
or bouncy motion. Tokens live in `qml/Theme.qml`.

## Tokens

| Role | Value |
|---|---|
| Canvas | `#000000` |
| Panel / raised / control | `#0B0B0B` / `#121212` / `#181818` (hover `#202020`, active `#2A2A2A`) |
| Hairline / strong hairline | `#1C1C1C` / `#2C2C2C` |
| Text: ink / soft / muted / faint | `#FFFFFF` / `#C9C9CB` / `#8E8E91` / `#5C5C5F` |
| Legit (Nike Success) | `#1EAA52` |
| Blatant, Stop, errors (Nike Sale) | `#D30005`; small red text on black uses `#FF4D52` |
| Radii | panels 14, controls 10, key caps 6; buttons are pills/circles |
| Motion | 110 / 160 / 240 ms, `OutCubic`; no springs, `OutBack` or overshoot |

**Type.** Geist (400–900) for interface text; Geist Mono for captions, units, key caps and tabular
numbers. Page titles are uppercase ExtraBold; section captions are 11 px uppercase mono with open
tracking. All text uses native grayscale rasterisation.

## Layout

- **Title bar:** skull mark and the `FAKE CLICKER` wordmark on the left, the Dynamic Island in the
  centre, window controls on the right (close turns red on hover).
- **Sidebar:** Clicker, Hotkeys, Profiles, Settings and nothing else; the keys live on the Hotkeys page.
- **Pages:** an uppercase title, then panels. Clicker has Mode (with one-line descriptions), Rate,
  Options (button, variance or hold, time limit, click limit — each on its own labelled row) and
  a Session panel with live rate, chart, totals, target window and the Start button
  (white → red Stop while running, graphite with a filling pill while counting down).
- **Settings:** language, the island-over-other-windows switch, Sound (on/off and volume), and About;
  clicking the About skull makes it bite.

## Logo and launch

The mark is a skull over two crossed bones (`assets/logo/*.svg`), drawn on one 128×128 artboard in
three layers: bones (grey `#8E8E91`), jaw and cranium (`#F4F4F4`). It is drawn sober rather than
cartoonish: anatomical proportions, a low brow over angular orbits, a sharp nasal opening,
cheekbones, a tapered jaw with a squared chin, stencil-cut teeth and bones with real condyles. Jaw
and cranium sit on black backings 1.3 units wider than the white, leaving a thin cut line between
skull, jaw and bones; the line widens as the jaw opens and the mouth stays black. The jaw is
animated separately.
Launch shows the skull, the wordmark and a 2 px loading bar; the skull bites twice (open 130 ms,
snap shut 85 ms, twice) while the bar fills with real startup progress, then the splash fades and
the interface fades in. Launch takes about a second; closing is a 150 ms fade. The intro starts on
the first presented frame so a slow first render never hides the bite. `scripts/render-icon.sh`
builds `app.ico`/`app-icon.png` from the same SVGs (16/24 px drop the bones).

## Sound

Short, dry and quiet, in one key (E major) so the tonal cues sit together. All are synthesised by
`scripts/render-sounds.py` into `assets/sounds/*.wav` (48 kHz mono 16-bit, 20 ms–1.1 s, peaks
−21 to −6 dBFS) and embedded in the EXE.

| Cue | When |
|---|---|
| `tap` | buttons, navigation, list rows, keys in the key sheet, window controls |
| `select` | mode, segmented choices, CPS presets, language |
| `switchOn` / `switchOff` | switches (rising / falling pair of ticks) |
| `step` | −/+ on steppers, the CPS field and the island |
| `count` | each second of the countdown, from the moment Start is pressed |
| `start` / `stop` | the run begins / is stopped or cancelled (button or hotkey) |
| `done` | the run ended on its own: a time or click limit |
| `confirm` / `remove` / `error` | saved, applied, imported or bound / deleted / any failure or engine error |
| `jaw`, `jaw2` | the teeth meeting at each of the two launch bites |

Buttons whose result has its own sound (Start, Save, Delete, Apply) do not tick as well, and the
same cue twice within 80 ms plays once. Session cues come from `SoundEngine::sessionCues`, so a
hotkey start in another window sounds the same as the button. Settings → Sound mutes everything or
sets the volume in 10 % steps (gain = level^1.5); the switch that turns sounds off still clicks.
Windows plays through XAudio2 2.9 (`xaudio2_9.dll`, loaded from System32) on a dedicated thread: the
UI only queues cues, a cue that waited over 150 ms is dropped rather than played late, and a lost
or changed audio device is reopened on the next cue. Other platforms are silent.
`FAKECLICKER_SOUND_LOG=<file>` records each cue with its time for QA.

## Dynamic Island

A black capsule with a `#262626` hairline; size changes ease in 200 ms (150 ms in the overlay).
Views: idle (mode badge, mode, target CPS), arming (white countdown ring), live (waveform in the mode
colour, measured CPS), expanded (mode switch, big value, −/+, white Start / red Stop button),
summary, error and notices.

Notices now say **what changed** (muted) and **the new value** (bright), each with its own glyph:
rate `gauge`, button `mouse`, variance `wave`, hold `hold`, time limit `hourglass`, click limit
`hash`, countdown `timer`, start/stop keys `play`/`stop` with the key shown as a key cap, target
window `target`, mode `hand`/`bolt` in the mode colour, language `globe`. The overlay switch shows
`overlay` + a white **ON** pill or `overlayOff` (struck through) + an outlined **OFF** pill instead of
the old `✓`/`—`. "No limit" replaces `∞` in notices.

## Icons

40 line glyphs on a 24 px grid (`assets/icons.json`, mirrored in `Icons.js`), rasterised on the
CPU at the exact physical size. New in 0.8: `gauge`, `hold`, `hash`, `overlay`, `overlayOff`,
`sliders`. Removed: `drop`, `liquidLens`, `square`, `sparkle`, `translate`, `save`, `island`.
