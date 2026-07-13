# 01 — Model: add primaryColor/primaryColors to ThemeProps

**What to build:** Add `primaryColor` (nullable int) and `primaryColors` (List<int>) fields to the `ThemeProps` model, add the `defaultPrimaryColors` constant, and regenerate freezed code. After this ticket, the app compiles with the new fields and existing config files deserialize correctly with defaults.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] `ThemeProps` has `int? primaryColor` field (null = auto/system color)
- [ ] `ThemeProps` has `List<int> primaryColors` field with `@Default(defaultPrimaryColors)`
- [ ] `defaultPrimaryColors` constant exists in `lib/common/constant.dart`
- [ ] Freezed code regenerated (`build_runner build`)
- [ ] App compiles successfully
- [ ] Existing config JSON without these fields deserializes to defaults
