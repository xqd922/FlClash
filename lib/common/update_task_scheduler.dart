import 'dart:async';

typedef UpdateTaskCallback = FutureOr<void> Function();
typedef UpdateTaskPredicate = bool Function();

class ScheduledUpdateTask {
  ScheduledUpdateTask(
    this.callback, {
    this.interval = const Duration(seconds: 1),
    this.shouldRun,
  });

  final UpdateTaskCallback callback;
  final Duration interval;
  final UpdateTaskPredicate? shouldRun;
  DateTime? _lastRunAt;

  bool isDue(DateTime now) {
    if (shouldRun?.call() == false) {
      return false;
    }
    final lastRunAt = _lastRunAt;
    return lastRunAt == null || now.difference(lastRunAt) >= interval;
  }

  Future<void> run(DateTime now) async {
    await callback();
    _lastRunAt = now;
  }

  void reset() {
    _lastRunAt = null;
  }
}

class UpdateTaskScheduler {
  UpdateTaskScheduler(Iterable<ScheduledUpdateTask> tasks)
    : _tasks = List.unmodifiable(tasks);

  final List<ScheduledUpdateTask> _tasks;

  bool get isEmpty => _tasks.isEmpty;

  Future<void> runDueTasks([DateTime? now]) async {
    final currentTime = now ?? DateTime.now();
    for (final task in _tasks) {
      if (task.isDue(currentTime)) {
        await task.run(currentTime);
      }
    }
  }

  void reset() {
    for (final task in _tasks) {
      task.reset();
    }
  }
}
