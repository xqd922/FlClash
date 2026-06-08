bool shouldRefreshGroupsAfterCoreInit({
  required bool coreAlreadyInitialized,
  required bool needsInitialStatusSetup,
}) {
  return coreAlreadyInitialized && !needsInitialStatusSetup;
}
