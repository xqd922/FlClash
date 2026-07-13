import 'package:fl_clash/common/task.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('makeRealProfileTask external-controller', () {
    Future<VM2<String, String>> buildProfile(
      ExternalControllerStatus status, {
      Object? externalController,
    }) {
      return makeRealProfileTask(
        MakeRealProfileState(
          profilesPath: '',
          profileId: 1,
          rawConfig: {
            if (externalController != null)
              'external-controller': externalController,
          },
          realPatchConfig: defaultClashConfig.copyWith(
            externalController: status,
          ),
          overrideDns: false,
          appendSystemDns: false,
          proxyGroups: [],
          rules: [],
          addedRules: [],
          defaultUA: 'xclash-test',
        ),
      );
    }

    test('clears the controller when disabled', () async {
      final profile = await buildProfile(
        ExternalControllerStatus.close,
        externalController: '0.0.0.0:9090',
      );

      expect(loadYaml(profile.a)['external-controller'], '');
    });

    test('keeps the profile controller when enabled', () async {
      final profile = await buildProfile(
        ExternalControllerStatus.open,
        externalController: '0.0.0.0:9090',
      );

      expect(loadYaml(profile.a)['external-controller'], '0.0.0.0:9090');
    });

    test('uses the app default when the profile omits it', () async {
      final profile = await buildProfile(ExternalControllerStatus.open);

      expect(loadYaml(profile.a)['external-controller'], '127.0.0.1:9090');
    });
  });
}
