import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A self-contained paginated list state.
///
/// Wraps a `Future<T> Function(int limit, int offset)` loader and accumulates
/// pages into a single growing list. The UI just calls [loadMore] when the
/// scroll reaches the end; the controller dedupes in-flight requests and stops
/// once a page returns fewer items than [pageSize] (no more data).
class PaginatedList<T> {
  PaginatedList({
    required this.loader,
    this.pageSize = 20,
  });

  /// Loader for one page. Returns the items for [limit] starting at [offset].
  final Future<List<T>> Function(int limit, int offset) loader;
  final int pageSize;

  final List<T> _items = [];
  bool _hasMore = true;
  bool _loading = false;
  bool _initialLoading = true;
  Object? _error;

  List<T> get items => List.unmodifiable(_items);
  bool get hasMore => _hasMore;
  bool get loading => _loading;
  bool get initialLoading => _initialLoading;
  Object? get error => _error;
  int get length => _items.length;

  /// First load. Safe to call from initState / didChangeDependencies.
  Future<void> loadInitial() async {
    if (_loading) return; // already in-flight
    _loading = true;
    _initialLoading = true;
    _error = null;
    _items.clear();
    _hasMore = true;
    try {
      final page = await loader(pageSize, 0);
      _items.addAll(page);
      _hasMore = page.length >= pageSize;
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      _initialLoading = false;
    }
  }

  /// Load the next page. Returns false when there is nothing more to load.
  Future<bool> loadMore() async {
    if (_loading || !_hasMore) return false;
    _loading = true;
    try {
      final page = await loader(pageSize, _items.length);
      _items.addAll(page);
      _hasMore = page.length >= pageSize;
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _loading = false;
    }
  }

  /// Force a fresh reload of the first page.
  Future<void> refresh() async {
    await loadInitial();
  }
}

/// A Riverpod StateNotifier that owns a [PaginatedList].
class PaginatedListNotifier<T> extends StateNotifier<PaginatedList<T>> {
  PaginatedListNotifier(this.list) : super(list);

  final PaginatedList<T> list;

  Future<void> loadInitial() async {
    await list.loadInitial();
    state = list;
  }

  Future<void> loadMore() async {
    await list.loadMore();
    state = list;
  }

  Future<void> refresh() async {
    await list.refresh();
    state = list;
  }
}

/// Convenience provider factory: build a notifier from a loader function.
PaginatedListNotifier<T> createPaginatedNotifier<T>(
  Future<List<T>> Function(int limit, int offset) loader, {
  int pageSize = 20,
}) {
  return PaginatedListNotifier<T>(
    PaginatedList<T>(loader: loader, pageSize: pageSize),
  );
}
