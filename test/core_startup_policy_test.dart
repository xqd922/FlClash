import 'package:fl_clash/core_startup_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Core startup policy', () {
    test(
      'skips eager group refresh while startup status still applies config',
      () {
        expect(
          shouldRefreshGroupsAfterCoreInit(
            coreAlreadyInitialized: true,
            needsInitialStatusSetup: true,
          ),
          isFalse,
        );
      },
    );

    test(
      'refreshes groups when core is already initialized and no setup follows',
      () {
        expect(
          shouldRefreshGroupsAfterCoreInit(
            coreAlreadyInitialized: true,
            needsInitialStatusSetup: false,
          ),
          isTrue,
        );
      },
    );

    test('does not refresh groups before core initialization', () {
      expect(
        shouldRefreshGroupsAfterCoreInit(
          coreAlreadyInitialized: false,
          needsInitialStatusSetup: false,
        ),
        isFalse,
      );
    });
  });
}
