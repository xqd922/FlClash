import 'dart:convert';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('regular update config payload omits external-controller', () {
    final updateParams = UpdateParams(
      tun: defaultTun,
      mixedPort: defaultMixedPort,
      allowLan: true,
      findProcessMode: FindProcessMode.always,
      mode: Mode.rule,
      logLevel: LogLevel.error,
      ipv6: true,
      tcpConcurrent: true,
      externalController: ExternalControllerStatus.close,
      unifiedDelay: false,
    );

    final payload = updateConfigPayload(updateParams);
    final jsonPayload = json.encode(payload);

    expect(jsonPayload.contains(externalControllerKey), isFalse);
  });
}
