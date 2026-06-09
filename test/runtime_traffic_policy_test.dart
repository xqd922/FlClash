import 'package:fl_clash/runtime_traffic_policy.dart';
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

  group('Total traffic sampling policy', () {
    test('samples while dashboard is visible', () {
      expect(shouldSampleTotalTraffic(isDashboardCurrent: true), isTrue);
    });

    test('skips while dashboard is not visible', () {
      expect(shouldSampleTotalTraffic(isDashboardCurrent: false), isFalse);
    });
  });
}
