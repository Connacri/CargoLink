import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable paginated list state.
///
/// Every mutation produces a NEW instance (via [copyWith]) so that assigning
/// it back to a Riverpod [StateNotifier] state is a different object and
/// triggers listeners. Mutating in place and re-assigning the same instance
/// silently suppresses notifications (StateNotifier dedupes with `==`).
class PaginatedList<T> {
  const PaginatedList({
    required this.loader,
    required this.pageSize,
    this.items = const [],
    this.hasMore = true,
    this.loading = false,
    this.initialLoading = false,
    this.error,
    this.onReload,
    this.onLoadMore,
  });

  /// Loader for one page: returns the items for [pageSize] starting at [offset].
  final Future<List<T>> Function(int limit, int offset) loader;
  final int pageSize;

  final List<T> items;
  final bool hasMore;
  final bool loading;
  final bool initialLoading;
  final Object? error;

  /// Bound to the owning notifier's [PaginatedListNotifier.loadInitial],
  /// used by the UI retry button to reload after an error.
  final Future<void> Function()? onReload;

  /// Bound to the owning notifier's [PaginatedListNotifier.loadMore],
  /// used by the infinite-scroll footer to fetch the next page.
  final Future<void> Function()? onLoadMore;

  int get length => items.length;

  PaginatedList<T> copyWith({
    List<T>? items,
    bool? hasMore,
    bool? loading,
    bool? initialLoading,
    Object? error,
    bool clearError = false,
    Future<void> Function()? onReload,
    Future<void> Function()? onLoadMore,
  }) {
    return PaginatedList<T>(
      loader: loader,
      pageSize: pageSize,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      loading: loading ?? this.loading,
      initialLoading: initialLoading ?? this.initialLoading,
      error: clearError ? null : error,
      onReload: onReload ?? this.onReload,
      onLoadMore: onLoadMore ?? this.onLoadMore,
    );
  }
}

/// A Riverpod [StateNotifier] that owns an immutable [PaginatedList].
class PaginatedListNotifier<T> extends StateNotifier<PaginatedList<T>> {
  PaginatedListNotifier({
    required Future<List<T>> Function(int limit, int offset) loader,
    int pageSize = 20,
  }) : super(PaginatedList<T>(loader: loader, pageSize: pageSize)) {
    state = state.copyWith(onReload: loadInitial, onLoadMore: loadMore);
  }

  /// First load. Safe to call from initState / didChangeDependencies.
  Future<void> loadInitial() async {
    if (state.loading) return; // already in-flight
    state = state.copyWith(
      loading: true,
      initialLoading: true,
      items: const [],
      hasMore: true,
      clearError: true,
    );
    try {
      final page = await state.loader(state.pageSize, 0);
      state = state.copyWith(
        items: page,
        hasMore: page.length >= state.pageSize,
        loading: false,
        initialLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        error: e,
        loading: false,
        initialLoading: false,
      );
    }
  }

  /// Load the next page. Returns false when there is nothing more to load.
  Future<bool> loadMore() async {
    if (state.loading || !state.hasMore) return false;
    state = state.copyWith(loading: true);
    try {
      final page = await state.loader(state.pageSize, state.items.length);
      state = state.copyWith(
        items: [...state.items, ...page],
        hasMore: page.length >= state.pageSize,
        loading: false,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e, loading: false);
      return false;
    }
  }

  /// Force a fresh reload of the first page.
  Future<void> refresh() async {
    await loadInitial();
  }
}

/// Convenience provider factory: build a notifier from a loader function.
PaginatedListNotifier<T> createPaginatedNotifier<T>(
  Future<List<T>> Function(int limit, int offset) loader, {
  int pageSize = 20,
}) {
  return PaginatedListNotifier<T>(loader: loader, pageSize: pageSize);
}
