import 'package:fl_clash/common/task.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  Future<YamlMap> buildProfile({
    Map<String, dynamic> rawConfig = const {},
    PatchClashConfig patchConfig = defaultClashConfig,
    bool overrideDns = false,
    List<ProxyGroup> proxyGroups = const [],
    List<Rule> rules = const [],
  }) async {
    final profile = await makeRealProfileTask(
      MakeRealProfileState(
        profilesPath: '',
        profileId: 1,
        rawConfig: rawConfig,
        realPatchConfig: patchConfig,
        overrideDns: overrideDns,
        appendSystemDns: false,
        proxyGroups: proxyGroups,
        rules: rules,
        addedRules: [],
        defaultUA: 'xclash-test',
      ),
    );
    return loadYaml(profile.a) as YamlMap;
  }

  group('makeRealProfileTask external-controller', () {
    Future<YamlMap> buildExternalControllerProfile(
      ExternalControllerStatus status, {
      Object? externalController,
    }) {
      return buildProfile(
        rawConfig: {
          if (externalController != null)
            'external-controller': externalController,
        },
        patchConfig: defaultClashConfig.copyWith(externalController: status),
      );
    }

    test('clears the controller when disabled', () async {
      final profile = await buildExternalControllerProfile(
        ExternalControllerStatus.close,
        externalController: '0.0.0.0:9090',
      );

      expect(profile['external-controller'], '');
    });

    test('keeps the profile controller when enabled', () async {
      final profile = await buildExternalControllerProfile(
        ExternalControllerStatus.open,
        externalController: '0.0.0.0:9090',
      );

      expect(profile['external-controller'], '0.0.0.0:9090');
    });

    test('uses the app default when the profile omits it', () async {
      final profile = await buildExternalControllerProfile(
        ExternalControllerStatus.open,
      );

      expect(profile['external-controller'], '127.0.0.1:9090');
    });
  });

  group('makeRealProfileTask merge semantics', () {
    test('keeps explicit profile and nested tun values', () async {
      final profile = await buildProfile(
        rawConfig: {
          'mixed-port': 1080,
          'allow-lan': false,
          'ipv6': false,
          'unified-delay': true,
          'tun': {'enable': true, 'stack': 'system'},
        },
      );

      expect(profile['mixed-port'], 1080);
      expect(profile['allow-lan'], false);
      expect(profile['ipv6'], false);
      expect(profile['unified-delay'], true);
      expect(profile['tun']['enable'], true);
      expect(profile['tun']['stack'], 'system');
    });

    test('respects non-empty profile DNS', () async {
      final profile = await buildProfile(
        rawConfig: {
          'dns': {
            'nameserver': ['1.1.1.1'],
          },
        },
      );

      expect(profile['dns']['enable'], true);
      expect(profile['dns']['nameserver'], ['1.1.1.1']);
    });

    test('custom overwrite rules and groups remain explicit', () async {
      final profile = await buildProfile(
        rawConfig: {
          'rules': ['MATCH,DIRECT'],
          'proxy-groups': [
            {'name': 'profile-group', 'type': 'select'},
          ],
        },
        rules: [Rule.parse('DOMAIN,example.com,DIRECT')],
        proxyGroups: const [
          ProxyGroup(id: 1, name: 'custom-group', type: GroupType.Selector),
        ],
      );

      expect(profile['rules'], ['DOMAIN,example.com,DIRECT']);
      expect(profile['proxy-groups'].single['name'], 'custom-group');
    });

    test('removes only null values and keeps stable top-level order', () async {
      final profile = await buildProfile(
        rawConfig: {
          'unknown': '',
          'dns': {
            'nameserver': ['1.1.1.1', null, ''],
            'nullable': null,
          },
          'allow-lan': null,
        },
      );

      expect(profile['allow-lan'], defaultClashConfig.allowLan);
      expect(profile['dns'].containsKey('nullable'), false);
      expect(profile['dns']['nameserver'], ['1.1.1.1', null, '']);
      expect(profile['unknown'], '');
      expect(
        profile.keys.toList().indexOf('allow-lan'),
        lessThan(profile.keys.toList().indexOf('dns')),
      );
      expect(
        profile.keys.toList().indexOf('unknown'),
        greaterThan(profile.keys.toList().indexOf('rules')),
      );
    });
  });
}
