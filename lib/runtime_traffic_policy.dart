bool shouldSampleSpeedTraffic({
  required bool isDashboardCurrent,
  required bool showTrayTitle,
}) {
  return isDashboardCurrent || showTrayTitle;
}

bool shouldSampleTotalTraffic({required bool isDashboardCurrent}) {
  return isDashboardCurrent;
}
