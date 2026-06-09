bool shouldUpdateLogsView({
  required bool isLogsCurrent,
  required bool isAppResumed,
}) {
  return isLogsCurrent && isAppResumed;
}
