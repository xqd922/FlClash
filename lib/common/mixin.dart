import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

mixin AutoDisposeNotifierMixin<T> on AnyNotifier<T, T> {
  T get value => state;

  set value(T value) {
    state = value;
  }

  bool equals(T previous, T next) {
    return false;
  }

  @override
  bool updateShouldNotify(previous, next) {
    if (equals(previous, next)) return false;
    final res = super.updateShouldNotify(previous, next);
    if (res) onUpdate(next);
    return res;
  }

  void onUpdate(T value) {}

  void update(T? Function(T) builder) {
    final res = builder(value);
    if (res == null) {
      return;
    }
    value = res;
  }
}

mixin AsyncNotifierMixin<T> on AnyNotifier<AsyncValue<T>, T> {
  T get value;

  set value(T value) {
    state = AsyncData(value);
  }
}
