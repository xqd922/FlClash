import 'package:fl_clash/core_event_update_groups_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Core event update groups policy', () {
    test('refreshes when no previous group refresh is known', () {
      expect(
        shouldRefreshGroupsAfterCoreEvent(
          lastGroupsRefreshAt: null,
          eventAt: DateTime.fromMillisecondsSinceEpoch(1000),
        ),
        isTrue,
      );
    });

    test('skips event refresh shortly after a full group refresh', () {
      final lastRefresh = DateTime.fromMillisecondsSinceEpoch(1000);

      expect(
        shouldRefreshGroupsAfterCoreEvent(
          lastGroupsRefreshAt: lastRefresh,
          eventAt: lastRefresh.add(const Duration(seconds: 5)),
        ),
        isFalse,
      );
    });

    test('refreshes after the quiet period', () {
      final lastRefresh = DateTime.fromMillisecondsSinceEpoch(1000);

      expect(
        shouldRefreshGroupsAfterCoreEvent(
          lastGroupsRefreshAt: lastRefresh,
          eventAt: lastRefresh.add(coreEventGroupRefreshQuietPeriod),
        ),
        isTrue,
      );
    });
  });
}
