# QA — 0.7.0

| Check | Result |
|---|---|
| Native Linux build (Qt 6.8.3 gcc_64, Release) | passes, no warnings |
| `controller_tests` | 683 assertions pass: planner statistics (Legit average within 2%, variance ordering, seeded sequences, warm-up, holds always inside gaps up to 1000 CPS), Blatant grid and batching (no drift over 10⁶ slots, batching at 10k CPS, stall bursts capped, count-limit accounting, nanosecond limit), uncapped CPS validation, v4 schema, v1–v3 migration, previous-format v4 profiles still import, `light-clicker` accepts only v4, bundled examples import, plus the full 0.4.7 binding suite |
| Windows cross-build (MinGW-w64 13 posix, Qt 6.8.3 mingw_64) | passes, no warnings; static import audit finds no unresolved non-system DLL (110 PE files) |
| Shaders | `glass.frag`, `reveal.frag` and `mark.frag` compile to SPIR-V, GLSL 100es/120/150, HLSL 50 (D3D11) and MSL 12 via `qt_add_shaders`; rendered and inspected on OpenGL (Mesa) |
| Screenshot tour (`--capture`, Xvfb + Mesa OpenGL) | 37 frames: launch (loading star, rays lighting, landing in the title bar), every page in both materials with all controls as glass, both languages, all island views including expanded idle and running, keyboard and name sheets in both materials, frames during the material-switch wave, page transition, overlay, closing |
| App icon | `scripts/render-icon.sh` renders `app.ico` (16–256 px) and `app-icon.png` from `mark.frag`; sizes inspected at 16–256 px |
| Physical Windows run | **not performed here**: SendInput delivery, Raw Input with real keyboards, DPI scaling, DWM corners and the Direct3D 11 path of the glass shaders need testing on Windows. Software OpenGL here renders only a few frames per second, so motion smoothness was judged from code and frames, not measured |
