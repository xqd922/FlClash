import 'package:fl_clash/views/logs_updates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Logs updates', () {
    test('updates the visible list only while logs is current', () {
      expect(shouldUpdateLogsView(isLogsCurrent: true), isTrue);
      expect(shouldUpdateLogsView(isLogsCurrent: false), isFalse);
    });
  });
}
