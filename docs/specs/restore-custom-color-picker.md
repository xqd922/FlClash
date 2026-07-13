# Spec: Restore Custom Color Picker with HCT Palette

## Problem Statement

The custom color picker was removed in commit `7a23a6b` ("Simplify theme system and remove Firebase"). Users lost the ability to set a custom theme color via a "+" button and color palette dialog. The upstream project (chen08209/FlClash) has since upgraded the palette to use HCT color model (Hue/Chroma/Tone sliders with live color scheme preview). The user wants to restore this feature using the upstream's latest implementation, but only the "+" button and palette — not the scheme variant selector, pure black mode, text scaling, or font family features.

## Solution

Restore the custom color picker feature with:
- A color list (initially empty) displayed as a grid of `ColorSchemeBox` widgets
- A "+" button to add new colors via a palette dialog
- Click a color to set it as the active theme color
- Long press a color to enter delete mode (shows delete overlay)
- A reset button to restore defaults
- The upstream's latest HCT-based `Palette` widget (replacing the old circular picker)
- The `ColorSchemeBox` and `PrimaryColorBox` helper widgets from upstream

No scheme variant selector, pure black mode, text scaling, or font family features.

## User Stories

1. As a user, I want to see a "Theme Color" section in the theme settings page, so that I can customize my app's accent color
2. As a user, I want to see an empty color grid with only a "+" button when no custom colors have been added, so that the UI is clean by default
3. As a user, I want to tap the "+" button to open a palette dialog, so that I can pick a custom color
4. As a user, I want the palette dialog to show a Hue slider with a rainbow gradient track, so that I can select the base hue intuitively
5. As a user, I want the palette dialog to show a Chroma slider that reflects the current hue, so that I can control color saturation
6. As a user, I want the palette dialog to show a Tone grid (0-100 in steps of 10), so that I can pick the exact lightness/darkness
7. As a user, I want the palette dialog to show a live color scheme preview (Primary, Secondary, Tertiary, Error, Surface, and their containers), so that I can see how the color will look across the app before confirming
8. As a user, I want to confirm the color selection and have it added to my color list
9. As a user, I want to cancel the palette dialog without any changes
10. As a user, I want to see a duplicate-color warning if I try to add a color that already exists
11. As a user, I want to tap a color in the list to set it as my active theme color
12. As a user, I want to long-press a color to enter delete mode
13. As a user, I want to see a delete overlay button on the long-pressed color
14. As a user, I want to see a cancel button when in delete mode
15. As a user, I want a confirmation dialog before deleting a color
16. As a user, I want the selected color to be automatically deselected if I delete it, falling back to default (system) color
17. As a user, I want a reset button that appears only when values differ from defaults
18. As a user, I want the reset button to show a confirmation dialog before resetting
19. As a user, I want pressing back while in delete mode to exit delete mode instead of leaving the page
20. As a user, I want the first color in the grid to represent the "auto/system" default (null)
21. As a user, I want each color box to show a mini preview of the generated color scheme (primary, secondary, tertiary swatches)
22. As a user, I want the selected color box to have a checkmark overlay
23. As a user, I want my custom color selections to persist across app restarts
24. As a user, I want the color grid to be responsive and adjust columns based on available width

## Implementation Decisions

### Module: ThemeProps model (`lib/models/config.dart`)
- Add `int? primaryColor` field (nullable, null = use system/auto color)
- Add `List<int> primaryColors` field with `@Default(defaultPrimaryColors)` annotation
- Do NOT add `schemeVariant`, `pureBlack`, or `textScale` fields

### Module: Constants (`lib/common/constant.dart`)
- Restore `defaultPrimaryColors` constant (list of 7 preset color int values, including `defaultPrimaryColor`)

### Module: Palette widget (`lib/widgets/palette.dart`)
- Replace the current old circular picker with the upstream's latest HCT-based Palette
- Uses `material_color_utilities` package's `Hct` class
- Three controls: `_HueSlider` (0-360), `_ChromaSlider` (0-10), `_ToneGrid` (0/10/20/.../100)
- Includes `_ColorSchemePreview` showing 8 color roles
- Includes `_HueTrackShape` and `_ChromaTrackShape` custom slider track painters

### Module: ColorSchemeBox and PrimaryColorBox (`lib/widgets/color_scheme_box.dart`)
- Restore from upstream's version
- `ColorSchemeBox`: 2x2 grid of primary/secondary/tertiary colors in a `CommonCard`, with selection checkmark and colorize icon for null (auto) color
- `PrimaryColorBox`: wraps child with a generated `ColorScheme` from `genColorSchemeProvider`
- Add export to `lib/widgets/widgets.dart`

### Module: Theme view (`lib/views/theme.dart`)
- Add `_PrimaryColorItem` as a `ConsumerStatefulWidget`
- Manages `_removablePrimaryColor` state for delete mode
- Grid layout: `Wrap` with responsive column calculation (`maxWidth / 96`)
- First item is always `null` (auto/system color)
- Each item is a `ColorSchemeBox` wrapped in `EffectGestureDetector` for long press
- "+" button shown when not in delete mode
- Reset button (replay icon) shown when values differ from defaults
- Cancel button shown when in delete mode
- `_handleAdd()`: opens `_PaletteDialog`, checks for duplicates, adds to list
- `_handleDel()`: shows confirmation, removes from list, deselects if active
- `_handleReset()`: shows confirmation, restores defaults
- Back button interception via `CommonPopScope` to exit delete mode first

### Module: Palette dialog (`lib/views/theme.dart`)
- `_PaletteDialog` with `ValueNotifier<Color>` controller
- Initial color: `Color(Hct.from(0, 0, 60).toInt())` (neutral gray)
- Contains the `Palette` widget and confirm/cancel buttons
- Returns `int` (ARGB32 value) on confirm, `null` on cancel

### Provider integration
- `ThemeSetting` notifier already supports `update()` with `copyWith`
- `genColorSchemeProvider` already exists and handles color generation
- No changes needed to the provider layer — just add fields to `ThemeProps`

### Schema changes
- `ThemeProps` gains two fields: `primaryColor` (nullable int) and `primaryColors` (List<int>)
- Backward-compatible — existing configs without these fields will use defaults
- Run `dart run build_runner build --delete-conflicting-outputs` after model changes

## Testing Decisions

- **ThemeProps serialization**: verify `primaryColor` and `primaryColors` round-trip through JSON, and that missing fields deserialize to defaults
- **Duplicate detection**: verify adding an existing color shows a notifier warning
- **Delete cascade**: verify deleting the active color falls back to null (auto)
- **Reset behavior**: verify reset restores both `primaryColors` and `primaryColor` to defaults
- **Back button in delete mode**: verify `CommonPopScope` intercepts back navigation

No existing test infrastructure found. If tests are added, focus on `ThemeProps` model serialization and provider state transitions.

## Out of Scope

- Scheme variant selector (`DynamicSchemeVariant` toggle)
- Pure black mode toggle
- Text scale factor slider
- Font family selector
- Firebase/analytics integration
- Any changes to core proxy/VPN functionality

## Further Notes

- `material_color_utilities` package must be in `pubspec.yaml` dependencies
- After modifying `ThemeProps`, run `dart run build_runner build --delete-conflicting-outputs`
- The upstream uses `ClipRSuperellipse` — verify Flutter version compatibility
