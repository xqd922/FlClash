import 'package:fl_clash/system_ui_overlay_style_updater.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('System UI overlay style updater', () {
    test('builds Android edge-to-edge style from brightness and surface', () {
      final style = buildAndroidSystemUiOverlayStyle(
        brightness: Brightness.light,
        surface: Colors.white,
      );

      expect(style.statusBarColor, Colors.transparent);
      expect(style.statusBarIconBrightness, Brightness.dark);
      expect(style.systemNavigationBarIconBrightness, Brightness.dark);
      expect(style.systemNavigationBarColor, Colors.white);
      expect(style.systemNavigationBarDividerColor, Colors.transparent);
    });

    test('coalesces repeated style writes into one scheduled update', () {
      var currentStyle = const SystemUiOverlayStyle();
      final scheduled = <void Function()>[];
      final writes = <SystemUiOverlayStyle>[];
      final updater = SystemUiOverlayStyleUpdater(
        read: () => currentStyle,
        write: (value) {
          currentStyle = value;
          writes.add(value);
        },
        schedule: scheduled.add,
      );
      final nextStyle = buildAndroidSystemUiOverlayStyle(
        brightness: Brightness.dark,
        surface: Colors.black,
      );

      updater.update(nextStyle);
      updater.update(nextStyle);

      expect(scheduled.length, 1);
      scheduled.single();
      expect(writes, [nextStyle]);
    });

    test('skips write when scheduled style becomes current before flush', () {
      var currentStyle = const SystemUiOverlayStyle();
      final scheduled = <void Function()>[];
      final writes = <SystemUiOverlayStyle>[];
      final updater = SystemUiOverlayStyleUpdater(
        read: () => currentStyle,
        write: writes.add,
        schedule: scheduled.add,
      );
      final nextStyle = buildAndroidSystemUiOverlayStyle(
        brightness: Brightness.light,
        surface: Colors.white,
      );

      updater.update(nextStyle);
      currentStyle = nextStyle;
      scheduled.single();

      expect(writes, isEmpty);
    });
  });
}
