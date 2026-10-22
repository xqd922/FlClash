import 'package:fl_clash/enum/enum.dart';
import 'package:material_ui/material_ui.dart';

import 'color.dart';

extension TextStyleExtension on TextStyle {
  TextStyle get toLight => copyWith(color: color?.opacity80);

  TextStyle get toLighter => copyWith(color: color?.opacity60);

  TextStyle get toSoftBold => withRegularWeight;

  TextStyle get toBold => copyWith(fontWeight: FontWeight.bold);

  TextStyle get toJetBrainsMono =>
      copyWith(fontFamily: FontFamily.jetBrainsMono.value);

  TextStyle adjustSize(int size) => copyWith(fontSize: fontSize! + size);

  TextStyle get withRegularWeight => copyWith(fontWeight: FontWeight.w400);
}

extension TextThemeExtension on TextTheme {
  /// Android's framework TextAppearance uses 22sp for large text, 18sp for
  /// medium text, 16sp for ordinary text and 14sp for small text, all at 400.
  TextTheme get withAndroidSystemSizes => copyWith(
    headlineLarge: headlineLarge?.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      height: 1.29,
      letterSpacing: 0,
    ),
    headlineMedium: headlineMedium?.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0,
    ),
    headlineSmall: headlineSmall?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w400,
      height: 1.36,
      letterSpacing: 0,
    ),
    titleLarge: titleLarge?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w400,
      height: 1.36,
      letterSpacing: 0,
    ),
    titleMedium: titleMedium?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0,
    ),
    titleSmall: titleSmall?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.25,
      letterSpacing: 0,
    ),
    bodyLarge: bodyLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.15,
    ),
    bodyMedium: bodyMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.15,
    ),
    bodySmall: bodySmall?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0.2,
    ),
    labelLarge: labelLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.25,
      letterSpacing: 0.1,
    ),
    labelMedium: labelMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.29,
      letterSpacing: 0.2,
    ),
    labelSmall: labelSmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.3,
    ),
  );
}

extension TypographyExtension on Typography {
  Typography get withAndroidSystemSizes => Typography(
    black: black.withAndroidSystemSizes,
    white: white.withAndroidSystemSizes,
    englishLike: englishLike.withAndroidSystemSizes,
    dense: dense.withAndroidSystemSizes,
    tall: tall.withAndroidSystemSizes,
  );
}
