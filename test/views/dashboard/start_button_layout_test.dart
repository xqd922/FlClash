import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/database.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/dashboard.dart';
import 'package:fl_clash/views/dashboard/widgets/start_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _oneHourRuntime = 60 * 60 * 1000;

void main() {
  testWidgets('Start button stays compact when stopped', (tester) async {
    await pumpStartButton(tester, runTime: null);

    expectStartButtonSize(tester, maxWidth: 72, maxHeight: 72);
  });

  testWidgets('Start button stays compact when running', (tester) async {
    await pumpStartButton(tester, runTime: _oneHourRuntime);

    expectStartButtonSize(tester, maxWidth: 200, maxHeight: 72);
  });

  testWidgets('Start button does not overflow when runtime text changes', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        profilesProvider.overrideWithValue([
          const Profile(
            id: 1,
            label: 'test',
            autoUpdateDuration: Duration.zero,
          ),
        ]),
      ],
    );
    addTearDown(container.dispose);

    await pumpMutableStartButton(tester, container);

    container.read(runTimeProvider.notifier).value = 1000;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final initialWidth = tester
        .getSize(find.byType(FloatingActionButton))
        .width;

    container.read(runTimeProvider.notifier).value = _oneHourRuntime;
    await tester.pump();
    await tester.pump();

    final updatedWidth = tester
        .getSize(find.byType(FloatingActionButton))
        .width;
    expect(tester.takeException(), isNull);
    expect(updatedWidth, greaterThanOrEqualTo(initialWidth));
    expect(updatedWidth, lessThanOrEqualTo(200));
  });

  testWidgets('Start button root stays compact in the scaffold FAB slot', (
    tester,
  ) async {
    await pumpStartButton(tester, runTime: _oneHourRuntime);

    final rootSize = tester.getSize(find.byType(StartButton));

    expect(rootSize.width, lessThanOrEqualTo(200));
    expect(rootSize.height, 56);
  });

  testWidgets('Start button collapses when there is no profile', (
    tester,
  ) async {
    await pumpStartButton(tester, runTime: null, hasProfile: false);

    final rootSize = tester.getSize(find.byType(StartButton));

    expect(rootSize, Size.zero);
  });

  testWidgets('Start button height remains bounded in tall constraints', (
    tester,
  ) async {
    await pumpStartButton(
      tester,
      runTime: _oneHourRuntime,
      constrainFabHeight: 640,
    );

    final buttonSize = tester.getSize(find.byType(FloatingActionButton));

    expect(buttonSize.height, 56);
  });

  testWidgets(
    'Start button visual size stays bounded in oversized constraints',
    (tester) async {
      await pumpStartButton(
        tester,
        runTime: _oneHourRuntime,
        constrainFabWidth: 390,
        constrainFabHeight: 640,
      );

      final buttonSize = tester.getSize(find.byType(FloatingActionButton));

      expect(buttonSize.width, lessThanOrEqualTo(200));
      expect(buttonSize.height, 56);
    },
  );

  testWidgets('Dashboard keeps start button compact', (tester) async {
    await pumpDashboard(tester, runTime: _oneHourRuntime);

    expectStartButtonSize(tester, maxWidth: 200, maxHeight: 72);
  });

  testWidgets('Dashboard start button root shrinks when stopped', (
    tester,
  ) async {
    await pumpDashboard(tester, runTime: null);

    final rootSize = tester.getSize(find.byType(StartButton));

    expect(rootSize.width, lessThanOrEqualTo(72));
    expect(rootSize.height, 56);
  });

  testWidgets('Dashboard start button root follows running width', (
    tester,
  ) async {
    await pumpDashboard(tester, runTime: _oneHourRuntime);

    final rootSize = tester.getSize(find.byType(StartButton));

    expect(rootSize.width, lessThanOrEqualTo(200));
    expect(rootSize.height, 56);
  });

  testWidgets('Dashboard FAB transition slot stays compact', (tester) async {
    await pumpDashboard(tester, runTime: _oneHourRuntime);

    final fabSlot = find
        .ancestor(of: find.byType(StartButton), matching: find.byType(Stack))
        .last;
    final fabSlotSize = tester.getSize(fabSlot);

    expect(fabSlotSize.width, lessThanOrEqualTo(200));
    expect(fabSlotSize.height, 56);
  });

  testWidgets('Dashboard core status action stays compact', (tester) async {
    for (final coreStatus in CoreStatus.values) {
      await pumpDashboard(
        tester,
        runTime: _oneHourRuntime,
        coreStatus: coreStatus,
      );

      final actionFinder = coreStatus == CoreStatus.connected
          ? find.bySubtype<IconButton>()
          : find.bySubtype<FilledButton>();
      final statusButtonSize = tester.getSize(actionFinder.first);

      expect(statusButtonSize.width, lessThanOrEqualTo(180));
      expect(statusButtonSize.height, lessThanOrEqualTo(48));
    }
  });
}

Future<void> pumpStartButton(
  WidgetTester tester, {
  required int? runTime,
  bool hasProfile = true,
  double? constrainFabWidth,
  double? constrainFabHeight,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profilesProvider.overrideWithValue(
          hasProfile
              ? [
                  const Profile(
                    id: 1,
                    label: 'test',
                    autoUpdateDuration: Duration.zero,
                  ),
                ]
              : [],
        ),
        runTimeProvider.overrideWithValue(runTime),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: const SizedBox.expand(),
          floatingActionButton:
              constrainFabWidth == null && constrainFabHeight == null
              ? const StartButton()
              : SizedBox(
                  width: constrainFabWidth,
                  height: constrainFabHeight,
                  child: const StartButton(),
                ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> pumpMutableStartButton(
  WidgetTester tester,
  ProviderContainer container,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(),
          floatingActionButton: StartButton(),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> pumpDashboard(
  WidgetTester tester, {
  required int? runTime,
  CoreStatus coreStatus = CoreStatus.disconnected,
}) async {
  await AppLocalizations.load(const Locale('en'));
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profilesProvider.overrideWithValue([
          const Profile(
            id: 1,
            label: 'test',
            autoUpdateDuration: Duration.zero,
          ),
        ]),
        appSettingProvider.overrideWithValue(
          const AppSettingProps(dashboardWidgets: []),
        ),
        runTimeProvider.overrideWithValue(runTime),
        coreStatusProvider.overrideWithValue(coreStatus),
        viewSizeProvider.overrideWithValue(const Size(390, 844)),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        home: _MeasureHost(child: DashboardView()),
      ),
    ),
  );
  await tester.pump();
}

class _MeasureHost extends StatelessWidget {
  const _MeasureHost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    globalState.measure = Measure.of(context, defaultTextScaleFactor);
    return child;
  }
}

void expectStartButtonSize(
  WidgetTester tester, {
  required double maxWidth,
  required double maxHeight,
}) {
  final buttonSize = tester.getSize(find.byType(FloatingActionButton));

  expect(buttonSize.width, lessThanOrEqualTo(maxWidth));
  expect(buttonSize.height, lessThanOrEqualTo(maxHeight));
}
