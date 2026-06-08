import 'package:fl_clash/models/models.dart';
import 'package:flutter/widgets.dart';

const profileAutoUpdateCheckInterval = Duration(minutes: 20);

bool shouldScheduleProfileAutoUpdate({
  required List<Profile> profiles,
  required AppLifecycleState? lifecycleState,
}) {
  final isForeground =
      lifecycleState == null || lifecycleState == AppLifecycleState.resumed;
  if (!isForeground) {
    return false;
  }
  return profiles.any((profile) => profile.realAutoUpdate);
}
