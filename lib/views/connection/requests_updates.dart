bool shouldUpdateRequestsView({
  required bool isRequestsCurrent,
  required bool isAppResumed,
}) {
  return isRequestsCurrent && isAppResumed;
}
