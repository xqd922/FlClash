const coreEventGroupRefreshQuietPeriod = Duration(seconds: 8);

bool shouldRefreshGroupsAfterCoreEvent({
  required DateTime? lastGroupsRefreshAt,
  required DateTime eventAt,
}) {
  final lastRefreshAt = lastGroupsRefreshAt;
  if (lastRefreshAt == null) {
    return true;
  }
  return eventAt.difference(lastRefreshAt) >= coreEventGroupRefreshQuietPeriod;
}
