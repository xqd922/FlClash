import 'package:fl_clash/common/common.dart';
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

  String? tooltipOf(WidgetTester tester) {
    return tester
        .widget<FloatingActionButton>(find.byType(FloatingActionButton))
        .tooltip;
  }

  testWidgets('starts the current group test while nothing is pending', (
    tester,
  ) async {
    var started = 0;
    await pumpButton(tester, () async {
      started++;
    });

    expect(find.byIcon(Icons.network_ping), findsOneWidget);
    expect(tooltipOf(tester), currentAppLocalizations.delayTest);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(started, 1);
  });

  testWidgets('turns into stop and cancels pending tests', (tester) async {
    var started = 0;
    await pumpButton(tester, () async {
      started++;
    });
    container.read(pendingDelayTestsProvider.notifier).acquire(const ['key']);
    await tester.pump();

    expect(find.byIcon(Icons.stop), findsOneWidget);
    expect(tooltipOf(tester), currentAppLocalizations.stopDelayTest);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(started, 0);
    expect(container.read(pendingDelayTestsProvider), isEmpty);
    expect(find.byIcon(Icons.network_ping), findsOneWidget);
  });
}
