import 'package:fl_clash/common/lazy_separated_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LazySeparatedList', () {
    test(
      'maps source items and separators by index without expanding widgets',
      () {
        final items = ['first', 'second', 'third'];
        final list = LazySeparatedList(items);

        expect(list.length, 5);
        expect(list.isSeparator(0), isFalse);
        expect(list.isSeparator(1), isTrue);
        expect(list.itemAt(0), 'first');
        expect(list.itemAt(2), 'second');
        expect(list.itemAt(4), 'third');
      },
    );

    test('has no children for an empty source list', () {
      final list = LazySeparatedList<String>(const []);

      expect(list.length, 0);
    });

    test('throws range errors for invalid separated indexes', () {
      final list = LazySeparatedList(const ['only']);

      expect(() => list.isSeparator(-1), throwsRangeError);
      expect(() => list.itemAt(1), throwsRangeError);
    });
  });
}
