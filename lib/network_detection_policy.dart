bool shouldStartNetworkDetection({
  required bool previousIsInitialized,
  required int previousCheckRequest,
  required bool nextIsInitialized,
  required int nextCheckRequest,
}) {
  if (!previousIsInitialized || !nextIsInitialized) {
    return false;
  }
  return nextCheckRequest != previousCheckRequest;
}
