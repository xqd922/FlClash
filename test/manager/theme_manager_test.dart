import 'package:fl_clash/manager/theme_manager.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TextScaler> pumpThemeManager(
    WidgetTester tester,
    TextScaler systemTextScaler,
  ) async {
    late TextScaler textScaler;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: systemTextScaler),
            child: ThemeManager(
              child: Builder(
                builder: (context) {
                  textScaler = MediaQuery.textScalerOf(context);
                  return child!;
                },
              ),
            ),
          ),
          home: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
    return textScaler;
  }

  testWidgets('keeps the system text scaler', (tester) async {
    const systemTextScaler = TextScaler.linear(1.3);

    final textScaler = await pumpThemeManager(tester, systemTextScaler);

    expect(textScaler.scale(10), systemTextScaler.scale(10));
  });
}
