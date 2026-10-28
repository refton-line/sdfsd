# References — 0.5.0

## Used
| Source | What was taken |
|---|---|
| [getdesign.md · Apple](https://getdesign.md/apple/design-md) (DESIGN.md via `npx getdesign add apple`) | Neutral palette: `#1d1d1f`, `#f5f5f7`, `#fafafc`, `#7a7a7a`, `#d2d2d7`@64%, `#0071e3`, `#272729`, `#000`; semibold headings, near-black primary pills |
| [getdesign.md · Mobbin](https://getdesign.md/mobbin/design-md) | Monochrome ladder for fields and lines: `#f0f0f0`, `#e0e0e0`, `#adadad` |
| [Apple: new software design (Liquid Glass), June 9, 2025](https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/) | Glass that reflects and refracts what is under it; controls that come alive when pressed |
| [WWDC25 · Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/) | Optical properties: specular rims, adaptive shadows, fluid morphing between states |
| [Apple HIG · Live Activities](https://developer.apple.com/design/human-interface-guidelines/live-activities) and [WWDC23 · Design dynamic Live Activities](https://developer.apple.com/videos/play/wwdc2023/10194/) | Dynamic Island presentations (compact, expanded, transient alerts) and glanceable live data |
| [Inter](https://rsms.me/inter/) 4.1 (OFL) | Bundled UI typeface |

## Considered, not used
- **iOS 14 widgets and cards.** This is the reference for the *Solid* material only: opaque white on `#f2f2f7`.
- **Raycast, Linear, Spectra** (0.4.x references). These are dark, dense tool aesthetics, so they were dropped because the brief asks for grey-white glass.
- **Real refraction shader.** Lensing the background at glass edges would need custom shaders compiled for every graphics API. The rim gradient, sheen and blur give the same impression at a fraction of the risk.
- **System acrylic / Mica.** Windows backdrop materials do not compose reliably with Direct3D flip-model swap chains in a frameless window. The glass is rendered inside the window.

No third-party artwork is bundled.
