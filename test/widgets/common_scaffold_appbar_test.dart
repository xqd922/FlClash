import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('common scaffold app bar disables scrolled-under tint and elevation', () async {
    final source = await File('lib/widgets/scaffold.dart').readAsString();

    expect(source.contains('backgroundColor: colorScheme.surface'), isTrue);
    expect(source.contains('elevation: 0'), isTrue);
    expect(source.contains('scrolledUnderElevation: 0'), isTrue);
    expect(source.contains('shadowColor: Colors.transparent'), isTrue);
    expect(source.contains('surfaceTintColor: Colors.transparent'), isTrue);
  });
}
