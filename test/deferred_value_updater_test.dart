import 'package:fl_clash/deferred_value_updater.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Deferred value updater', () {
    test('does not schedule when the next value is already current', () {
      final scheduled = <void Function()>[];
      final updates = <int>[];
      final updater = DeferredValueUpdater<int>(
        read: () => 1,
        write: updates.add,
        schedule: scheduled.add,
      );

      updater.update(1);

      expect(scheduled, isEmpty);
      expect(updates, isEmpty);
    });

    test('coalesces duplicate pending values into one scheduled update', () {
      final scheduled = <void Function()>[];
      final updates = <int>[];
      final updater = DeferredValueUpdater<int>(
        read: () => updates.isEmpty ? 1 : updates.last,
        write: updates.add,
        schedule: scheduled.add,
      );

      updater.update(2);
      updater.update(2);

      expect(scheduled.length, 1);
      scheduled.single();
      expect(updates, [2]);
    });

    test('schedules the latest changed value', () {
      final scheduled = <void Function()>[];
      final updates = <int>[];
      final updater = DeferredValueUpdater<int>(
        read: () => updates.isEmpty ? 1 : updates.last,
        write: updates.add,
        schedule: scheduled.add,
      );

      updater.update(2);
      updater.update(3);

      expect(scheduled.length, 1);
      scheduled.single();
      expect(updates, [3]);
    });
  });
}
