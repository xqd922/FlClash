import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_clash/connectivity_policy.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Connectivity policy', () {
    test('normalizes connectivity results before comparison', () {
      expect(
        normalizeConnectivityResults([
          ConnectivityResult.vpn,
          ConnectivityResult.wifi,
          ConnectivityResult.wifi,
        ]),
        [ConnectivityResult.wifi, ConnectivityResult.vpn],
      );
    });

    test('ignores repeated connectivity results', () {
      expect(
        shouldHandleConnectivityResults(
          previousResults: [ConnectivityResult.vpn, ConnectivityResult.wifi],
          nextResults: [ConnectivityResult.wifi, ConnectivityResult.vpn],
          lifecycleState: AppLifecycleState.resumed,
        ),
        isFalse,
      );
    });

    test('ignores connectivity events while not resumed', () {
      expect(
        shouldHandleConnectivityResults(
          previousResults: [ConnectivityResult.wifi],
          nextResults: [ConnectivityResult.mobile],
          lifecycleState: AppLifecycleState.paused,
        ),
        isFalse,
      );
    });

    test('handles changed connectivity results while resumed', () {
      expect(
        shouldHandleConnectivityResults(
          previousResults: [ConnectivityResult.wifi],
          nextResults: [ConnectivityResult.mobile],
          lifecycleState: AppLifecycleState.resumed,
        ),
        isTrue,
      );
    });

    test('only checks public IP when VPN presence changes', () {
      expect(
        shouldCheckIpAfterConnectivityChange(
          previousResults: [ConnectivityResult.wifi],
          nextResults: [ConnectivityResult.wifi, ConnectivityResult.vpn],
        ),
        isTrue,
      );
      expect(
        shouldCheckIpAfterConnectivityChange(
          previousResults: [ConnectivityResult.mobile, ConnectivityResult.vpn],
          nextResults: [ConnectivityResult.wifi, ConnectivityResult.vpn],
        ),
        isFalse,
      );
    });

    test('change gate suppresses repeated foreground events', () {
      final gate = ConnectivityChangeGate();

      expect(
        gate.handle([
          ConnectivityResult.wifi,
        ], lifecycleState: AppLifecycleState.resumed),
        [ConnectivityResult.wifi],
      );
      expect(
        gate.handle([
          ConnectivityResult.wifi,
        ], lifecycleState: AppLifecycleState.resumed),
        isNull,
      );
    });

    test('change gate ignores background events without storing them', () {
      final gate = ConnectivityChangeGate();

      expect(
        gate.handle([
          ConnectivityResult.wifi,
        ], lifecycleState: AppLifecycleState.resumed),
        [ConnectivityResult.wifi],
      );
      expect(
        gate.handle([
          ConnectivityResult.mobile,
        ], lifecycleState: AppLifecycleState.paused),
        isNull,
      );
      expect(
        gate.handle([
          ConnectivityResult.mobile,
        ], lifecycleState: AppLifecycleState.resumed),
        [ConnectivityResult.mobile],
      );
    });
  });
}
