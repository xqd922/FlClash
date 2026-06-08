import 'package:fl_clash/auto_check_update_policy.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auto check update scheduling', () {
    test('does not schedule when automatic checks are disabled', () {
      var scheduled = false;

      scheduleAutoCheckUpdate(
        isEnabled: () => false,
        lifecycleState: () => AppLifecycleState.resumed,
        schedule: (_, _) => scheduled = true,
        checkForUpdate: () async {},
        onError: (_, _) {},
      );

      expect(scheduled, isFalse);
    });

    test('schedules with startup delay without running immediately', () {
      Duration? scheduledDelay;
      VoidCallback? scheduledTask;
      var checkCount = 0;

      scheduleAutoCheckUpdate(
        isEnabled: () => true,
        lifecycleState: () => AppLifecycleState.resumed,
        schedule: (delay, task) {
          scheduledDelay = delay;
          scheduledTask = task;
        },
        checkForUpdate: () async {
          checkCount++;
        },
        onError: (_, _) {},
      );

      expect(scheduledDelay, autoCheckUpdateStartupDelay);
      expect(checkCount, 0);

      scheduledTask!();

      expect(checkCount, 1);
    });

    test('skips delayed check when app is no longer foreground', () {
      var lifecycleState = AppLifecycleState.resumed;
      VoidCallback? scheduledTask;
      var checkCount = 0;

      scheduleAutoCheckUpdate(
        isEnabled: () => true,
        lifecycleState: () => lifecycleState,
        schedule: (_, task) => scheduledTask = task,
        checkForUpdate: () async {
          checkCount++;
        },
        onError: (_, _) {},
      );

      lifecycleState = AppLifecycleState.paused;
      scheduledTask!();

      expect(checkCount, 0);
    });

    test('skips delayed check when automatic checks are disabled later', () {
      var isEnabled = true;
      VoidCallback? scheduledTask;
      var checkCount = 0;

      scheduleAutoCheckUpdate(
        isEnabled: () => isEnabled,
        lifecycleState: () => AppLifecycleState.resumed,
        schedule: (_, task) => scheduledTask = task,
        checkForUpdate: () async {
          checkCount++;
        },
        onError: (_, _) {},
      );

      isEnabled = false;
      scheduledTask!();

      expect(checkCount, 0);
    });
  });
}
