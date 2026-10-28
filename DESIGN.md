# Light clicker 0.7 — design

A new design written from scratch. Nothing from the 0.4.x red/black look is reused. 0.6 turns the two materials into two complete design languages.

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
| Solid tint / separator | `#007aff` / `#e0e0e5` | iOS 14 system blue and light separator (Solid material only) |
| Legit / Blatant / countdown | `#34c759` / `#ff3b30` / `#ff9500` (bright island variants `#30d158` / `#ff453a` / `#ff9f0a`) | iOS system colours |

`qml/Theme.qml` is the only place where these tokens are defined.

## Two materials, two apps
`Theme.material` is `"glass"` or `"solid"`. Choosing one restyles everything: surfaces, navigation, controls, page and sheet motion, and the backdrop.

**Switching.** `SkinReveal.qml` snapshots the window, applies the new material underneath, then
`shaders/reveal.frag` erases the old look in a circle that grows from the pointer. The front is a
bright liquid band that bends the old image outward as it passes.

### Liquid Glass
- **Real refraction.** `GlassSurface.qml` runs `shaders/glass.frag`. It computes a rounded-rectangle SDF, bends the backdrop inward across a curved bezel (refraction grows quadratically towards the rim), mixes sharp and frosted samples, splits RGB slightly at the edge, and adds a lit bezel, a two-sided specular rim and far-side shade.
- **Everything is glass.** `Fill.qml` replaces every filled rectangle. On solid it is that rectangle; on glass it is a `GlassSurface` tinted with the same colour: opaque colours become strongly tinted glass (Start button, selected chip, mode and hotkey badges, key caps, island), faint fills become recessed `inset` glass lit from below (segmented tracks, stepper tracks, wells). Only text, hairlines, status dots and the waveform are not glass.
- **Backdrop.** `Main.qml` keeps four live textures: the wallpaper, a frosted copy of it, the whole stage (wallpaper and pages), and a frosted copy of the stage. Cards sample the wallpaper. Floating glass (tab bar, its lens, sheets, the island and its controls) samples the stage, so content behind them refracts too. Glass in the overlay window has no backdrop (`detached`) and is drawn from its tint, a vertical sheen and the rim light. Each surface follows its on-screen position every frame while anything moves.
- **Wallpaper.** A grey-white field with orbiting white and graphite masses and thin silver arcs. It gives the glass something visible to bend and frost.
- **Navigation.** A floating tab bar. The selection is a clear lens whose stretch, swell and magnification follow its speed.
- **Controls.** Glass capsules that squash on press. Switch knobs turn into a clear lens while held. Segmented lenses stretch towards their target.
- **Motion.** Springs with overshoot. Pages lift, scale and settle. Sheets spring in over a blurred window.

### Solid (iOS 14)
- Inset grouped sections: uppercase headers, white groups with radius 10 on `#f2f2f7`, 1 px separators, and grey icon tiles in the style of Settings.
- iPadOS 14 sidebar: the logo, blue line icons, filled `#007aff` selection. No section headers above groups; rows say what they are.
- iOS 14 controls: white segmented thumb with dividers, classic 51×31 switch, stepper pill, tinted buttons that dim on press.
- Motion: eased with no overshoot. Pages slide horizontally like a push; sheets slide up over a 32% dim.

## Motion rules
- Springs (`SpringAnimation`) for spatial glass motion. Critically damped springs or ease-out curves for solid.
- Outgoing content leaves quickly (110–150 ms). Incoming content arrives in 260–380 ms and starts at once, with no gap between the two.
- Continuous effects (island waveform, countdown ring, pulse, tab-bar lens speed) are evaluated every frame from a running clock rather than as looping keyframes, so they never visibly stop or step.
- Launch: nothing snaps at the start. The plain window warms up into the wallpaper while the star fades and grows in (720 ms, in-out sine); its ink half fills from the bottom up, paced so it never jumps. The star then flies (860 ms, in-out cubic) into the title bar or the sidebar and becomes the logo. The island grows out of the title bar half-way, and navigation, content and controls follow in a stagger where every part eases in and out on its own (smoothstep over an in-out cubic).
- Close mirrors the launch. Input stops first. The UI folds away in reverse order, the island collapses, the star flies back to the centre, its ink drains from the top, then the star and the wallpaper fade into the plain window, which closes (about 0.9 s).
- Minimize, maximize, restore and Snap are the system animations: `WindowEffects::enableNativeFrame` gives the frameless window an invisible caption and thick frame (`WM_NCCALCSIZE` hands the whole window to the client, and a maximized window is fitted to the work area), and the title-bar buttons call `ShowWindow`.

## Dynamic Island
One capsule (`DynamicIsland.qml`), smoked Liquid Glass on glass and black on solid, on springs (`spring 3.3, damping 0.25`) with a
velocity-driven squash and stretch. Its content is drawn in a fixed-size layer and masked to the
moving capsule, so nothing pokes out mid-morph and no textures are reallocated.

- **Views:** idle, arming, live, expanded, notice, error, summary (hidden while the app loads).
- **Expanded (hover or click):** Legit/Blatant switch, large CPS with −/+ (idle) or a live waveform (running), clicks and time while running, and a 76 px Start/Cancel/Stop button with a continuous countdown ring.
- **Priority:** hover-expansion beats notices and errors, so it responds at once and never queues behind them.
- **Overlay:** the floating copy (`IslandOverlay.qml`) is input-transparent and never activates, so the clicker's foreground and cursor checks still see the target window.

## Icons
Vector paths (`qml/components/Icons.js`) rendered with Qt Quick Shapes, tinted at runtime. Every
place has its own glyph: navigation (cursor, keyboard, stack, drop, globe), modes (hand, bolt),
shortcut kinds (keyboard for a single key, two joined keycaps for a combination),
materials (sparkle, square), profile actions (check, pencil, duplicate, export, trash, import,
folder), window chrome, and status (warning, check circle).

## Logo
`shaders/mark.frag` draws the mark: a rounded five-point star, point up (an exact distance field
after Inigo Quilez's `sdStar5`, notch radius 0.5 of the tip radius), lowered slightly so it sits
centred. The split runs through the top tip and the bottom notch. Both halves share one silhouette
and one soft shadow, so the star reads symmetric. Left of the split it is grey-tinted Liquid Glass:
a frosted body with sharp refraction only in the bezel, lit from above, with a one-pixel graphite
edge as crisp as the ink edge. Right of the split it is solid `#1d1d1f`. Below 60 px the star gets
chubbier with softer tips, and the glass half turns a mid grey so it weighs the same as the ink half. `AppMark.qml` wraps it;
during launch `progress` fills the ink half from the bottom up, and the unfilled part waits as a
faint star. The Windows icon (`assets/app.ico`, 16–256 px) and the window icon are rendered from
the same shader by `scripts/render-icon.sh` and `tools/icon/RenderIcon.qml`, with a squircle tile
split the same way (frosted glass | white).

## Type
Inter (OFL, bundled, Cyrillic coverage) stands in for SF Pro, which cannot be redistributed.
Numbers use tabular figures.
