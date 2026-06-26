import 'dart:async';

class Store<T> {
  late T _data;
  // NOTE: StreamSubscription 保存以便 dispose 时取消，避免泄漏。
  late final StreamSubscription<T> _subscription;

  Store(Stream stream, T defaultValue) {
    // NOTE: stream 参数是无类型的 Stream，需要 cast 为 Stream<T> 以匹配 StreamSubscription<T>。
    _subscription = (stream as Stream<T>).listen((data) {
      _add(data);
    });
    _data = defaultValue;
  }

  void dispose() {
    _subscription.cancel();
    _streamController.close();
  }

  bool equals(T oldValue, T newValue) {
    return oldValue == newValue;
  }

  void _add(T value) {
    if (!equals(_data, value)) {
      _streamController.add(value);
      _data = value;
    }
  }

  final StreamController<T> _streamController = StreamController<T>.broadcast();

  Stream<T> get stream => _streamController.stream;

  T get value => _data;

  set value(T value) {
    _add(value);
  }
}
