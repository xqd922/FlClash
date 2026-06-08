import 'package:fl_clash/views/connection/connections_polling.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Connections polling', () {
    test('polls only while connections is the current page', () {
      expect(shouldPollConnections(isConnectionsCurrent: true), isTrue);
      expect(shouldPollConnections(isConnectionsCurrent: false), isFalse);
    });

    test(
      'uses a conservative polling interval for active connection details',
      () {
        expect(connectionsPollingInterval, const Duration(seconds: 2));
      },
    );
  });
}
