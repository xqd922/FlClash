import 'package:fl_clash/deferred_value_updater.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef SystemUiOverlayStyleReader = SystemUiOverlayStyle Function();
typedef SystemUiOverlayStyleWriter = void Function(SystemUiOverlayStyle value);
typedef SystemUiOverlayStyleScheduler = void Function(void Function() callback);

class SystemUiOverlayStyleUpdater {
  SystemUiOverlayStyleUpdater({
    required SystemUiOverlayStyleReader read,
    required SystemUiOverlayStyleWriter write,
    required SystemUiOverlayStyleScheduler schedule,
  }) : _updater = DeferredValueUpdater<SystemUiOverlayStyle>(
         read: read,
         write: write,
         schedule: schedule,
       );

  final DeferredValueUpdater<SystemUiOverlayStyle> _updater;

  void update(SystemUiOverlayStyle value) {
    _updater.update(value);
  }
}

SystemUiOverlayStyle buildAndroidSystemUiOverlayStyle({
  required Brightness brightness,
  required Color surface,
}) {
  final iconBrightness = brightness == Brightness.light
      ? Brightness.dark
      : Brightness.light;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: iconBrightness,
    systemNavigationBarIconBrightness: iconBrightness,
    systemNavigationBarColor: surface,
    systemNavigationBarDividerColor: Colors.transparent,
  );
}
