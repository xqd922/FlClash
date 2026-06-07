import 'package:flutter_test/flutter_test.dart';

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
  });
}
