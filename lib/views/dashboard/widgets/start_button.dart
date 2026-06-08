import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/controller.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/database.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'start_button_width.dart';

class StartButton extends ConsumerStatefulWidget {
  const StartButton({super.key});

  @override
  ConsumerState<StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends ConsumerState<StartButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late Animation<double> _animation;
  bool isStart = false;

  @override
  void initState() {
    super.initState();
    isStart = ref.read(isStartProvider);
    _controller = AnimationController(
      vsync: this,
      value: isStart ? 1 : 0,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeOutBack,
    );
    ref.listenManual(isStartProvider, (prev, next) {
      if (next != isStart) {
        isStart = next;
        updateController();
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  void handleSwitchStart() {
    isStart = !isStart;
    updateController();
    debouncer.call(FunctionTag.updateStatus, () {
      appController.updateStatus(isStart, isInit: !ref.read(initProvider));
    }, duration: commonDuration);
  }

  void updateController() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isStart && mounted) {
        _controller?.forward();
      } else {
        _controller?.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasProfile = ref.watch(
      profilesProvider.select((state) => state.isNotEmpty),
    );
    if (!hasProfile) {
      return Container();
    }
    final theme = Theme.of(context);
    return RepaintBoundary(
      child: Theme(
        data: theme.copyWith(
          floatingActionButtonTheme: theme.floatingActionButtonTheme.copyWith(
            sizeConstraints: const BoxConstraints(minWidth: 56, maxWidth: 200),
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller!.view,
          builder: (_, child) {
            return FloatingActionButton(
              clipBehavior: Clip.antiAlias,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              heroTag: null,
              onPressed: () {
                handleSwitchStart();
              },
              child: SizedBox(
                height: startButtonIconHeight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: startButtonIconHeight,
                      padding: EdgeInsets.only(
                        left: startButtonIconLeftPadding,
                        right: startButtonExpandedIconRightPadding(
                          _animation.value,
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      child: AnimatedIcon(
                        icon: AnimatedIcons.play_pause,
                        progress: _animation,
                      ),
                    ),
                    _ExpandableStartButtonLabel(
                      progress: _animation.value,
                      child: child!,
                    ),
                  ],
                ),
              ),
            );
          },
          child: Consumer(
            builder: (_, ref, _) {
              final runTime = ref.watch(runTimeProvider);
              final text = utils.getTimeText(runTime);
              final style = theme.textTheme.titleMedium?.toSoftBold.copyWith(
                color: context.colorScheme.onPrimaryContainer,
              );
              final textWidth = estimatedStartButtonTextWidth(text);
              return _StartButtonLabel(
                text: text,
                width: textWidth,
                style: style,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ExpandableStartButtonLabel extends StatelessWidget {
  const _ExpandableStartButtonLabel({
    required this.progress,
    required this.child,
  });

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        widthFactor: progress,
        heightFactor: 1,
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }
}

class _StartButtonLabel extends StatelessWidget {
  const _StartButtonLabel({
    required this.text,
    required this.width,
    required this.style,
  });

  final String text;
  final double width;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.visible,
        style: style,
      ),
    );
  }
}
