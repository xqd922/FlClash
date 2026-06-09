import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/views/connection/connections_updates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Connections updates', () {
    test('skips replacing the visible list when connections are unchanged', () {
      final current = [_trackerInfo('1')];
      final unchanged = [_trackerInfo('1')];

      expect(shouldUpdateConnectionsList(current, unchanged), isFalse);
    });

    test('replaces the visible list when connection traffic changes', () {
      final current = [_trackerInfo('1')];
      final changed = [_trackerInfo('1', download: 1024)];

      expect(shouldUpdateConnectionsList(current, changed), isTrue);
    });
  });
}

TrackerInfo _trackerInfo(String id, {int download = 0}) {
  return TrackerInfo(
    id: id,
    download: download,
    start: DateTime(2026),
    metadata: const Metadata(),
    chains: const ['DIRECT'],
    rule: 'MATCH',
    rulePayload: '',
  );
}
