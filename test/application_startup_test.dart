import 'package:fl_clash/application_startup.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Application startup attach policy', () {
    test('waits when navigator context is not ready', () {
      expect(startupAttachStatus(null), StartupAttachStatus.waitForNavigator);
    });

    testWidgets('attaches when navigator context is ready', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(key: ValueKey('navigator-context')),
        ),
      );

      final context = tester.element(
        find.byKey(const ValueKey('navigator-context')),
      );

      expect(startupAttachStatus(context), StartupAttachStatus.ready);
    });
  });
}
