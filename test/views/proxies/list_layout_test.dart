import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/views/proxies/list_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Proxies list layout', () {
    test('builds lightweight entries for expanded and collapsed groups', () {
      final groups = [
        _group('Auto', proxyCount: 3),
        _group('Fallback', proxyCount: 1),
      ];

      final layout = buildProxiesListLayout(
        groups: groups,
        expandedGroupNames: {'Auto'},
        columns: 2,
        headerHeight: 40,
        proxyRowHeight: 64,
        gapHeight: 8,
      );

      expect(layout.length, 8);
      expect(layout.itemHeights, [40, 8, 64, 8, 64, 8, 40, 8]);
      expect(layout.headerOffsets, [0, 192]);

      expect(layout.entryAt(0).type, ProxiesListEntryType.header);
      expect(layout.entryAt(0).groupIndex, 0);

      final firstRow = layout.entryAt(2);
      expect(firstRow.type, ProxiesListEntryType.proxyRow);
      expect(firstRow.groupIndex, 0);
      expect(firstRow.proxyStartIndex, 0);
      expect(firstRow.proxyEndIndex, 2);

      final secondRow = layout.entryAt(4);
      expect(secondRow.type, ProxiesListEntryType.proxyRow);
      expect(secondRow.proxyStartIndex, 2);
      expect(secondRow.proxyEndIndex, 3);

      expect(layout.entryAt(6).type, ProxiesListEntryType.header);
      expect(layout.entryAt(6).groupIndex, 1);
    });

    test('keeps expanded empty groups compatible with existing spacing', () {
      final layout = buildProxiesListLayout(
        groups: [_group('Empty', proxyCount: 0)],
        expandedGroupNames: {'Empty'},
        columns: 2,
        headerHeight: 40,
        proxyRowHeight: 64,
        gapHeight: 8,
      );

      expect(layout.itemHeights, [40, 8, 8]);
      expect(layout.headerOffsets, [0]);
    });

    test('rejects invalid column counts', () {
      expect(
        () => buildProxiesListLayout(
          groups: [_group('Auto', proxyCount: 1)],
          expandedGroupNames: {'Auto'},
          columns: 0,
          headerHeight: 40,
          proxyRowHeight: 64,
          gapHeight: 8,
        ),
        throwsRangeError,
      );
    });
  });
}

Group _group(String name, {required int proxyCount}) {
  return Group(
    name: name,
    type: GroupType.Selector,
    all: List.generate(
      proxyCount,
      (index) => Proxy(name: '$name-$index', type: 'ss'),
    ),
  );
}
