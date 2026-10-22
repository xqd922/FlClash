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
  TextTheme get withSystemWeights => copyWith(
    titleLarge: titleLarge?.withRegularWeight,
    titleMedium: titleMedium?.withRegularWeight,
    titleSmall: titleSmall?.withRegularWeight,
    bodyLarge: bodyLarge?.withRegularWeight,
    bodyMedium: bodyMedium?.withRegularWeight,
    bodySmall: bodySmall?.withRegularWeight,
    labelLarge: labelLarge?.withRegularWeight,
    labelMedium: labelMedium?.withRegularWeight,
    labelSmall: labelSmall?.withRegularWeight,
  );
}

extension TypographyExtension on Typography {
  Typography get withSystemWeights => Typography(
    black: black.withSystemWeights,
    white: white.withSystemWeights,
    englishLike: englishLike.withSystemWeights,
    dense: dense.withSystemWeights,
    tall: tall.withSystemWeights,
  );
}
