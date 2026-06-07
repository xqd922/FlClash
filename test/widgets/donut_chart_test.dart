import 'package:fl_clash/widgets/donut_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Donut chart interpolation', () {
    test('keeps chart values unchanged at animation endpoints', () {
      final oldValue = DonutChartData(value: 4, color: Colors.red).value;
      final newValue = DonutChartData(value: 9, color: Colors.blue).value;

      expect(interpolateDonutChartValue(oldValue, newValue, 0), oldValue);
      expect(interpolateDonutChartValue(oldValue, newValue, 1), newValue);
    });

    test('returns a value between endpoints during animation', () {
      final oldValue = DonutChartData(value: 4, color: Colors.red).value;
      final newValue = DonutChartData(value: 9, color: Colors.blue).value;

      final value = interpolateDonutChartValue(oldValue, newValue, 0.5);

      expect(value, greaterThan(oldValue));
      expect(value, lessThan(newValue));
    });
  });
}
