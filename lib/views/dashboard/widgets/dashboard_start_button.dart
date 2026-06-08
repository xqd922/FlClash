import 'package:flutter/material.dart';

import 'start_button.dart';
import 'start_button_width.dart';

class DashboardStartButton extends StatelessWidget {
  const DashboardStartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: startButtonMaxWidth,
      height: startButtonIconHeight,
      child: const Align(
        alignment: AlignmentDirectional.bottomEnd,
        child: StartButton(),
      ),
    );
  }
}
