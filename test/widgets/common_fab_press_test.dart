import 'dart:ui';

import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a touch press highlights the fab before the pointer lifts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: CommonFloatingActionButton(
            onPressed: () {},
            icon: const Icon(Icons.add),
            tooltip: 'add',
          ),
        ),
      ),
    );
    await tester.pump();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FloatingActionButton)),
      kind: PointerDeviceKind.touch,
    );
    await tester.pump(const Duration(milliseconds: 16));

    final material = Material.of(tester.element(find.byIcon(Icons.add)));
    expect((material as dynamic).debugInkFeatures as List, isNotEmpty);

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
