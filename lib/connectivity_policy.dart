import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

List<ConnectivityResult> normalizeConnectivityResults(
  List<ConnectivityResult> results,
) {
  return results.toSet().toList()..sort((a, b) => a.index.compareTo(b.index));
}

bool areConnectivityResultsEqual(
  List<ConnectivityResult>? previousResults,
  List<ConnectivityResult> nextResults,
) {
  final normalizedPrevious = normalizeConnectivityResults(
    previousResults ?? const [],
  );
  final normalizedNext = normalizeConnectivityResults(nextResults);
  if (normalizedPrevious.length != normalizedNext.length) {
    return false;
  }
  for (var i = 0; i < normalizedNext.length; i++) {
    if (normalizedPrevious[i] != normalizedNext[i]) {
      return false;
    }
  }
  return true;
}

bool shouldHandleConnectivityResults({
  required List<ConnectivityResult>? previousResults,
  required List<ConnectivityResult> nextResults,
  required AppLifecycleState? lifecycleState,
}) {
  final isForeground =
      lifecycleState == null || lifecycleState == AppLifecycleState.resumed;
  if (!isForeground) {
    return false;
  }
  return !areConnectivityResultsEqual(previousResults, nextResults);
}

bool shouldCheckIpAfterConnectivityChange({
  required List<ConnectivityResult>? previousResults,
  required List<ConnectivityResult> nextResults,
}) {
  final previousHasVpn =
      previousResults?.contains(ConnectivityResult.vpn) == true;
  final nextHasVpn = nextResults.contains(ConnectivityResult.vpn);
  return previousHasVpn != nextHasVpn;
}

class ConnectivityChangeGate {
  List<ConnectivityResult>? _lastHandledResults;

  List<ConnectivityResult>? handle(
    List<ConnectivityResult> results, {
    required AppLifecycleState? lifecycleState,
  }) {
    final nextResults = normalizeConnectivityResults(results);
    if (!shouldHandleConnectivityResults(
      previousResults: _lastHandledResults,
      nextResults: nextResults,
      lifecycleState: lifecycleState,
    )) {
      return null;
    }
    _lastHandledResults = nextResults;
    return nextResults;
  }
}
