import 'package:fl_clash/common/text.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('text style helpers follow the system regular weight', () {
    const style = TextStyle(fontWeight: FontWeight.w500);

    expect(style.toSoftBold.fontWeight, FontWeight.w400);
    expect(style.toBold.fontWeight, FontWeight.bold);
  });
}
