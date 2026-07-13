import 'package:fl_clash/common/navigation.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requests navigation is hidden by default', () {
    final requests = navigation.getItems().singleWhere(
      (item) => item.label == PageLabel.requests,
    );

    expect(requests.modes, isEmpty);
  });

  test('requests navigation can be enabled', () {
    final requests = navigation
        .getItems(openRequests: true)
        .singleWhere((item) => item.label == PageLabel.requests);

    expect(requests.modes, [
      NavigationItemMode.desktop,
      NavigationItemMode.more,
    ]);
  });
}
