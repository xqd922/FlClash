import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/state.dart';

class ThemeManager extends ConsumerWidget {
  final Widget child;

  const ThemeManager({super.key, required this.child});

  Widget _buildSystemUi(Widget child) {
    if (!system.isAndroid) {
      return child;
    }
    return Consumer(
      builder: (context, ref, _) {
        final brightness = ref.watch(currentBrightnessProvider);
        final iconBrightness = brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: iconBrightness,
            systemNavigationBarIconBrightness: iconBrightness,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
          ),
          sized: false,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, ref) {
    globalState.measure = Measure.of(context, MediaQuery.textScalerOf(context));
    globalState.theme = CommonTheme.of(context, 1);
    final padding = MediaQuery.of(context).padding;
    final height = MediaQuery.of(context).size.height;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: padding.copyWith(
          top: padding.top > height * 0.3 ? 20.0 : padding.top,
        ),
      ),
      child: LayoutBuilder(
        builder: (_, constraints) {
          ref
              .read(themeActionProvider.notifier)
              .updateViewSize(
                Size(constraints.maxWidth, constraints.maxHeight),
              );
          return _buildSystemUi(child);
        },
      ),
    );
  }
}
