# QA — 0.5.0

| Check | Result |
|---|---|
| Native Linux build (Qt 6.8.3 gcc_64, Release) | passes, no warnings |
| `controller_tests` | 681 assertions pass: planner statistics (Legit average within 2%, variance ordering, seeded sequences, warm-up, holds always inside gaps up to 1000 CPS), Blatant grid and batching (no drift over 10⁶ slots, batching at 10k CPS, stall bursts capped, count-limit accounting, nanosecond limit), uncapped CPS validation, v4 schema, v1–v3 migration, bundled examples import, plus the full 0.4.7 binding suite |
| Windows cross-build (MinGW-w64 13 posix, Qt 6.8.3 mingw_64) | passes, no warnings; static import audit finds no unresolved non-system DLL |
| Screenshot tour (`--capture`, Xvfb + Mesa OpenGL) | every page, both materials, both languages, all island presentations, keyboard sheet, transitions, closing |
| Physical Windows run | **not performed here**: SendInput delivery, Raw Input with real keyboards, DPI scaling and DWM corners need testing on Windows |
