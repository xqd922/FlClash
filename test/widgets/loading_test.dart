import 'package:fl_clash/widgets/loading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('CommonCircleLoading defaults to a 48 square', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: CommonCircleLoading())),
    );

    expect(
      tester.getSize(find.byType(CommonCircleLoading)),
      const Size.square(48),
    );
  });

  testWidgets('CommonCircleLoading shrink-wraps to the shortest constraint', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100, maxHeight: 32),
            child: const CommonCircleLoading(),
          ),
        ),
      ),
    );

    final customPaint = find.descendant(
      of: find.byType(CommonCircleLoading),
      matching: find.byType(CustomPaint),
    );

    expect(tester.getSize(customPaint), const Size.square(32));
  });

  testWidgets('CommonCircleLoading keeps rotating and morphing points', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: CommonCircleLoading())),
    );

    final loading = find.byType(CommonCircleLoading);
    final transform = find.descendant(
      of: loading,
      matching: find.byType(Transform),
    );
    final customPaint = find.descendant(
      of: loading,
      matching: find.byType(CustomPaint),
    );
    final initialTransform = tester.widget<Transform>(transform).transform;
    final initialPainter = tester.widget<CustomPaint>(customPaint).painter!;

    await tester.pump(const Duration(milliseconds: 300));

    final animatedTransform = tester.widget<Transform>(transform).transform;
    final animatedPainter = tester.widget<CustomPaint>(customPaint).painter!;

    expect(animatedTransform.storage, isNot(equals(initialTransform.storage)));
    expect(animatedPainter.shouldRepaint(initialPainter), isTrue);

    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(tester.takeException(), isNull);
  });
}
