import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'paginated_list.dart';
import '../theme/app_theme.dart';
import 'shimmer.dart';

/// A lazy, paginated SliverList with infinite scrolling.
///
/// Drop this inside a `CustomScrollView`. It owns its pagination state via
/// [paginatedList] and triggers [PaginatedList.loadMore] when the scroll
/// reaches the bottom. Handles initial shimmer, error + retry, an empty state
/// and a bottom loading indicator — no nested scroll views.
class PagedSliverList<T> extends ConsumerWidget {
  const PagedSliverList({
    super.key,
    required this.paginatedList,
    required this.itemBuilder,
    this.separator,
    this.padding = EdgeInsets.zero,
    this.emptyState,
    this.skeletonCount = 6,
  });

  final PaginatedList<T> paginatedList;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? separator;
  final EdgeInsets padding;
  final Widget? emptyState;
  final int skeletonCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = paginatedList;

    // Initial loading
    if (list.initialLoading) {
      return SliverPadding(
        padding: padding,
        sliver: SliverList.builder(
          itemCount: skeletonCount,
          itemBuilder: (_, i) => const ShimmerCard(),
        ),
      );
    }

    // Error on first load
    if (list.error != null && list.items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _ErrorState(
          error: list.error,
          onRetry: () => paginatedList.loadInitial(),
        ),
      );
    }

    // Empty
    if (list.items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: emptyState ?? const _DefaultEmptyState(),
      );
    }

    // Content + automatic infinite scroll trigger
    final itemCount = list.items.length + (list.hasMore ? 1 : 0);
    return SliverPadding(
      padding: padding,
      sliver: SliverList.builder(
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= list.items.length) {
            // Footer row: triggers next page load
            WidgetsBinding.instance.addPostFrameCallback((_) {
              paginatedList.loadMore();
            });
            return _LoadMoreFooter(loading: list.loading);
          }
          final item = list.items[index];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              itemBuilder(context, item, index),
              if (separator != null && index != list.items.length - 1)
                separator!,
            ],
          );
        },
      ),
    );
  }
}

/// A lazy, paginated SliverGrid with infinite scrolling (e.g. shipments grid).
class PagedSliverGrid<T> extends ConsumerWidget {
  const PagedSliverGrid({
    super.key,
    required this.paginatedList,
    required this.itemBuilder,
    required this.gridDelegate,
    this.padding = EdgeInsets.zero,
    this.emptyState,
    this.skeletonCount = 6,
  });

  final PaginatedList<T> paginatedList;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final EdgeInsets padding;
  final Widget? emptyState;
  final int skeletonCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = paginatedList;

    if (list.initialLoading) {
      return SliverPadding(
        padding: padding,
        sliver: SliverGrid.builder(
          gridDelegate: gridDelegate,
          itemCount: skeletonCount,
          itemBuilder: (_, i) => const ShimmerCard(imageHeight: 90, lines: 2),
        ),
      );
    }

    if (list.error != null && list.items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _ErrorState(
          error: list.error,
          onRetry: () => paginatedList.loadInitial(),
        ),
      );
    }

    if (list.items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: emptyState ?? const _DefaultEmptyState(),
      );
    }

    final itemCount = list.items.length + (list.hasMore ? 1 : 0);
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid.builder(
        gridDelegate: gridDelegate,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= list.items.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              paginatedList.loadMore();
            });
            return _LoadMoreFooter(loading: list.loading);
          }
          return itemBuilder(context, list.items[index], index);
        },
      ),
    );
  }
}

/// A simple one-shot paged loader intended for `RefreshIndicator` usage:
/// wraps [PaginatedList.loadInitial] so pull-to-refresh also triggers the
/// on-screen footer logic.
class PagedRefreshable extends StatelessWidget {
  const PagedRefreshable({
    super.key,
    required this.scrollView,
    required this.onRefresh,
  });

  final Widget scrollView;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: onRefresh,
      child: scrollView,
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceLg),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primaryColor,
                ),
              )
            : const Icon(
                Icons.keyboard_arrow_down,
                color: AppTheme.textMutedColor,
              ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppTheme.textMutedColor,
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Text(
              'Impossible de charger',
              style: AppTheme.h3,
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              'Vérifie ta connexion puis réessaie.',
              style: AppTheme.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceLg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultEmptyState extends StatelessWidget {
  const _DefaultEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AppTheme.textMutedColor,
            ),
            SizedBox(height: AppTheme.spaceMd),
            Text('Rien à afficher pour le moment', style: AppTheme.h3),
          ],
        ),
      ),
    );
  }
}
