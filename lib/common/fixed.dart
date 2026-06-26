import 'iterable.dart';

typedef ValueCallback<T> = T Function();

class FixedList<T> {
  final int maxLength;
  final List<T> _list;
  final int _version;

  FixedList(this.maxLength, {List<T>? list, int version = 0})
      : _list = (list ?? [])..truncate(maxLength),
        _version = version;

  void add(T item) {
    _list.add(item);
    _list.truncate(maxLength);
  }

  /// Returns a new FixedList with [item] appended and version bumped.
  /// Avoids a full copy when already at capacity (drops oldest, adds newest).
  FixedList<T> addAndNotify(T item) {
    if (maxLength > 0 && _list.length >= maxLength) {
      // ponytail: copies maxLength-1 elements, upgrade to ring buffer if profiling shows this hot
      final newList = List<T>.from(_list, growable: true)
        ..removeAt(0)
        ..add(item);
      return FixedList(maxLength, list: newList, version: _version + 1);
    }
    return FixedList(maxLength, list: List<T>.from(_list)..add(item),
        version: _version + 1);
  }

  void clear() {
    _list.clear();
  }

  List<T> get list => List.unmodifiable(_list);

  int get length => _list.length;

  T operator [](int index) => _list[index];

  FixedList<T> copyWith() {
    return FixedList(maxLength, list: _list);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FixedList<T> &&
          maxLength == other.maxLength &&
          _version == other._version &&
          _list.length == other._list.length &&
          _listEquals(_list, other._list);

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(maxLength, _version, Object.hashAll(_list));
}

class FixedMap<K, V> {
  int maxLength;
  late Map<K, V> _map;

  FixedMap(this.maxLength, {Map<K, V>? map}) {
    _map = map ?? {};
  }

  V updateCacheValue(K key, ValueCallback<V> callback) {
    final realValue = _map.updateCacheValue(
      key,
      callback,
    );
    _adjustMap();
    return realValue;
  }

  void clear() {
    _map.clear();
  }

  void updateMaxLength(int size) {
    maxLength = size;
    _adjustMap();
  }

  void updateMap(Map<K, V> map) {
    _map = map;
    _adjustMap();
  }

  void _adjustMap() {
    if (_map.length > maxLength) {
      _map = Map.fromEntries(
        map.entries.toList()..truncate(maxLength),
      );
    }
  }

  V? get(K key) => _map[key];

  bool containsKey(K key) => _map.containsKey(key);

  int get length => _map.length;

  Map<K, V> get map => Map.unmodifiable(_map);
}
