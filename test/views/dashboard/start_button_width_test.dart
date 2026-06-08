import 'package:fl_clash/views/dashboard/widgets/start_button_width.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Start button text width', () {
    test('adds horizontal padding to measured text width', () {
      expect(startButtonTextWidth(42), 58);
    });

    test('never returns a negative width', () {
      expect(startButtonTextWidth(-8), 16);
    });

    test('estimates runtime text width from character count', () {
      expect(estimatedStartButtonTextWidth('00:00'), 61);
      expect(estimatedStartButtonTextWidth('100:00:00'), 97);
    });

    test('shrinks icon right padding as the button expands', () {
      expect(startButtonExpandedIconRightPadding(0), 16);
      expect(startButtonExpandedIconRightPadding(0.5), 12);
      expect(startButtonExpandedIconRightPadding(1), 8);
    });

    test('clamps icon right padding progress', () {
      expect(startButtonExpandedIconRightPadding(-1), 16);
      expect(startButtonExpandedIconRightPadding(2), 8);
    });

    test('computes compact visual width from text and animation progress', () {
      expect(startButtonWidthForText('00:00:00', 0), startButtonIconHeight);
      expect(startButtonWidthForText('00:00:00', 1), 136);
    });

    test('clamps visual width progress and maximum width', () {
      expect(startButtonWidthForText('00:00:00', -1), startButtonIconHeight);
      expect(
        startButtonWidthForText('00:00:00-very-long-runtime', 2),
        startButtonMaxWidth,
      );
    });

    test('keeps floating action button height bounded', () {
      const constraints = startButtonSizeConstraints;

      expect(constraints.minWidth, startButtonIconHeight);
      expect(constraints.minHeight, startButtonIconHeight);
      expect(constraints.maxHeight, startButtonIconHeight);
      expect(constraints.maxWidth, 200);
      expect(constraints, isA<BoxConstraints>());
    });
  });
}
