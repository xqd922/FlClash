import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';

bool shouldUpdateConnectionsList(
  List<TrackerInfo> current,
  List<TrackerInfo> next,
) {
  return !trackerInfoListEquality.equals(current, next);
}
