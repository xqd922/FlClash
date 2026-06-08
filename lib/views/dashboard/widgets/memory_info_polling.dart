const memoryInfoPollingInterval = Duration(seconds: 5);

bool shouldPollMemoryInfo({required bool isDashboardCurrent}) {
  return isDashboardCurrent;
}
