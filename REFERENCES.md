# References — Fake Clicker 0.8.0

## Used
| Source | What was taken |
|---|---|
| [projectreal.gg](https://projectreal.gg) (site CSS and app mock-ups, Oct 2026) | The overall direction: pure black canvas (`#000`), graphite panels (`#0C0C0C`–`#111`), white hairlines at 7–12 % alpha, white pill call-to-action with dark text, dark secondary pills, tight bold headings, Geist type, a top bar with the logo on the left and a left navigation rail like its desktop app |
| [getdesign.md · Nike](https://getdesign.md/nike/design-md) ([source](https://github.com/VoltAgent/awesome-design-md/tree/main/design-md/nike)) | Monochrome discipline and greys (`#111111`, `#39393B`, `#4B4B4D`, `#707072`, `#9E9EA0`, `#CACACB`), uppercase display headings, colour reserved for state: **Success `#1EAA52`** (Legit) and **Sale `#D30005`** (Blatant, Stop, errors) |
| [getdesign.md · BMW M](https://getdesign.md/bmw-m/design-md) | Dark surface ladder on black (`#0D0D0D`, `#1A1A1A`, `#262626`), body grey `#BBBBBB` for secondary text on black |
| [getdesign.md · SpaceX](https://getdesign.md/spacex/design-md) | Black canvas with hairlines instead of shadows |
| [Geist and Geist Mono](https://github.com/vercel/geist-font) 1.8.2 (OFL) | Bundled typefaces; Cyrillic coverage verified. Geist Mono sets captions, units, key caps and numbers in tables |
| [Apple HIG · Live Activities](https://developer.apple.com/design/human-interface-guidelines/live-activities) | Only for the Dynamic Island behaviour that the app keeps as its signature: compact, expanded and transient presentations |

## Dropped from 0.7.x
- **Liquid Glass and the iOS 14 "Solid" material** (Apple newsroom, WWDC25, iOS 14 system UI), the refraction/reveal/star shaders, the wallpaper and the material switch. The app now has one dark theme.
- **Inter**, replaced by Geist.
- **Spring motion with overshoot.** All motion is short and eased (110–260 ms); tests enforce it.

The skull mark, icons and app icon are original vector artwork drawn for this project. The interface sounds are original too:
`scripts/render-sounds.py` synthesises them from damped resonances, soft tones and filtered noise. No third-party artwork or audio is bundled.
