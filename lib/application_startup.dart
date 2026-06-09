import 'package:flutter/widgets.dart';

const startupAttachRetryDelay = Duration(milliseconds: 16);

enum StartupAttachStatus { ready, waitForNavigator }

StartupAttachStatus startupAttachStatus(BuildContext? navigatorContext) {
  if (navigatorContext == null) {
    return StartupAttachStatus.waitForNavigator;
  }
  return StartupAttachStatus.ready;
}
