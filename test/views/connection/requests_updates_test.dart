import 'package:fl_clash/views/connection/requests_updates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Requests updates', () {
    test('updates the visible list only while requests is current', () {
      expect(shouldUpdateRequestsView(isRequestsCurrent: true), isTrue);
      expect(shouldUpdateRequestsView(isRequestsCurrent: false), isFalse);
    });
  });
}
