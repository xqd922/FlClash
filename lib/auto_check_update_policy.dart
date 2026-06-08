import 'dart:async';

import 'package:flutter/widgets.dart';

const autoCheckUpdateStartupDelay = Duration(seconds: 30);

typedef AutoCheckUpdateScheduler =
    void Function(Duration delay, VoidCallback task);

void scheduleAutoCheckUpdate({
  required bool Function() isEnabled,
  required AppLifecycleState? Function() lifecycleState,
  required AutoCheckUpdateScheduler schedule,
  required Future<void> Function() checkForUpdate,
  required void Function(Object error, StackTrace stackTrace) onError,
}) {
  if (!isEnabled()) {
    return;
  }
  schedule(autoCheckUpdateStartupDelay, () {
    if (!isEnabled()) {
      return;
    }
    final state = lifecycleState();
    if (state != null && state != AppLifecycleState.resumed) {
      return;
    }
    unawaited(
      checkForUpdate().catchError((Object error, StackTrace stackTrace) {
        onError(error, stackTrace);
      }),
    );
  });
}
