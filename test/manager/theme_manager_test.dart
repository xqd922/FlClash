import 'package:fl_clash/manager/theme_manager.dart';
import 'package:fl_clash/models/config.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TextScaler> pumpThemeManager(
    WidgetTester tester,
    TextScaler systemTextScaler, {
    bool enableTextScale = false,
  }) async {
    late TextScaler textScaler;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (enableTextScale)
            themeSettingProvider.overrideWith(
              () => _EnabledTextScaleThemeSetting(),
            ),
        ],
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

  testWidgets('keeps the system text scaler by default', (tester) async {
    const systemTextScaler = TextScaler.linear(1.3);

    final textScaler = await pumpThemeManager(tester, systemTextScaler);

    expect(textScaler.scale(10), systemTextScaler.scale(10));
  });

  testWidgets('uses the configured scale when text scaling is enabled', (
    tester,
  ) async {
    final textScaler = await pumpThemeManager(
      tester,
      const TextScaler.linear(1.3),
      enableTextScale: true,
    );

    expect(textScaler.scale(10), 12);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _EnabledTextScaleThemeSetting extends ThemeSetting {
  @override
  ThemeProps build() =>
      const ThemeProps(textScale: TextScale(enable: true, scale: 1.2));
}
