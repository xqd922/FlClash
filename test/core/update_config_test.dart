import 'dart:convert';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('update config payload does not contain external-controller', () {
    final updateParams = UpdateParams(
      tun: defaultTun,
      mixedPort: defaultMixedPort,
      allowLan: true,
      findProcessMode: FindProcessMode.always,
      mode: Mode.rule,
      logLevel: LogLevel.error,
      ipv6: true,
      tcpConcurrent: true,
      unifiedDelay: false,
    );

    final jsonPayload = json.encode(updateParams);

    expect(jsonPayload.contains(externalControllerKey), isFalse);
  });
}
