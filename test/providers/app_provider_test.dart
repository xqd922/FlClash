import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('TotalTraffic skips unchanged traffic notifications', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifications = <Traffic>[];
    container.listen<Traffic>(
      totalTrafficProvider,
      (_, next) => notifications.add(next),
    );

    final notifier = container.read(totalTrafficProvider.notifier);
    const traffic = Traffic(up: 1, down: 2);
    notifier.value = traffic;
    notifier.value = traffic;

    expect(notifications, [traffic]);
  });

  test('RunTime skips unchanged runtime notifications', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifications = <int?>[];
    container.listen<int?>(
      runTimeProvider,
      (_, next) => notifications.add(next),
    );

    final notifier = container.read(runTimeProvider.notifier);
    notifier.value = 1000;
    notifier.value = 1000;
    notifier.value = null;
    notifier.value = null;

    expect(notifications, [1000, null]);
  });
}
