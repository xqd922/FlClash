# 03 — Widget: replace Palette with HCT version

**What to build:** Replace the old circular color picker in `palette.dart` with the upstream's HCT-based Palette widget. Three sliders (Hue, Chroma, Tone grid) with live color scheme preview.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] `lib/widgets/palette.dart` contains HCT-based Palette widget
- [ ] Hue slider (0-360) with rainbow gradient track
- [ ] Chroma slider (0-10) with hue-tinted track
- [ ] Tone grid (0-100, steps of 10) with selection highlight
- [ ] Color scheme preview showing 8 color roles
- [ ] `material_color_utilities` dependency in pubspec.yaml
- [ ] App compiles successfully
