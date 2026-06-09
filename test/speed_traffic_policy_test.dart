import 'package:fl_clash/speed_traffic_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Speed traffic sampling policy', () {
    test('samples while dashboard is visible', () {
      expect(
        shouldSampleSpeedTraffic(
          isDashboardCurrent: true,
          showTrayTitle: false,
        ),
        isTrue,
      );
    });

    test('samples while tray title needs live speed', () {
      expect(
        shouldSampleSpeedTraffic(
          isDashboardCurrent: false,
          showTrayTitle: true,
        ),
        isTrue,
      );
    });

    test('skips sampling when no visible surface needs live speed', () {
      expect(
        shouldSampleSpeedTraffic(
          isDashboardCurrent: false,
          showTrayTitle: false,
        ),
        isFalse,
      );
    });
  });
}
