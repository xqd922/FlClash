import 'package:fl_clash/common/fixed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FixedList', () {
    test('keeps newest items after reaching max length', () {
      final list = FixedList<int>(3);

      list.add(1);
      list.add(2);
      list.add(3);
      list.add(4);

      expect(list.list, [2, 3, 4]);
    });

    test('keeps empty list when max length is zero', () {
      final list = FixedList<int>(0);

      list.add(1);

      expect(list.list, isEmpty);
    });
  });
}
