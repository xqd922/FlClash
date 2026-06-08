import 'package:fl_clash/widgets/line_chart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Line chart normalization', () {
    test('normalizes points into a zero-to-one range', () {
      final points = normalizeLineChartPoints([
        const Point(10, 100),
        const Point(20, 150),
        const Point(30, 200),
      ]);

      expect(points[0].x, 0);
      expect(points[0].y, 0);
      expect(points[1].x, 0.5);
      expect(points[1].y, 0.5);
      expect(points[2].x, 1);
      expect(points[2].y, 1);
    });

    test('keeps flat axes at zero instead of returning NaN', () {
      final points = normalizeLineChartPoints([
        const Point(4, 9),
        const Point(4, 9),
      ]);

      expect(points.map((point) => point.x), [0, 0]);
      expect(points.map((point) => point.y), [0, 0]);
    });
  });

  group('Line chart interpolation', () {
    test('keeps endpoint values unchanged', () {
      expect(interpolateLineChartValue(2, 10, 0), 2);
      expect(interpolateLineChartValue(2, 10, 1), 10);
    });

    test('returns a value between endpoints during animation', () {
      expect(interpolateLineChartValue(2, 10, 0.25), 4);
      expect(interpolateLineChartValue(10, 2, 0.25), 8);
    });
  });
}
