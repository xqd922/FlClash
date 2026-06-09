import 'package:flutter/widgets.dart';

bool isAppLifecycleResumed(AppLifecycleState? lifecycleState) {
  return lifecycleState == null || lifecycleState == AppLifecycleState.resumed;
}
