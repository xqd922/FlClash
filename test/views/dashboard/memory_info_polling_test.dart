import 'package:fl_clash/views/dashboard/widgets/memory_info_polling.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Memory info polling', () {
    test('polls only while the dashboard is the current page', () {
      expect(
        shouldPollMemoryInfo(isDashboardCurrent: true, isAppResumed: true),
        isTrue,
      );
      expect(
        shouldPollMemoryInfo(isDashboardCurrent: false, isAppResumed: true),
        isFalse,
      );
    });

    test('skips polling while the app is not resumed', () {
      expect(
        shouldPollMemoryInfo(isDashboardCurrent: true, isAppResumed: false),
        isFalse,
      );
    });

    test('uses a conservative polling interval', () {
      expect(memoryInfoPollingInterval, const Duration(seconds: 5));
    });
  });
}
