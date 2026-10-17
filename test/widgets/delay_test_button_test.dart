import 'dart:async';

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

  double opacityOf(WidgetTester tester) {
    return tester
        .widget<FadeTransition>(
          find.descendant(
            of: find.byType(DelayTestButton),
            matching: find.byType(FadeTransition),
          ),
        )
        .opacity
        .value;
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

  testWidgets('keeps the standard fab size without a label', (tester) async {
    await pumpButton(tester, () async {});

    expect(
      tester.getSize(find.byType(FloatingActionButton)),
      const Size.square(56),
    );
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

  testWidgets('fades out and straight back while the test keeps running', (
    tester,
  ) async {
    final completer = Completer<void>();
    await pumpButton(tester, () => completer.future);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(opacityOf(tester), 0);

    await tester.pumpAndSettle();

    expect(opacityOf(tester), 1);
    expect(completer.isCompleted, isFalse);

    completer.complete();
  });

  testWidgets('a tap during the pulse restarts it from where it is', (
    tester,
  ) async {
    final first = Completer<void>();
    final second = Completer<void>();
    var started = 0;
    await pumpButton(tester, () {
      started++;
      return started == 1 ? first.future : second.future;
    });

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final halfway = opacityOf(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(started, 2);
    expect(opacityOf(tester), halfway);

    await tester.pumpAndSettle();

    expect(opacityOf(tester), 1);
    expect(first.isCompleted, isFalse);
    expect(second.isCompleted, isFalse);

    first.complete();
    second.complete();
  });
}
