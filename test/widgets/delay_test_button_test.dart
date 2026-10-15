import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/views/proxies/tab.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  Future<void> pumpButton(
    WidgetTester tester,
    Future<void> Function() onClick,
  ) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.delegate.supportedLocales,
          home: Scaffold(
            floatingActionButton: DelayTestButton(onClick: onClick),
          ),
        ),
      ),
    );
  }

  testWidgets('runs the current group test', (tester) async {
    var started = 0;
    await pumpButton(tester, () async {
      started++;
    });

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(started, 1);
  });

  testWidgets('a tap while a test is pending drops it and starts over', (
    tester,
  ) async {
    var started = 0;
    await pumpButton(tester, () async {
      started++;
    });
    container.read(pendingDelayTestsProvider.notifier).acquire(const ['key']);
    await tester.pump();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(started, 1);
    expect(container.read(pendingDelayTestsProvider), isEmpty);
    expect(find.byIcon(Icons.network_ping), findsOneWidget);
  });
}
