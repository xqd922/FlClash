import 'package:fl_clash/enum/enum.dart';
import 'package:material_ui/material_ui.dart';

import 'color.dart';

// Flutter 3.41 起 fontWeight 会隐式写入可变字体的 wght 轴，HyperOS 的 MiSans 等中文回退字体因此整体变粗；显式钉住优先于隐式轴值，静态字体不支持该轴不受影响。
const _kDefaultWeightVariations = <FontVariation>[FontVariation('wght', 400)];

extension TextStyleExtension on TextStyle {
  TextStyle get toLight => copyWith(color: color?.opacity80);

  TextStyle get toLighter => copyWith(color: color?.opacity60);

  TextStyle get toSoftBold => copyWith(fontWeight: FontWeight.w500);

  TextStyle get toBold => copyWith(fontWeight: FontWeight.bold);

  TextStyle get toJetBrainsMono =>
      copyWith(fontFamily: FontFamily.jetBrainsMono.value);

  TextStyle adjustSize(int size) => copyWith(fontSize: fontSize! + size);

  TextStyle get toDefaultWeight =>
      copyWith(fontVariations: _kDefaultWeightVariations);
}

extension TextThemeExtension on TextTheme {
  TextTheme get toDefaultWeight => TextTheme(
    displayLarge: displayLarge?.toDefaultWeight,
    displayMedium: displayMedium?.toDefaultWeight,
    displaySmall: displaySmall?.toDefaultWeight,
    headlineLarge: headlineLarge?.toDefaultWeight,
    headlineMedium: headlineMedium?.toDefaultWeight,
    headlineSmall: headlineSmall?.toDefaultWeight,
    titleLarge: titleLarge?.toDefaultWeight,
    titleMedium: titleMedium?.toDefaultWeight,
    titleSmall: titleSmall?.toDefaultWeight,
    bodyLarge: bodyLarge?.toDefaultWeight,
    bodyMedium: bodyMedium?.toDefaultWeight,
    bodySmall: bodySmall?.toDefaultWeight,
    labelLarge: labelLarge?.toDefaultWeight,
    labelMedium: labelMedium?.toDefaultWeight,
    labelSmall: labelSmall?.toDefaultWeight,
  );
}

extension TypographyExtension on Typography {
  Typography get toDefaultWeight => Typography(
    black: black.toDefaultWeight,
    white: white.toDefaultWeight,
    englishLike: englishLike.toDefaultWeight,
    dense: dense.toDefaultWeight,
    tall: tall.toDefaultWeight,
  );
}
