import 'package:fl_clash/common/text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('app typography pins variable font wght axis', () {
    for (final brightness in Brightness.values) {
      test('$brightness text theme styles carry wght=400', () {
        final colorScheme = ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: brightness,
        );
        final typography = Typography.material2021(
          platform: defaultTargetPlatform,
          colorScheme: colorScheme,
        ).toDefaultWeight;
        final theme = ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
          typography: typography,
        );
        for (final style in [
          theme.textTheme.displayLarge,
          theme.textTheme.headlineMedium,
          theme.textTheme.titleMedium,
          theme.textTheme.bodyLarge,
          theme.textTheme.bodyMedium,
          theme.textTheme.labelLarge,
          theme.textTheme.labelSmall,
        ]) {
          expect(
            style?.fontVariations,
            contains(const FontVariation('wght', 400)),
          );
        }
      });
    }

    test('derived styles keep the pinned axis', () {
      const style = TextStyle(fontSize: 16);
      final pinned = ThemeData().textTheme.bodyMedium!;
      expect(
        pinned.toDefaultWeight
            .copyWith(fontWeight: FontWeight.w600)
            .fontVariations,
        contains(const FontVariation('wght', 400)),
      );
      expect(style.toDefaultWeight.fontVariations, isNotEmpty);
    });
  });
}
