import 'package:fl_clash/enum/enum.dart';
import 'package:material_ui/material_ui.dart';

import 'color.dart';

// Flutter 3.41 起 fontWeight 会隐式写入可变字体的 wght 轴，而 HyperOS 等系统的
// 中文回退字体 MiSans 是可变字体，界面文字因此整体变粗。显式钉住 wght 轴可让
// 可变字体按默认字重渲染；Roboto 等静态字体不支持该轴，不受影响。
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
