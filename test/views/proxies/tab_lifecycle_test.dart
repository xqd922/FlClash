import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ProxiesTabViewState disposes overflow notifier', () {
    final source = File('lib/views/proxies/tab.dart').readAsStringSync();
    final stateStart = source.indexOf('class ProxiesTabViewState');
    final disposeStart = source.indexOf('void dispose()', stateStart);
    final disposeEnd = source.indexOf('}', disposeStart);
    final disposeBody = source.substring(disposeStart, disposeEnd);

    final notifierDisposeIndex = disposeBody.indexOf(
      '_hasMoreButtonNotifier.dispose();',
    );
    final superDisposeIndex = disposeBody.indexOf('super.dispose();');

    expect(notifierDisposeIndex, isNonNegative);
    expect(notifierDisposeIndex, lessThan(superDisposeIndex));
  });
}
