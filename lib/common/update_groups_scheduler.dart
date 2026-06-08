class UpdateGroupsScheduler {
  final Duration minInterval;
  final DateTime Function() now;
  Future<void>? _inFlight;
  DateTime? _lastCompletedAt;

  UpdateGroupsScheduler({
    this.minInterval = const Duration(milliseconds: 1000),
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<void> run(Future<void> Function() task) {
    final inFlight = _inFlight;
    if (inFlight != null) {
      return inFlight;
    }
    final lastCompletedAt = _lastCompletedAt;
    final currentTime = now();
    if (lastCompletedAt != null &&
        currentTime.difference(lastCompletedAt) < minInterval) {
      return Future.value();
    }
    final future = task();
    _inFlight = future;
    future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
      _lastCompletedAt = now();
    });
    return future;
  }
}
