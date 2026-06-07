import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/views/dashboard/widgets/network_speed_chart_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Network speed chart data', () {
    test('builds two baseline points before traffic samples', () {
      final points = buildNetworkSpeedPoints([
        Traffic(up: 1, down: 2),
        Traffic(up: 3, down: 4),
      ]);

      expect(points.length, 4);
      expect(points[0].x, 0);
      expect(points[0].y, 0);
      expect(points[1].x, 1);
      expect(points[1].y, 0);
      expect(points[2].x, 2);
      expect(points[2].y, 3);
      expect(points[3].x, 3);
      expect(points[3].y, 7);
    });

    test('returns an empty traffic sample when there is no history', () {
      expect(lastNetworkSpeedTraffic(const []), Traffic());
    });

    test('returns the latest traffic sample without copying history', () {
      final latest = Traffic(up: 8, down: 13);
      expect(
        lastNetworkSpeedTraffic([Traffic(up: 1, down: 1), latest]),
        latest,
      );
    });

    test('builds view data for chart and current speed text', () {
      final viewData = buildNetworkSpeedViewData([
        Traffic(up: 2, down: 3),
        Traffic(up: 5, down: 8),
      ]);

      expect(viewData.points.map((point) => point.y), [0, 0, 5, 13]);
      expect(viewData.currentSpeedText, Traffic(up: 5, down: 8).speedText);
    });
  });
}
