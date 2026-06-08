typedef DeferredValueReader<T> = T Function();
typedef DeferredValueWriter<T> = void Function(T value);
typedef DeferredValueScheduler = void Function(void Function() callback);

class DeferredValueUpdater<T> {
  DeferredValueUpdater({
    required this.read,
    required this.write,
    required this.schedule,
  });

  final DeferredValueReader<T> read;
  final DeferredValueWriter<T> write;
  final DeferredValueScheduler schedule;
  T? _pendingValue;
  bool _hasPendingValue = false;
  bool _isScheduled = false;

  void update(T value) {
    if (!_hasPendingValue && read() == value) {
      return;
    }
    _pendingValue = value;
    _hasPendingValue = true;
    if (_isScheduled) {
      return;
    }
    _isScheduled = true;
    schedule(_flush);
  }

  void _flush() {
    _isScheduled = false;
    if (!_hasPendingValue) {
      return;
    }
    final value = _pendingValue as T;
    _pendingValue = null;
    _hasPendingValue = false;
    if (read() == value) {
      return;
    }
    write(value);
  }
}
