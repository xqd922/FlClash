import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'start_button.dart';
import 'start_button_width.dart';

class DashboardStartButton extends ConsumerWidget {
  const DashboardStartButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runTime = ref.watch(runTimeProvider);
    final isStart = ref.watch(isStartProvider);
    final text = utils.getTimeText(runTime);
    final width = startButtonWidthForText(text, isStart ? 1 : 0);
    return SizedBox(
      width: width,
      height: startButtonIconHeight,
      child: const Align(
        alignment: AlignmentDirectional.bottomEnd,
        child: StartButton(),
      ),
    );
  }
}
