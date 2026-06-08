import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/database.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/dashboard/widgets/start_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Start button stays compact when stopped', (tester) async {
    await pumpStartButton(tester, runTime: null);

    expectStartButtonSize(tester, maxWidth: 72, maxHeight: 72);
  });

  testWidgets('Start button stays compact when running', (tester) async {
    await pumpStartButton(tester, runTime: 60 * 60);

    expectStartButtonSize(tester, maxWidth: 160, maxHeight: 72);
  });

  testWidgets('Start button height remains bounded in tall constraints', (
    tester,
  ) async {
    await pumpStartButton(tester, runTime: 60 * 60, constrainFabHeight: 640);

    final buttonSize = tester.getSize(find.byType(FloatingActionButton));

    expect(buttonSize.height, 56);
  });
}

Future<void> pumpStartButton(
  WidgetTester tester, {
  required int? runTime,
  double? constrainFabHeight,
}) async {
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
        runTimeProvider.overrideWithValue(runTime),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: const SizedBox.expand(),
          floatingActionButton: constrainFabHeight == null
              ? const StartButton()
              : SizedBox(
                  height: constrainFabHeight,
                  child: const StartButton(),
                ),
        ),
      ),
    ),
  );
  await tester.pump();
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
