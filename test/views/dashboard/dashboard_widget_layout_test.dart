import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/views/dashboard/dashboard_widget_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dashboard widget layout', () {
    test('filters widgets by platform', () {
      final widgets = [
        DashboardWidget.networkSpeed,
        DashboardWidget.vpnButton,
        DashboardWidget.tunButton,
      ];

      expect(
        dashboardWidgetsForPlatform(widgets, platform: SupportPlatform.Android),
        [DashboardWidget.networkSpeed.widget, DashboardWidget.vpnButton.widget],
      );
      expect(
        dashboardWidgetsForPlatform(widgets, platform: SupportPlatform.Windows),
        [DashboardWidget.networkSpeed.widget, DashboardWidget.tunButton.widget],
      );
    });

    test('finds addable widgets without rebuilding unchanged lists', () {
      final visibleWidgets = dashboardWidgetsForPlatform([
        DashboardWidget.networkSpeed,
        DashboardWidget.vpnButton,
      ], platform: SupportPlatform.Android);

      final addableWidgets = addableDashboardWidgets(
        visibleWidgets,
        platform: SupportPlatform.Android,
      );

      expect(
        addableWidgets,
        isNot(contains(DashboardWidget.networkSpeed.widget)),
      );
      expect(addableWidgets, isNot(contains(DashboardWidget.vpnButton.widget)));
      expect(addableWidgets, contains(DashboardWidget.memoryInfo.widget));
    });

    test('detects unchanged grid item lists by identity and order', () {
      final items = [
        DashboardWidget.networkSpeed.widget,
        DashboardWidget.memoryInfo.widget,
      ];

      expect(isSameGridItemList(items, List.of(items)), isTrue);
      expect(
        isSameGridItemList(items, [
          DashboardWidget.memoryInfo.widget,
          DashboardWidget.networkSpeed.widget,
        ]),
        isFalse,
      );
      expect(
        isSameGridItemList(items, [DashboardWidget.networkSpeed.widget]),
        isFalse,
      );
    });
  });
}
