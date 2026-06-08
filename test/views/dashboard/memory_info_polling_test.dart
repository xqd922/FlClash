import 'package:fl_clash/views/dashboard/widgets/memory_info_polling.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Memory info polling', () {
    test('polls only while the dashboard is the current page', () {
      expect(shouldPollMemoryInfo(isDashboardCurrent: true), isTrue);
      expect(shouldPollMemoryInfo(isDashboardCurrent: false), isFalse);
    });

    test('uses a conservative polling interval', () {
      expect(memoryInfoPollingInterval, const Duration(seconds: 5));
    });
  });
}
