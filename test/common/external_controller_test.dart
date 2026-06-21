import 'package:fl_clash/common/external_controller.dart';
import 'package:fl_clash/common/task.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveExternalController', () {
    test('clears config value while the proxy runtime is stopped', () {
      final value = resolveExternalController(
        '127.0.0.1:9090',
        enableExternalController: false,
      );

      expect(value, '');
    });

    test('keeps config value while the proxy runtime is started', () {
      final value = resolveExternalController(
        '127.0.0.1:9090',
        enableExternalController: true,
      );

      expect(value, '127.0.0.1:9090');
    });

    test('does not invent a controller when config omits it', () {
      final value = resolveExternalController(
        null,
        enableExternalController: true,
      );

      expect(value, '');
    });
  });

  group('makeRealProfileTask', () {
    test('writes empty external-controller while the proxy runtime is stopped', () async {
      final profile = await makeRealProfileTask(
        MakeRealProfileState(
          profilesPath: '',
          profileId: 1,
          rawConfig: {
            externalControllerKey: '127.0.0.1:9090',
          },
          realPatchConfig: defaultClashConfig.copyWith(
            externalController: ExternalControllerStatus.close,
          ),
          overrideDns: false,
          appendSystemDns: false,
          addedRules: [],
          defaultUA: 'fl-clash-test',
        ),
      );

      expect(profile[externalControllerKey], '');
    });

    test('keeps config external-controller while the proxy runtime is started', () async {
      final profile = await makeRealProfileTask(
        MakeRealProfileState(
          profilesPath: '',
          profileId: 1,
          rawConfig: {
            externalControllerKey: '127.0.0.1:9090',
          },
          realPatchConfig: defaultClashConfig.copyWith(
            externalController: ExternalControllerStatus.open,
          ),
          overrideDns: false,
          appendSystemDns: false,
          addedRules: [],
          defaultUA: 'fl-clash-test',
        ),
      );

      expect(profile[externalControllerKey], '127.0.0.1:9090');
    });
  });
}
