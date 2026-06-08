import 'dart:async';

import 'package:fl_clash/common/update_groups_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpdateGroupsScheduler', () {
    test('shares one in-flight update across concurrent callers', () async {
      final completer = Completer<void>();
      var runs = 0;
      final scheduler = UpdateGroupsScheduler(
        minInterval: Duration.zero,
        now: () => DateTime.fromMillisecondsSinceEpoch(0),
      );

      final first = scheduler.run(() {
        runs++;
        return completer.future;
      });
      final second = scheduler.run(() {
        runs++;
        return Future.value();
      });

      expect(identical(first, second), isTrue);
      expect(runs, 1);

      completer.complete();
      await Future.wait([first, second]);
    });

    test('skips updates inside the minimum interval', () async {
      var now = DateTime.fromMillisecondsSinceEpoch(1000);
      var runs = 0;
      final scheduler = UpdateGroupsScheduler(
        minInterval: const Duration(seconds: 1),
        now: () => now,
      );

      await scheduler.run(() async => runs++);
      now = now.add(const Duration(milliseconds: 500));
      await scheduler.run(() async => runs++);

      expect(runs, 1);
    });

    test('runs again after the minimum interval', () async {
      var now = DateTime.fromMillisecondsSinceEpoch(1000);
      var runs = 0;
      final scheduler = UpdateGroupsScheduler(
        minInterval: const Duration(seconds: 1),
        now: () => now,
      );

      await scheduler.run(() async => runs++);
      now = now.add(const Duration(seconds: 1));
      await scheduler.run(() async => runs++);

      expect(runs, 2);
    });

    test('records when the latest update completed', () async {
      var now = DateTime.fromMillisecondsSinceEpoch(1000);
      final scheduler = UpdateGroupsScheduler(now: () => now);

      await scheduler.run(() async {
        now = DateTime.fromMillisecondsSinceEpoch(1500);
      });

      expect(
        scheduler.lastCompletedAt,
        DateTime.fromMillisecondsSinceEpoch(1500),
      );
    });

    test('normalizes synchronous task failures into failed futures', () async {
      var now = DateTime.fromMillisecondsSinceEpoch(1000);
      final scheduler = UpdateGroupsScheduler(now: () => now);

      final update = scheduler.run(() {
        now = DateTime.fromMillisecondsSinceEpoch(1500);
        throw StateError('boom');
      });

      await expectLater(update, throwsA(isA<StateError>()));
      expect(
        scheduler.lastCompletedAt,
        DateTime.fromMillisecondsSinceEpoch(1500),
      );
    });
  });
}
