import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Traffic.trayTitle stays on one line for upstream tray_manager', () {
    const traffic = Traffic(up: 1536, down: 2048);

    expect(traffic.trayTitle, isNot(contains('\n')));
  });
}
