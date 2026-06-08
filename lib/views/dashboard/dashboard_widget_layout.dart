import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/widgets/widgets.dart';

List<GridItem> dashboardWidgetsForPlatform(
  Iterable<DashboardWidget> widgets, {
  required SupportPlatform platform,
}) {
  return widgets
      .where((item) => item.platforms.contains(platform))
      .map((item) => item.widget)
      .toList();
}

List<GridItem> addableDashboardWidgets(
  List<GridItem> currentWidgets, {
  required SupportPlatform platform,
}) {
  return DashboardWidget.values
      .where(
        (item) =>
            !currentWidgets.contains(item.widget) &&
            item.platforms.contains(platform),
      )
      .map((item) => item.widget)
      .toList();
}

bool isSameGridItemList(List<GridItem> previous, List<GridItem> next) {
  if (identical(previous, next)) {
    return true;
  }
  if (previous.length != next.length) {
    return false;
  }
  for (var index = 0; index < previous.length; index++) {
    if (!identical(previous[index], next[index])) {
      return false;
    }
  }
  return true;
}
