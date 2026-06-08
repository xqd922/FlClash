import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/connection/connections.dart';
import 'package:fl_clash/views/connection/item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ConnectionsList renders separators without prebuilding rows', (
    tester,
  ) async {
    await AppLocalizations.load(const Locale('en'));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: _MeasureHost(
            child: SizedBox(
              width: 390,
              height: 640,
              child: ConnectionsList(
                connections: [_trackerInfo('first'), _trackerInfo('second')],
                onClickKeyword: (_) {},
                onBlockConnection: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(TrackerInfoItem), findsNWidgets(2));
    expect(find.byType(Divider), findsOneWidget);
  });
}

TrackerInfo _trackerInfo(String id) {
  return TrackerInfo(
    id: id,
    start: DateTime(2026, 1, 1),
    metadata: const Metadata(
      network: 'tcp',
      host: 'example.com',
      destinationIP: '93.184.216.34',
      destinationPort: '443',
    ),
    chains: const ['DIRECT'],
    rule: 'MATCH',
    rulePayload: '',
  );
}

class _MeasureHost extends StatelessWidget {
  const _MeasureHost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    globalState.measure = Measure.of(context, defaultTextScaleFactor);
    return Scaffold(body: child);
  }
}
