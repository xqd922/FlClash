import 'package:fl_clash/enum/enum.dart';
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

  test('NetworkDetection starts idle until a check is requested', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(networkDetectionProvider).isLoading, isFalse);
  });

  test('CurrentGroupsState reuses groups that have no runtime selection', () {
    final proxy = Proxy(name: 'Proxy A', type: 'ss');
    final group = Group(
      name: 'Group A',
      type: GroupType.Selector,
      hidden: false,
      all: [proxy],
    );
    final container = ProviderContainer(
      overrides: [
        groupsProvider.overrideWithValue([group]),
        patchClashConfigProvider.overrideWithValue(ClashConfig()),
      ],
    );
    addTearDown(container.dispose);

    final groups = container.read(currentGroupsStateProvider).value;

    expect(groups, hasLength(1));
    expect(identical(groups.first, group), isTrue);
    expect(identical(groups.first.all.first, proxy), isTrue);
  });

  test('CurrentGroupsState only copies groups with runtime selection', () {
    final cleanProxy = Proxy(name: 'Proxy A', type: 'ss');
    final selectedProxy = Proxy(name: 'Proxy B', type: 'ss', now: 'fast');
    final group = Group(
      name: 'Group A',
      type: GroupType.Selector,
      now: 'Proxy B',
      hidden: false,
      all: [cleanProxy, selectedProxy],
    );
    final container = ProviderContainer(
      overrides: [
        groupsProvider.overrideWithValue([group]),
        patchClashConfigProvider.overrideWithValue(ClashConfig()),
      ],
    );
    addTearDown(container.dispose);

    final sanitizedGroup = container.read(currentGroupsStateProvider).value;

    expect(sanitizedGroup, hasLength(1));
    expect(identical(sanitizedGroup.first, group), isFalse);
    expect(sanitizedGroup.first.now, '');
    expect(identical(sanitizedGroup.first.all.first, cleanProxy), isTrue);
    expect(identical(sanitizedGroup.first.all.last, selectedProxy), isFalse);
    expect(sanitizedGroup.first.all.last.now, '');
  });
}
