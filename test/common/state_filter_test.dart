import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogsState list', () {
    test('reuses source logs when there is no filter', () {
      final logs = LogsState(
        logs: [
          Log(
            logLevel: LogLevel.info,
            payload: 'started',
            dateTime: '2026-01-01 00:00:00',
          ),
        ],
      ).logs;

      final state = LogsState(logs: logs);

      expect(identical(state.list, logs), isTrue);
    });

    test('filters by keyword and query', () {
      final error = Log(
        logLevel: LogLevel.error,
        payload: 'failed to connect',
        dateTime: '2026-01-01 00:00:00',
      );
      final info = Log(
        logLevel: LogLevel.info,
        payload: 'connected',
        dateTime: '2026-01-01 00:00:01',
      );

      final state = LogsState(
        logs: [error, info],
        keywords: [LogLevel.error.name],
        query: 'connect',
      );

      expect(state.list, [error]);
    });
  });

  group('TrackerInfosState list', () {
    test('reuses source tracker infos when there is no filter', () {
      final trackerInfos = TrackerInfosState(
        trackerInfos: [_trackerInfo('first')],
      ).trackerInfos;

      final state = TrackerInfosState(trackerInfos: trackerInfos);

      expect(identical(state.list, trackerInfos), isTrue);
    });

    test('filters by keyword and query', () {
      final direct = _trackerInfo(
        'direct',
        process: 'browser',
        chains: ['DIRECT'],
        host: 'example.com',
      );
      final proxy = _trackerInfo(
        'proxy',
        process: 'terminal',
        chains: ['Proxy'],
        host: 'github.com',
      );

      final state = TrackerInfosState(
        trackerInfos: [direct, proxy],
        keywords: ['DIRECT', 'browser'],
        query: 'EXAMPLE',
      );

      expect(state.list, [direct]);
    });
  });
}

TrackerInfo _trackerInfo(
  String id, {
  String process = '',
  List<String> chains = const ['DIRECT'],
  String host = 'example.com',
}) {
  return TrackerInfo(
    id: id,
    start: DateTime(2026, 1, 1),
    metadata: Metadata(
      network: 'tcp',
      host: host,
      destinationIP: '93.184.216.34',
      destinationPort: '443',
      process: process,
    ),
    chains: chains,
    rule: 'MATCH',
    rulePayload: '',
  );
}
