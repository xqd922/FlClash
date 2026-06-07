import 'package:fl_clash/common/update_task_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpdateTaskScheduler', () {
    test('runs all tasks immediately on first tick', () async {
      var fastRuns = 0;
      var slowRuns = 0;
      final scheduler = UpdateTaskScheduler([
        ScheduledUpdateTask(() => fastRuns++),
        ScheduledUpdateTask(
          () => slowRuns++,
          interval: const Duration(seconds: 5),
        ),
      ]);

      await scheduler.runDueTasks(DateTime.fromMillisecondsSinceEpoch(1000));

      expect(fastRuns, 1);
      expect(slowRuns, 1);
    });

    test('runs each task only after its own interval', () async {
      var fastRuns = 0;
      var slowRuns = 0;
      final scheduler = UpdateTaskScheduler([
        ScheduledUpdateTask(() => fastRuns++),
        ScheduledUpdateTask(
          () => slowRuns++,
          interval: const Duration(seconds: 5),
        ),
      ]);
      final start = DateTime.fromMillisecondsSinceEpoch(1000);

      await scheduler.runDueTasks(start);
      await scheduler.runDueTasks(start.add(const Duration(seconds: 1)));
      await scheduler.runDueTasks(start.add(const Duration(seconds: 4)));
      await scheduler.runDueTasks(start.add(const Duration(seconds: 5)));

      expect(fastRuns, 4);
      expect(slowRuns, 2);
    });

    test('reset makes tasks eligible on the next tick', () async {
      var runs = 0;
      final scheduler = UpdateTaskScheduler([
        ScheduledUpdateTask(() => runs++, interval: const Duration(seconds: 5)),
      ]);
      final start = DateTime.fromMillisecondsSinceEpoch(1000);

      await scheduler.runDueTasks(start);
      await scheduler.runDueTasks(start.add(const Duration(seconds: 1)));
      scheduler.reset();
      await scheduler.runDueTasks(start.add(const Duration(seconds: 2)));

      expect(runs, 2);
    });
  });
}
