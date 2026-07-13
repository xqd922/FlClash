# 02 — Widget: restore ColorSchemeBox and PrimaryColorBox

**What to build:** Restore the `ColorSchemeBox` and `PrimaryColorBox` widgets from upstream. `ColorSchemeBox` shows a mini 2x2 color scheme preview with selection checkmark. `PrimaryColorBox` wraps a child with a generated `ColorScheme`. Export from `widgets.dart`.

**Blocked by:** 01 — theme-props-model

**Status:** ready-for-agent

- [ ] `lib/widgets/color_scheme_box.dart` exists with `ColorSchemeBox` and `PrimaryColorBox`
- [ ] Exported from `lib/widgets/widgets.dart`
- [ ] `ColorSchemeBox` renders 2x2 grid (primary/secondary/tertiary) with selection state
- [ ] `PrimaryColorBox` uses `genColorSchemeProvider` to generate color scheme
- [ ] Auto color (null) shows colorize icon
- [ ] App compiles successfully
