import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('startRuntimeUpdates gates runtime writes by dashboard visibility', () {
    final source = File('lib/controller.dart').readAsStringSync();
    final methodStart = source.indexOf('Future<void> startRuntimeUpdates()');
    final methodEnd = source.indexOf(
      'Future<void> updateTraffic()',
      methodStart,
    );
    final methodBody = source.substring(methodStart, methodEnd);

    expect(
      methodBody,
      contains(
        'ScheduledUpdateTask(updateRunTime, shouldRun: _shouldUpdateRunTime)',
      ),
    );
  });
}
