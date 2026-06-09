bool shouldSampleSpeedTraffic({
  required bool isDashboardCurrent,
  required bool showTrayTitle,
}) {
  return isDashboardCurrent || showTrayTitle;
}
