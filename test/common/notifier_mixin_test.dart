import 'package:fl_clash/common/common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

final _equalValueProvider = NotifierProvider<_EqualValueNotifier, int>(
  _EqualValueNotifier.new,
);

class _EqualValueNotifier extends Notifier<int> with AutoDisposeNotifierMixin {
  @override
  int build() {
    return 0;
  }

  @override
  bool equals(previous, next) {
    return previous == next;
  }
}

void main() {
  test('AutoDisposeNotifierMixin suppresses equal state notifications', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifications = <int>[];
    container.listen<int>(
      _equalValueProvider,
      (_, next) => notifications.add(next),
    );

    container.read(_equalValueProvider.notifier).value = 0;
    container.read(_equalValueProvider.notifier).value = 1;
    container.read(_equalValueProvider.notifier).value = 1;

    expect(notifications, [1]);
  });
}
