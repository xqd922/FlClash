import 'dart:async';

import 'package:fl_clash/local_ip_refresh.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Local IP refresh', () {
    test('shares one in-flight lookup across concurrent refreshes', () async {
      final completer = Completer<String?>();
      var lookupCount = 0;
      final values = <String?>[];
      final controller = LocalIpRefreshController(
        lookup: () {
          lookupCount++;
          return completer.future;
        },
        update: values.add,
      );

      final first = controller.refresh();
      final second = controller.refresh();

      expect(lookupCount, 1);
      expect(identical(first, second), isTrue);
      expect(values, isEmpty);

      completer.complete('192.168.1.2');
      await Future.wait([first, second]);

      expect(values, ['192.168.1.2']);
    });

    test('starts a new lookup after the previous refresh completes', () async {
      var lookupCount = 0;
      final values = <String?>[];
      final controller = LocalIpRefreshController(
        lookup: () async => '192.168.1.${++lookupCount}',
        update: values.add,
      );

      await controller.refresh();
      await controller.refresh();

      expect(lookupCount, 2);
      expect(values, ['192.168.1.1', '192.168.1.2']);
    });
  });
}
