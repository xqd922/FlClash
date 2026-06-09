const connectionsPollingInterval = Duration(seconds: 2);

bool shouldPollConnections({
  required bool isConnectionsCurrent,
  required bool isAppResumed,
}) {
  return isConnectionsCurrent && isAppResumed;
}
