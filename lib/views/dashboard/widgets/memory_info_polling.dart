const memoryInfoPollingInterval = Duration(seconds: 5);

bool shouldPollMemoryInfo({
  required bool isDashboardCurrent,
  required bool isAppResumed,
}) {
  return isDashboardCurrent && isAppResumed;
}
