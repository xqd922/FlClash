import 'package:fl_clash/models/models.dart';

enum ProxiesListEntryType { header, gap, proxyRow }

final class ProxiesListEntry {
  final ProxiesListEntryType type;
  final int groupIndex;
  final int proxyStartIndex;
  final int proxyEndIndex;
  final double height;

  const ProxiesListEntry.header({
    required this.groupIndex,
    required this.height,
  }) : type = ProxiesListEntryType.header,
       proxyStartIndex = -1,
       proxyEndIndex = -1;

  const ProxiesListEntry.gap({required this.height})
    : type = ProxiesListEntryType.gap,
      groupIndex = -1,
      proxyStartIndex = -1,
      proxyEndIndex = -1;

  const ProxiesListEntry.proxyRow({
    required this.groupIndex,
    required this.proxyStartIndex,
    required this.proxyEndIndex,
    required this.height,
  }) : type = ProxiesListEntryType.proxyRow;
}

final class ProxiesListLayout {
  final List<ProxiesListEntry> entries;
  final List<double> headerOffsets;

  const ProxiesListLayout({required this.entries, required this.headerOffsets});

  int get length => entries.length;

  List<double> get itemHeights {
    return [for (final entry in entries) entry.height];
  }

  ProxiesListEntry entryAt(int index) {
    return entries[RangeError.checkValidIndex(index, entries)];
  }
}

ProxiesListLayout buildProxiesListLayout({
  required List<Group> groups,
  required Set<String> expandedGroupNames,
  required int columns,
  required double headerHeight,
  required double proxyRowHeight,
  required double gapHeight,
}) {
  RangeError.checkNotNegative(columns - 1, 'columns');

  final entries = <ProxiesListEntry>[];
  final headerOffsets = <double>[];
  var currentHeight = 0.0;

  void addEntry(ProxiesListEntry entry) {
    entries.add(entry);
    currentHeight += entry.height;
  }

  for (var groupIndex = 0; groupIndex < groups.length; groupIndex++) {
    final group = groups[groupIndex];
    headerOffsets.add(currentHeight);
    addEntry(
      ProxiesListEntry.header(groupIndex: groupIndex, height: headerHeight),
    );
    addEntry(ProxiesListEntry.gap(height: gapHeight));

    if (!expandedGroupNames.contains(group.name)) {
      continue;
    }

    for (
      var proxyStartIndex = 0;
      proxyStartIndex < group.all.length;
      proxyStartIndex += columns
    ) {
      final proxyEndIndex = (proxyStartIndex + columns).clamp(
        0,
        group.all.length,
      );
      addEntry(
        ProxiesListEntry.proxyRow(
          groupIndex: groupIndex,
          proxyStartIndex: proxyStartIndex,
          proxyEndIndex: proxyEndIndex,
          height: proxyRowHeight,
        ),
      );
      addEntry(ProxiesListEntry.gap(height: gapHeight));
    }

    if (group.all.isEmpty) {
      addEntry(ProxiesListEntry.gap(height: gapHeight));
    }
  }

  return ProxiesListLayout(entries: entries, headerOffsets: headerOffsets);
}
