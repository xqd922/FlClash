# 04 — Theme view: add _PrimaryColorItem with +, delete, reset

**What to build:** Add the `_PrimaryColorItem` widget to the theme settings page. Color grid with responsive layout, "+" button to add colors via palette dialog, long-press to delete, reset button, and back-button interception for delete mode.

**Blocked by:** 01 — theme-props-model, 02 — color-scheme-box, 03 — palette-hct

**Status:** ready-for-agent

- [ ] "Theme Color" section visible in theme settings
- [ ] Color grid shows auto (null) + user-added colors as `ColorSchemeBox` widgets
- [ ] "+" button opens `_PaletteDialog` with HCT palette
- [ ] Duplicate color detection with notifier warning
- [ ] Click color to set as active theme color
- [ ] Long press to enter delete mode with delete overlay
- [ ] Cancel button to exit delete mode
- [ ] Confirmation dialog before delete
- [ ] Deleting active color falls back to null (auto)
- [ ] Reset button appears when values differ from defaults
- [ ] Reset confirmation dialog restores defaults
- [ ] Back button in delete mode exits delete mode, not page
- [ ] Grid is responsive (columns based on width)
- [ ] Color selections persist across app restarts
