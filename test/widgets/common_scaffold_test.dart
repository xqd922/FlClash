import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/widgets/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CommonScaffold disposes keyword notifier', (tester) async {
    await AppLocalizations.load(const Locale('en'));
    final scaffoldKey = GlobalKey<CommonScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: CommonScaffold(
          key: scaffoldKey,
          title: 'Test',
          body: const SizedBox.shrink(),
        ),
      ),
    );

    final scaffoldState = scaffoldKey.currentState!;
    scaffoldState.addKeyword('before-dispose');

    await tester.pumpWidget(const SizedBox.shrink());

    expect(
      () => scaffoldState.addKeyword('after-dispose'),
      throwsA(isA<FlutterError>()),
    );
  });
}
