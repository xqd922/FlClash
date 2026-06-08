import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

import '../setup.dart';

void main() {
  group('Build', () {
    test('builds the helper only for Windows targets', () {
      expect(Build.shouldBuildHelper(Target.windows), isTrue);
      expect(Build.shouldBuildHelper(Target.android), isFalse);
      expect(Build.shouldBuildHelper(Target.linux), isFalse);
      expect(Build.shouldBuildHelper(Target.macos), isFalse);
    });

    test('resolves android build targets by requested arch', () {
      expect(Build.androidBuildTargetPlatforms(null), [
        'android-arm',
        'android-arm64',
        'android-x64',
      ]);
      expect(Build.androidBuildTargetPlatforms(Arch.arm64), ['android-arm64']);
    });

    test('uses stable android apk names in dist', () {
      expect(
        Build.androidDistApkFileName(Arch.arm64, '7.0.20'),
        'FlClash-7.0.20-android-arm64-v8a.apk',
      );
      expect(
        Build.androidDistApkFileName(Arch.arm, '7.0.20'),
        'FlClash-7.0.20-android-armeabi-v7a.apk',
      );
    });

    test('keeps dart define env file outside the repository root', () {
      expect(
        Build.envFilePath,
        join(current, '.dart_tool', 'flclash', 'env.json'),
      );
    });

    test('uses generated dart define file for android apk builds', () {
      expect(Build.androidBuildApkArgs(Arch.arm64), [
        'flutter',
        'build',
        'apk',
        '--verbose',
        '--dart-define-from-file',
        Build.envFilePath,
        '--split-per-abi',
        '--target-platform',
        'android-arm64',
      ]);
    });

    test('uses generated dart define file for distributor package builds', () {
      expect(
        Build.distributorPackageArgs(
          target: Target.linux,
          targets: 'deb,appimage,rpm',
          description: 'amd64',
          buildTargetPlatform: 'linux-x64',
        ),
        [
          'flutter_distributor',
          'package',
          '--skip-clean',
          '--platform',
          'linux',
          '--targets',
          'deb,appimage,rpm',
          '--flutter-build-args',
          'verbose,dart-define-from-file=${Build.envFilePath}',
          '--description',
          'amd64',
          '--build-target-platform',
          'linux-x64',
        ],
      );
    });

    test('writes dart define env file with parent directories', () async {
      final tempDir = await Directory.systemTemp.createTemp('flclash-env-');
      addTearDown(() async {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });

      final envFile = File(join(tempDir.path, 'nested', 'env.json'));
      await Build.writeDartDefineEnvFile(
        'stable',
        coreSha256: 'core-sha',
        path: envFile.path,
      );

      expect(envFile.existsSync(), isTrue);
      expect(jsonDecode(await envFile.readAsString()), {
        'APP_ENV': 'stable',
        'CORE_SHA256': 'core-sha',
      });
    });

    test('extracts version name without build number', () {
      expect(
        Build.versionNameFromPubspec('name: fl_clash\nversion: 7.0.20+1\n'),
        '7.0.20',
      );
    });

    test('prepends a path entry without dropping existing environment', () {
      final environment = Build.prependPathEntry(
        {'Path': r'C:\tools', 'FOO': 'bar'},
        r'C:\Users\Seven\AppData\Local\Pub\Cache\bin',
        pathSeparator: ';',
      );

      expect(environment['FOO'], 'bar');
      expect(
        environment['Path'],
        r'C:\Users\Seven\AppData\Local\Pub\Cache\bin;C:\tools',
      );
    });

    test('copies files over existing dist artifacts', () async {
      final tempDir = await Directory.systemTemp.createTemp('flclash-setup-');
      addTearDown(() async {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });

      final source = File(join(tempDir.path, 'source.apk'));
      final target = File(join(tempDir.path, 'target.apk'));
      await source.writeAsString('new apk');
      await target.writeAsString('old apk');

      await Build.copyFileReplacing(source, target);

      expect(await target.readAsString(), 'new apk');
    });

    test('retries transient file operations', () async {
      var attempts = 0;

      await Build.retryFileOperation(() async {
        attempts += 1;
        if (attempts < 3) {
          throw const FileSystemException('locked');
        }
      }, retryDelay: Duration.zero);

      expect(attempts, 3);
    });
  });
}
