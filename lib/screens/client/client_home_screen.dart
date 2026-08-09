import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';

/// Lazy paged source for active shipments, keyed by the active filters.
final clientShipmentsPagerProvider = StateNotifierProvider.family<
    PaginatedListNotifier<Shipment>,
    PaginatedList<Shipment>,
    ({String? destination, String? origin})>(
  (ref, params) {
    return createPaginatedNotifier(
      (limit, offset) => ref
          .read(shipmentServiceProvider)
          .getActiveShipments(
            destinationCity: params.destination,
            originCountry: params.origin,
            limit: limit,
            offset: offset,
          ),
      pageSize: 15,
    );
  },
);

/// Lazy paged server-side search source, keyed by the search query.
final clientSearchPagerProvider =
    StateNotifierProvider.family<PaginatedListNotifier<Shipment>,
        PaginatedList<Shipment>, String>((ref, query) {
  return createPaginatedNotifier(
    (limit, offset) => ref.read(shipmentServiceProvider).searchShipments(
          query: query,
          limit: limit,
          offset: offset,
        ),
    pageSize: 15,
  );
});

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  final _scrollController = ScrollController();
  String _lastFilterKey = '';
  String _lastSearchKey = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPager());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPager();
    _syncSearch();
  }

  /// (Re)load the first page whenever the filter combo changes.
  void _syncPager() {
    final destination = ref.read(destinationFilterProvider);
    final origin = ref.read(originFilterProvider);
    final key = '$destination|$origin';
    if (key == _lastFilterKey) return;
    _lastFilterKey = key;
    final notifier = ref.read(
      clientShipmentsPagerProvider((destination: destination, origin: origin))
          .notifier,
    );
    notifier.loadInitial();
  }

  /// (Re)load server-side search results when the query changes.
  void _syncSearch() {
    final query = ref.read(searchQueryProvider).trim();
    if (query.isEmpty) return;
    if (query == _lastSearchKey) return;
    _lastSearchKey = query;
    final notifier = ref.read(clientSearchPagerProvider(query).notifier);
    notifier.loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final destination = ref.watch(destinationFilterProvider);
    final origin = ref.watch(originFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final pager = ref.watch(
      clientShipmentsPagerProvider((destination: destination, origin: origin)),
    );
    final searchPager =
        ref.watch(clientSearchPagerProvider(searchQuery.trim()));

    final isSearching = searchQuery.trim().isNotEmpty;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          if (isSearching) {
            await ref
                .read(clientSearchPagerProvider(searchQuery.trim()).notifier)
                .refresh();
            return;
          }
          await ref
              .read(
                clientShipmentsPagerProvider(
                  (destination: destination, origin: origin),
                ).notifier,
              )
              .refresh();
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            GradientSliverHeader(
              title: 'CargoLink',
              subtitle: 'Trouvez les meilleurs micro-importateurs pour vos commandes',
              icon: Icons.local_shipping_rounded,
              trailing: GestureDetector(
                onTap: () => _showNotificationsSheet(context),
                child: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: _UnreadBadge(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildGreeting(currentUser),
            ),
            SliverToBoxAdapter(
              child: _buildSearchBar(),
            ),
            SliverToBoxAdapter(
              child: _buildFilters(),
            ),
            if (!isSearching)
              PagedSliverList<Shipment>(
                paginatedList: pager,
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMd,
                  AppTheme.spaceSm,
                  AppTheme.spaceMd,
                  AppTheme.spaceXxl,
                ),
                emptyState: const _EmptyShipments(),
                itemBuilder: (context, shipment, index) => StaggeredEntrance(
                  delay: Duration(milliseconds: (index % 10) * 40),
                  child: _ShipmentCard(shipment: shipment),
                ),
              )
            else
              PagedSliverList<Shipment>(
                paginatedList: searchPager,
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMd,
                  AppTheme.spaceSm,
                  AppTheme.spaceMd,
                  AppTheme.spaceXxl,
                ),
                emptyState: const _NoSearchResults(),
                itemBuilder: (context, shipment, index) => StaggeredEntrance(
                  delay: Duration(milliseconds: (index % 10) * 40),
                  child: _ShipmentCard(shipment: shipment),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(AsyncValue<User?> currentUser) {
    return currentUser.when(
      data: (user) {
        final name = user?.fullName ?? '';
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd,
            AppTheme.spaceMd,
            AppTheme.spaceMd,
            AppTheme.spaceSm,
          ),
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppTheme.shadowMd,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceSm + 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Bonjour 👋' : 'Bonjour $name 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Trouvez les meilleurs micro-importateurs pour vos commandes',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: TextField(
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
        decoration: const InputDecoration(
          hintText: 'Rechercher par destination, origine...',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final destination = ref.watch(destinationFilterProvider);
    final origin = ref.watch(originFilterProvider);
    final hasFilter = destination != null || origin != null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      child: Row(
        children: [
          _FilterChip(
            label: destination ?? 'Destination',
            selected: destination != null,
            icon: Icons.location_on_outlined,
            onTap: () => _showDestinationPicker(),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: origin ?? 'Origine',
            selected: origin != null,
            icon: Icons.flight_takeoff_rounded,
            onTap: () => _showOriginPicker(),
          ),
          if (hasFilter) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Effacer',
              selected: false,
              icon: Icons.clear_rounded,
              onTap: () {
                ref.read(destinationFilterProvider.notifier).state = null;
                ref.read(originFilterProvider.notifier).state = null;
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showDestinationPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(AppTheme.spaceMd),
              child: Text('Choisir une destination', style: AppTheme.h3),
            ),
            ...AppConstants.majorCities.map(
              (city) => ListTile(
                leading: const Icon(Icons.location_city_rounded,
                    color: AppTheme.primaryColor),
                title: Text(city),
                onTap: () {
                  ref.read(destinationFilterProvider.notifier).state = city;
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOriginPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(AppTheme.spaceMd),
              child: Text("Choisir l'origine", style: AppTheme.h3),
            ),
            ...AppConstants.populateOrigins.map(
              (origin) => ListTile(
                leading: const Icon(Icons.flight_takeoff_rounded,
                    color: AppTheme.primaryColor),
                title: Text(origin),
                onTap: () {
                  ref.read(originFilterProvider.notifier).state = origin;
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const FractionallySizedBox(
        heightFactor: 0.85,
        child: NotificationsSheet(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

// ============================================================================
// SHIPMENT CARD WIDGET
// ============================================================================

class _ShipmentCard extends ConsumerWidget {
  final Shipment shipment;

  const _ShipmentCard({required this.shipment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final full = shipment.isFull;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: GlassCard(
        onTap: () => _navigateToBooking(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            shipment.originCountry,
                            style: AppTheme.h3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 18, color: AppTheme.textMutedColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            shipment.destinationCity,
                            style: AppTheme.h3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event_rounded,
                            size: 14, color: AppTheme.textMutedColor),
                        const SizedBox(width: 4),
                        Text(
                          'Arrivée ${_formatDate(shipment.arrivalDate)}',
                          style: AppTheme.caption,
                        ),
                        if (shipment.flightNumber != null) ...[
                          const SizedBox(width: 8),
                          Text('• Vol ${shipment.flightNumber}',
                              style: AppTheme.caption),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (shipment.shipper != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        shipment.shipper!.ratingDisplay,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Disponible',
                  value: '${shipment.remainingWeightKg.toStringAsFixed(1)} kg',
                ),
              ),
              Expanded(
                child: _InfoTile(
                  icon: Icons.payments_outlined,
                  label: 'Prix / kg',
                  value: '${shipment.pricePerKg.toStringAsFixed(0)} DZD',
                  valueColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (shipment.utilizationPercent / 100).clamp(0, 1),
              minHeight: 6,
              backgroundColor: AppTheme.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(
                full ? AppTheme.errorColor : AppTheme.accentColor,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: full ? null : () => _navigateToBooking(context),
              icon: Icon(full ? Icons.block_rounded : Icons.assignment_turned_in_outlined),
              label: Text(full ? 'Complet' : 'Réserver'),
            ),
          ),
        ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  void _navigateToBooking(BuildContext context) {
    Navigator.of(context).pushNamed('/booking', arguments: shipment.id);
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedIconDot(icon: icon, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.caption),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: valueColor ?? AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyShipments extends StatelessWidget {
  const _EmptyShipments();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_shipping_outlined,
            size: 64, color: AppTheme.textMutedColor),
        SizedBox(height: AppTheme.spaceMd),
        Text('Aucun shipment disponible', style: AppTheme.h3),
        SizedBox(height: AppTheme.spaceSm),
        Text(
          'Reviens plus tard ou élargis tes filtres.',
          style: AppTheme.bodySecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.search_off_rounded,
            size: 56, color: AppTheme.textMutedColor),
        SizedBox(height: AppTheme.spaceMd),
        Text('Aucun résultat pour cette recherche', style: AppTheme.h3),
        SizedBox(height: AppTheme.spaceSm),
        Text(
          'Essaie une autre destination ou origine.',
          style: AppTheme.bodySecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ============================================================================
// NOTIFICATIONS BADGE
// ============================================================================

class _UnreadBadge extends ConsumerWidget {
  const _UnreadBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.read(authServiceProvider).currentUserId;
    if (userId == null) {
      return const Icon(Icons.notifications_outlined, color: Colors.white);
    }

    final notifs = ref.watch(notificationStreamProvider(userId));

    return notifs.when(
      data: (list) {
        final count = list.where((n) => !n.isRead).length;
        if (count == 0) {
          return const Icon(Icons.notifications_outlined, color: Colors.white);
        }
        return Badge.count(
          count: count > 99 ? 99 : count,
          child: const Icon(Icons.notifications_outlined, color: Colors.white),
        );
      },
      loading: () =>
          const Icon(Icons.notifications_outlined, color: Colors.white),
      error: (error, stack) =>
          const Icon(Icons.notifications_outlined, color: Colors.white),
    );
  }
}

// ============================================================================
// NOTIFICATIONS SHEET
// ============================================================================

class NotificationsSheet extends ConsumerWidget {
  const NotificationsSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final userId = authService.currentUserId;

    if (userId == null) {
      return const Center(child: Text('Utilisateur non identifié'));
    }

    final notifications = ref.watch(notificationStreamProvider(userId));

    return notifications.when(
      data: (notifs) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      ref
                          .read(notificationServiceProvider)
                          .markAllAsRead(userId);
                    },
                    child: const Text('Marquer tout comme lu'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: notifs.isEmpty
                  ? const Center(child: Text('Aucune notification'))
                  : ListView.builder(
                      itemCount: notifs.length,
                      itemBuilder: (context, index) {
                        final notif = notifs[index];
                        return ListTile(
                          title: Text(notif.title),
                          subtitle: Text(notif.message),
                          trailing: !notif.isRead
                              ? CircleAvatar(
                                  radius: 4,
                                  backgroundColor: AppTheme.primaryColor,
                                )
                              : null,
                          onTap: () {
                            ref
                                .read(notificationServiceProvider)
                                .markAsRead(notif.id);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Erreur: $error')),
    );
  }
}
