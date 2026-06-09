import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/deferred_value_updater.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/system_ui_overlay_style_updater.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/state.dart';

class ThemeManager extends ConsumerStatefulWidget {
  final Widget child;

  const ThemeManager({super.key, required this.child});

  @override
  ConsumerState<ThemeManager> createState() => _ThemeManagerState();
}

class _ThemeManagerState extends ConsumerState<ThemeManager> {
  SystemUiOverlayStyleUpdater? _systemUiOverlayStyleUpdater;
  DeferredValueUpdater<Size>? _viewSizeUpdater;

  Widget _buildSystemUi(Widget child) {
    if (!system.isAndroid) {
      return child;
    }
    return AnnotatedRegion<SystemUiMode>(
      sized: false,
      value: SystemUiMode.edgeToEdge,
      child: Consumer(
        builder: (context, ref, _) {
          final brightness = ref.watch(currentBrightnessProvider);
          final style = buildAndroidSystemUiOverlayStyle(
            brightness: brightness,
            surface: context.colorScheme.surface,
          );
          _updateSystemUiOverlayStyle(style);
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: style,
            sized: false,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    globalState.measure = Measure.of(context, defaultTextScaleFactor);
    final padding = MediaQuery.of(context).padding;
    final height = MediaQuery.of(context).size.height;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: padding.copyWith(
          top: padding.top > height * 0.3 ? 20.0 : padding.top,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          floatingActionButtonTheme: Theme.of(context).floatingActionButtonTheme
              .copyWith(
                shape: const RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16.0)),
                ),
              ),
        ),
        child: LayoutBuilder(
          builder: (_, container) {
            _updateViewSize(Size(container.maxWidth, container.maxHeight));
            return _buildSystemUi(widget.child);
          },
        ),
      ),
    );
  }

  void _updateSystemUiOverlayStyle(SystemUiOverlayStyle style) {
    final updater = _systemUiOverlayStyleUpdater ??=
        SystemUiOverlayStyleUpdater(
          read: () => ref.read(systemUiOverlayStyleStateProvider),
          write: (value) {
            ref.read(systemUiOverlayStyleStateProvider.notifier).value = value;
          },
          schedule: (callback) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                callback();
              }
            });
          },
        );
    updater.update(style);
  }

  void _updateViewSize(Size size) {
    final updater = _viewSizeUpdater ??= DeferredValueUpdater<Size>(
      read: () => ref.read(viewSizeProvider),
      write: (value) {
        ref.read(viewSizeProvider.notifier).value = value;
      },
      schedule: (callback) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            callback();
          }
        });
      },
    );
    updater.update(size);
  }
}
