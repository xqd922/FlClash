import 'package:fl_clash/application_auto_update.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile auto update scheduling', () {
    test('schedules only while there is an auto-updatable URL profile', () {
      expect(
        shouldScheduleProfileAutoUpdate(
          profiles: [_profile(url: 'https://example.com/config.yaml')],
          lifecycleState: AppLifecycleState.resumed,
        ),
        isTrue,
      );
      expect(
        shouldScheduleProfileAutoUpdate(
          profiles: [_profile(url: '')],
          lifecycleState: AppLifecycleState.resumed,
        ),
        isFalse,
      );
      expect(
        shouldScheduleProfileAutoUpdate(
          profiles: [
            _profile(url: 'https://example.com/config.yaml', autoUpdate: false),
          ],
          lifecycleState: AppLifecycleState.resumed,
        ),
        isFalse,
      );
    });

    test('does not schedule while the app is not in the foreground', () {
      final profiles = [_profile(url: 'https://example.com/config.yaml')];

      expect(
        shouldScheduleProfileAutoUpdate(
          profiles: profiles,
          lifecycleState: AppLifecycleState.inactive,
        ),
        isFalse,
      );
      expect(
        shouldScheduleProfileAutoUpdate(
          profiles: profiles,
          lifecycleState: AppLifecycleState.paused,
        ),
        isFalse,
      );
      expect(
        shouldScheduleProfileAutoUpdate(
          profiles: profiles,
          lifecycleState: AppLifecycleState.detached,
        ),
        isFalse,
      );
    });
  });
}

Profile _profile({required String url, bool autoUpdate = true}) {
  return Profile(
    id: 1,
    url: url,
    autoUpdate: autoUpdate,
    autoUpdateDuration: const Duration(hours: 1),
  );
}
