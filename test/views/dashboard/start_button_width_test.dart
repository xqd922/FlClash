import 'package:fl_clash/views/dashboard/widgets/start_button_width.dart';
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
  });
}
