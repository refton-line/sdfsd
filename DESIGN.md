# C clicker 0.5 — design

A new design written from scratch. Nothing from the 0.4.x red/black look is reused.

## Direction
Grey-white Liquid Glass with very smooth motion. Most of the screen stays still. What moves has a
reason: drifting light under the glass, the island, the selection lens, the state of a run.
There are no hints, quotes or explanatory paragraphs. Words appear only where a control needs a name.

## Palette (from getdesign.md)
| Token | Hex | Source |
|---|---|---|
| ink | `#1d1d1f` | getdesign.md · Apple (near-black text, primary pills) |
| canvas / pearl | `#f5f5f7` / `#fafafc` | Apple (parchment, pearl surfaces) |
| muted | `#7a7a7a` | Apple (muted ink) |
| chip | `#d2d2d7` @ 64% | Apple (translucent chip gray; toggle track) |
| focus ring | `#0071e3` | Apple (focus blue) |
| island | `#000000`, raised `#272729` | Apple (pure black, near-black tile) |
| field / hairline | `#f0f0f0` / `#e0e0e0` | getdesign.md · Mobbin (field, hairline) |
| faint | `#adadad` | Mobbin (tertiary text) |
| backdrop | `#f2f2f7` | iOS grouped background (Solid material) |
| Legit / Blatant / countdown | `#34c759` / `#ff3b30` / `#ff9500` (bright island variants `#30d158` / `#ff453a` / `#ff9f0a`) | iOS system colours |

`qml/Theme.qml` is the only place where these tokens are defined.

## Materials
`Theme.glass` is a single 0..1 value that blends the two materials, so switching materials morphs.
- **Liquid Glass**: white fill at 44%, a top sheen, and a specular rim drawn as a gradient ring
  (bright at top-left, dim in the middle, catching light again at bottom-right). Interactive glass
  shows a pointer light. A soft contact shadow sits under each panel, and drifting radial light in
  the wallpaper shows through. Modal sheets blur the whole window behind them.
- **Solid**: opaque white cards on `#f2f2f7`, with no rim, no sheen and no moving light (iOS 14).

## Motion
- Springs (`SpringAnimation`) for everything spatial, so movement overshoots slightly and settles.
- The selection lens in the sidebar, segmented controls and mode tiles stretches in proportion to
  how far it still has to travel, like a drop.
- Pages: the outgoing page leaves in 150 ms and the incoming one arrives in 380 ms. Direction follows
  the sidebar order, and pages pass through a blur while semi-transparent.
- Launch: the island appears as a dot at the centre of the window, fills a progress ring, then
  springs up into the title bar while the sidebar, content and controls arrive in a stagger.
- Close: input stops first. Content sinks and fades, the island collapses to a dot, the light fades,
  then the window closes.
- Language switch: content fades out, swaps text and fades back in. Material switch: 700 ms morph.

## Dynamic Island
One black capsule (`qml/components/DynamicIsland.qml`) with these presentations: boot, idle, arming
(countdown ring), live (pulsing mode dot, activity bars, measured CPS), expanded (hover/click),
notice, error and summary. Width and height move on springs. Each presentation fades through blur,
with a short squash when a new one arrives. The floating copy (`IslandOverlay.qml`) is a separate
always-on-top window. Its native mask follows the capsule on every frame. It is disabled for input
and never activates, so the clicker's foreground and cursor checks still see the target window.

## Icons
Vector paths (`qml/components/Icons.js`) rendered with Qt Quick Shapes, tinted at runtime. Every
place has its own glyph: navigation (cursor, keyboard, stack, drop, globe), modes (hand, bolt),
materials (sparkle, square), profile actions (check, pencil, duplicate, export, trash, import,
folder), window chrome, and status (warning, check circle). The app icon is a glass squircle with an
open "C" that ends in a click point.

## Type
Inter (OFL, bundled, Cyrillic coverage) stands in for SF Pro, which cannot be redistributed.
Numbers use tabular figures.
