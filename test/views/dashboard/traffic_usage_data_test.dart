import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/views/dashboard/widgets/traffic_usage_data.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Traffic usage data', () {
    test('builds traffic values and donut data from total traffic', () {
      final viewData = buildTrafficUsageViewData(
        const Traffic(up: 12, down: 34),
        uploadColor: Colors.red,
        downloadColor: Colors.blue,
      );

      expect(viewData.uploadValue, 12);
      expect(viewData.downloadValue, 34);
      expect(viewData.donutData, [
        const DonutChartData(value: 12, color: Colors.red),
        const DonutChartData(value: 34, color: Colors.blue),
      ]);
    });
  });
}
