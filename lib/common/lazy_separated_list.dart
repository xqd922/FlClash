final class LazySeparatedList<T> {
  final List<T> items;

  const LazySeparatedList(this.items);

  int get length => items.isEmpty ? 0 : items.length * 2 - 1;

  bool isSeparator(int index) {
    _checkIndex(index);
    return index.isOdd;
  }

  T itemAt(int index) {
    _checkIndex(index);
    if (index.isOdd) {
      throw RangeError.index(index, this, 'index');
    }
    return items[index ~/ 2];
  }

  void _checkIndex(int index) {
    RangeError.checkValidIndex(index, this, 'index', length);
  }
}
