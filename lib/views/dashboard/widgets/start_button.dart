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
      return const SizedBox.shrink();
    }
    final runTime = ref.watch(runTimeProvider);
    final text = utils.getTimeText(runTime);
    final theme = Theme.of(context);
    final style = theme.textTheme.titleMedium?.toSoftBold.copyWith(
      color: context.colorScheme.onPrimaryContainer,
    );
    final textWidth = measuredStartButtonTextWidth(
      text,
      style: style,
      textScaler: MediaQuery.of(context).textScaler,
    );
    return Align(
      widthFactor: 1,
      heightFactor: 1,
      alignment: AlignmentDirectional.bottomEnd,
      child: RepaintBoundary(
        child: Theme(
          data: theme.copyWith(
            floatingActionButtonTheme: theme.floatingActionButtonTheme.copyWith(
              sizeConstraints: startButtonSizeConstraints,
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller!.view,
            builder: (_, child) {
              final iconRightPadding = startButtonExpandedIconRightPadding(
                _animation.value,
              );
              final iconWidth =
                  startButtonIconLeftPadding +
                  startButtonIconSize +
                  iconRightPadding;
              final width = startButtonWidthForMeasuredText(
                textWidth,
                _animation.value,
              );
              final labelWidth = width - iconWidth;
              return SizedBox(
                width: width,
                height: startButtonIconHeight,
                child: FloatingActionButton(
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
                        SizedBox(
                          width: iconWidth,
                          height: startButtonIconHeight,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: startButtonIconLeftPadding,
                              right: iconRightPadding,
                            ),
                            child: AnimatedIcon(
                              icon: AnimatedIcons.play_pause,
                              progress: _animation,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: labelWidth < 0 ? 0 : labelWidth,
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: child!,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            child: _StartButtonLabel(text: text, style: style),
          ),
        ),
      ),
    );
  }
}

class _StartButtonLabel extends StatelessWidget {
  const _StartButtonLabel({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text, maxLines: 1, style: style),
    );
  }
}
