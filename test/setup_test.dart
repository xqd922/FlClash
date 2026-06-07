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
  });
}
