# QA — 0.6.0

| Check | Result |
|---|---|
| Native Linux build (Qt 6.8.3 gcc_64, Release) | passes, no warnings |
| `controller_tests` | 681 assertions pass: planner statistics (Legit average within 2%, variance ordering, seeded sequences, warm-up, holds always inside gaps up to 1000 CPS), Blatant grid and batching (no drift over 10⁶ slots, batching at 10k CPS, stall bursts capped, count-limit accounting, nanosecond limit), uncapped CPS validation, v4 schema, v1–v3 migration, bundled examples import, plus the full 0.4.7 binding suite |
| Windows cross-build (MinGW-w64 13 posix, Qt 6.8.3 mingw_64) | passes, no warnings; static import audit finds no unresolved non-system DLL |
| Shaders | `glass.frag` and `reveal.frag` compile to SPIR-V, GLSL 100es/120/150, HLSL 50 (D3D11) and MSL 12 via `qt_add_shaders`; rendered and inspected on OpenGL (Mesa) |
| Screenshot tour (`--capture`, Xvfb + Mesa OpenGL) | 35 frames: every page in both materials, both languages, all island views including expanded idle and running, keyboard and name sheets in both materials, frames during the material-switch wave, page transition, overlay, closing |
| Physical Windows run | **not performed here**: SendInput delivery, Raw Input with real keyboards, DPI scaling, DWM corners and the Direct3D 11 path of the glass shaders need testing on Windows. Software OpenGL here renders only a few frames per second, so motion smoothness was judged from code and frames, not measured |
