import 'package:build_tool/src/go_builder.dart';
import 'package:build_tool/src/target.dart';
import 'package:test/test.dart';

void main() {
  test('adds low-memory tag only for armeabi-v7a', () {
    const tags = 'with_gvisor,no_fake_tcp';

    expect(
      buildTagsForTarget(tags, Target.androidArm),
      '$tags,with_low_memory',
    );
    expect(buildTagsForTarget(tags, Target.androidArm64), tags);
  });

  test('adds 16KB page alignment only for Android 64-bit targets', () {
    const ldflags = '-w -s';

    expect(
      buildLdflagsForTarget(ldflags, Target.androidArm64),
      contains('max-page-size=16384'),
    );
    expect(buildLdflagsForTarget(ldflags, Target.androidArm), ldflags);
    expect(buildLdflagsForTarget(ldflags, Target.windowsAmd64), ldflags);
  });
}
