import 'package:fl_clash/views/logs_updates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Logs updates', () {
    test('updates the visible list only while logs is current', () {
      expect(
        shouldUpdateLogsView(isLogsCurrent: true, isAppResumed: true),
        isTrue,
      );
      expect(
        shouldUpdateLogsView(isLogsCurrent: false, isAppResumed: true),
        isFalse,
      );
    });

    test('skips visible list updates while the app is not resumed', () {
      expect(
        shouldUpdateLogsView(isLogsCurrent: true, isAppResumed: false),
        isFalse,
      );
    });
  });
}
