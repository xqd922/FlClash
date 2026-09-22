import 'package:fl_clash/common/text.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

const _pinnedVariation = FontVariation('wght', 400);

void _expectPinned(TextStyle? style) {
  expect(style, isNotNull);
  expect(style!.fontVariations, contains(_pinnedVariation));
}

void main() {
  for (final brightness in Brightness.values) {
    test('every typography geometry pins wght on ${brightness.name}', () {
      final typography = Typography.material2021(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: brightness,
        ),
      ).toDefaultWeight;

      for (final theme in [
        typography.black,
        typography.white,
        typography.englishLike,
        typography.dense,
        typography.tall,
      ]) {
        _expectPinned(theme.displayLarge);
        _expectPinned(theme.headlineLarge);
        _expectPinned(theme.titleMedium);
        _expectPinned(theme.bodyLarge);
        _expectPinned(theme.labelLarge);
      }
    });

    test('theme text styles stay pinned on ${brightness.name}', () {
      final theme = ThemeData(
        typography: Typography.material2021(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: brightness,
          ),
        ).toDefaultWeight,
      );

      _expectPinned(theme.textTheme.displayLarge);
      _expectPinned(theme.textTheme.headlineLarge);
      _expectPinned(theme.textTheme.titleMedium);
      _expectPinned(theme.textTheme.bodyLarge);
      _expectPinned(theme.textTheme.labelLarge);
    });
  }

  test('styles derived from a pinned base keep the pin', () {
    final derived = const TextStyle().toDefaultWeight.copyWith(
      fontWeight: FontWeight.w600,
    );

    _expectPinned(derived);
  });

  test('scratch styles pin when asked', () {
    _expectPinned(const TextStyle(fontWeight: FontWeight.w600).toDefaultWeight);
  });

  test('empty text theme slots stay null', () {
    expect(const TextTheme().toDefaultWeight.titleMedium, isNull);
  });
}
