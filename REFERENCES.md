# References — 0.7.0

## Used
| Source | What was taken |
|---|---|
| [getdesign.md · Apple](https://getdesign.md/apple/design-md) (DESIGN.md via `npx getdesign add apple`) | Neutral palette: `#1d1d1f`, `#f5f5f7`, `#fafafc`, `#7a7a7a`, `#d2d2d7`@64%, `#0071e3`, `#272729`, `#000`; semibold headings, near-black primary pills |
| [getdesign.md · Mobbin](https://getdesign.md/mobbin/design-md) | Monochrome ladder for fields and lines: `#f0f0f0`, `#e0e0e0`, `#adadad` |
| [Apple: new software design (Liquid Glass), June 9, 2025](https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/) | Glass that reflects and refracts what is under it; controls that come alive when pressed |
| [WWDC25 · Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/) | Optical properties: specular rims, adaptive shadows, fluid morphing between states |
| [Apple HIG · Live Activities](https://developer.apple.com/design/human-interface-guidelines/live-activities) and [WWDC23 · Design dynamic Live Activities](https://developer.apple.com/videos/play/wwdc2023/10194/) | Dynamic Island presentations (compact, expanded, transient alerts) and glanceable live data |
| [Inter](https://rsms.me/inter/) 4.1 (OFL) | Bundled UI typeface |
| iOS 14 / iPadOS 14 system UI (inset grouped lists, sidebar, segmented control, switch, stepper) | The whole *Solid* material: structure, metrics and motion |
| [Qt 6 ShaderEffect](https://doc.qt.io/qt-6/qml-qtquick-shadereffect.html) and `qt_add_shaders` | Shader conventions used for real-time refraction on every graphics backend |

## Considered, not used
- **Raycast, Linear, Spectra** (0.4.x references). These are dark, dense tool aesthetics, so they were dropped because the brief asks for grey-white glass.
- **Desktop see-through (Windows acrylic/Mica behind the window).** Rejected: it cannot be verified here and is unreliable with Direct3D flip-model swap chains in a frameless window. The glass refracts the app's own animated backdrop instead.

No third-party artwork is bundled.
