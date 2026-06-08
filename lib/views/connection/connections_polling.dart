const connectionsPollingInterval = Duration(seconds: 2);

bool shouldPollConnections({required bool isConnectionsCurrent}) {
  return isConnectionsCurrent;
}
