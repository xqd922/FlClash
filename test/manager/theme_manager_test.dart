import 'package:fl_clash/manager/theme_manager.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ThemeManager updates view size without AppController attach', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [viewSizeProvider.overrideWithBuild((_, _) => Size.zero)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ThemeManager(child: SizedBox.expand())),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(container.read(viewSizeProvider), const Size(800, 600));
  });
}
