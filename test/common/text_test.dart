import 'package:fl_clash/common/text.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('text style helpers keep the Material font weight', () {
    const style = TextStyle(fontWeight: FontWeight.w500);

    expect(style.toSoftBold.fontWeight, FontWeight.w500);
    expect(style.toBold.fontWeight, FontWeight.bold);
  });
}
