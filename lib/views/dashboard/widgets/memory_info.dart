import 'dart:async';
import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'memory_info_polling.dart';

final _memoryStateNotifier = ValueNotifier<num>(0);

class MemoryInfo extends ConsumerStatefulWidget {
  const MemoryInfo({super.key});

  @override
  ConsumerState<MemoryInfo> createState() => _MemoryInfoState();
}

class _MemoryInfoState extends ConsumerState<MemoryInfo>
    with WidgetsBindingObserver {
  Timer? _timer;

  bool get _shouldPoll => shouldPollMemoryInfo(
    isDashboardCurrent: ref.read(isCurrentPageProvider(PageLabel.dashboard)),
    isAppResumed: _isAppResumed,
  );

  bool get _isAppResumed {
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    return lifecycleState == null ||
        lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(isCurrentPageProvider(PageLabel.dashboard), (
      previous,
      next,
    ) {
      if (next) {
        _updateMemory();
      } else {
        _cancelTimer();
      }
    }, fireImmediately: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_shouldPoll) {
        _updateMemory();
      }
      return;
    }
    _cancelTimer();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _scheduleNextUpdate() {
    _cancelTimer();
    if (!_shouldPoll) {
      return;
    }
    _timer = Timer(memoryInfoPollingInterval, _updateMemory);
  }

  Future<void> _readMemory() async {
    if (!_shouldPoll) {
      return;
    }
    final rss = ProcessInfo.currentRss;
    if (coreController.isCompleted) {
      _memoryStateNotifier.value = await coreController.getMemory() + rss;
    } else {
      _memoryStateNotifier.value = rss;
    }
  }

  void _updateMemory() {
    if (!_shouldPoll) {
      _cancelTimer();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await _readMemory();
      if (!mounted) {
        return;
      }
      _scheduleNextUpdate();
    });
  }

  @override
  void dispose() {
    _cancelTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        info: Info(iconData: Icons.memory, label: appLocalizations.memoryInfo),
        onPressed: () {
          coreController.requestGc();
        },
        child: Container(
          padding: baseInfoEdgeInsets.copyWith(top: 0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: globalState.measure.bodyMediumHeight + 2,
                child: ValueListenableBuilder(
                  valueListenable: _memoryStateNotifier,
                  builder: (_, memory, _) {
                    final traffic = memory.traffic;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          traffic.value,
                          style: context.textTheme.bodyMedium?.toLight
                              .adjustSize(1),
                        ),
                        SizedBox(width: 8),
                        Text(
                          traffic.unit,
                          style: context.textTheme.bodyMedium?.toLight
                              .adjustSize(1),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
