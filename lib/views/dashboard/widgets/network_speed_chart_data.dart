import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/widgets/widgets.dart';

const networkSpeedBaselinePoints = [Point(0, 0), Point(1, 0)];

class NetworkSpeedViewData {
  const NetworkSpeedViewData({
    required this.currentSpeedText,
    required this.points,
  });

  final String currentSpeedText;
  final List<Point> points;
}

NetworkSpeedViewData buildNetworkSpeedViewData(List<Traffic> traffics) {
  final currentTraffic = lastNetworkSpeedTraffic(traffics);
  return NetworkSpeedViewData(
    currentSpeedText: currentTraffic.speedText,
    points: buildNetworkSpeedPoints(traffics),
  );
}

List<Point> buildNetworkSpeedPoints(List<Traffic> traffics) {
  final points = List<Point>.filled(
    networkSpeedBaselinePoints.length + traffics.length,
    const Point(0, 0),
    growable: false,
  );
  for (var i = 0; i < networkSpeedBaselinePoints.length; i++) {
    points[i] = networkSpeedBaselinePoints[i];
  }
  for (var i = 0; i < traffics.length; i++) {
    points[i + networkSpeedBaselinePoints.length] = Point(
      (i + networkSpeedBaselinePoints.length).toDouble(),
      traffics[i].speed.toDouble(),
    );
  }
  return points;
}

Traffic lastNetworkSpeedTraffic(List<Traffic> traffics) {
  if (traffics.isEmpty) return Traffic();
  return traffics.last;
}
