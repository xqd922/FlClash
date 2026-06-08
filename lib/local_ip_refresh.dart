import 'dart:async';

typedef LocalIpLookup = Future<String?> Function();
typedef LocalIpUpdate = void Function(String? value);

class LocalIpRefreshController {
  LocalIpRefreshController({required this.lookup, required this.update});

  final LocalIpLookup lookup;
  final LocalIpUpdate update;
  Future<void>? _refreshing;

  Future<void> refresh() {
    final currentRefresh = _refreshing;
    if (currentRefresh != null) {
      return currentRefresh;
    }
    final refresh = _refresh();
    _refreshing = refresh;
    return refresh;
  }

  Future<void> _refresh() async {
    try {
      update(await lookup());
    } finally {
      _refreshing = null;
    }
  }
}
