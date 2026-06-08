import 'package:fl_clash/network_detection_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Network detection policy', () {
    test('does not start when initialization is the only change', () {
      expect(
        shouldStartNetworkDetection(
          previousIsInitialized: false,
          previousCheckRequest: 0,
          nextIsInitialized: true,
          nextCheckRequest: 0,
        ),
        isFalse,
      );
    });

    test('starts only for explicit check requests after initialization', () {
      expect(
        shouldStartNetworkDetection(
          previousIsInitialized: true,
          previousCheckRequest: 0,
          nextIsInitialized: true,
          nextCheckRequest: 1,
        ),
        isTrue,
      );
      expect(
        shouldStartNetworkDetection(
          previousIsInitialized: true,
          previousCheckRequest: 1,
          nextIsInitialized: true,
          nextCheckRequest: 1,
        ),
        isFalse,
      );
      expect(
        shouldStartNetworkDetection(
          previousIsInitialized: true,
          previousCheckRequest: 1,
          nextIsInitialized: false,
          nextCheckRequest: 2,
        ),
        isFalse,
      );
      expect(
        shouldStartNetworkDetection(
          previousIsInitialized: false,
          previousCheckRequest: 0,
          nextIsInitialized: true,
          nextCheckRequest: 1,
        ),
        isFalse,
      );
    });
  });
}
