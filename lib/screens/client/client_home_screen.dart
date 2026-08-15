import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../../core/widgets/notification_widgets.dart';
import '../../core/widgets/chat_widgets.dart';
import '../../components/shipper_card.dart';
import '../shipper/shipper_public_profile_screen.dart';
import '../chat/chat_screen.dart';

/// Smart sort applied to the (server-side filtered) search feed.
enum ClientSort { none, price, fastest, topRated }

final clientSortProvider = StateProvider<ClientSort>((ref) => ClientSort.none);

/// Lazy paged source for active shipments, keyed by the active filters.
final clientShipmentsPagerProvider = StateNotifierProvider.family<
    PaginatedListNotifier<Shipment>,
    PaginatedList<Shipment>,
    ({String? destination, String? origin})>(
  (ref, params) {
    return createPaginatedNotifier(
      (limit, offset) => ref.read(shipmentServiceProvider).getActiveShipments(
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
final clientSearchPagerProvider = StateNotifierProvider.family<
    PaginatedListNotifier<Shipment>,
    PaginatedList<Shipment>,
    String>((ref, query) {
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
  const ClientHomeScreen({super.key});

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
    // Never touch a pager provider while the widget tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPager());
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSearch());
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
    final sort = ref.watch(clientSortProvider);

    // Smart sort applied locally on top of the server-side filters. Keeping
    // the same PaginatedList (via copyWith) preserves infinite scrolling and
    // pull-to-refresh callbacks.
    final sortedFeed = pager.copyWith(items: _applySort(pager.items, sort));
    final sortedSearch =
        searchPager.copyWith(items: _applySort(searchPager.items, sort));

    // Live refresh: a newly published shipment appears in the feed without a
    // manual pull-to-refresh.
    ref.listen(
      tableChangesProvider(('shipments', null, null)),
      (previous, next) {
        if (next.hasValue) {
          if (isSearching) {
            ref
                .read(clientSearchPagerProvider(searchQuery.trim()).notifier)
                .refresh();
          } else {
            ref
                .read(clientShipmentsPagerProvider(
                  (destination: destination, origin: origin),
                ).notifier)
                .refresh();
          }
        }
      },
    );

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
              subtitle:
                  'Trouvez les meilleurs micro-importateurs pour vos commandes',
              icon: Icons.airplanemode_active,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ChatInboxBadge(),
                  GestureDetector(
                    onTap: () => _showNotificationsSheet(context),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: UnreadNotificationBadge(),
                    ),
                  ),
                  const LogoutIconButton(),
                ],
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
            SliverToBoxAdapter(
              child: _buildSmartFilters(sort),
            ),
            if (!isSearching)
              PagedSliverList<Shipment>(
                paginatedList: sortedFeed,
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMd,
                  AppTheme.spaceSm,
                  AppTheme.spaceMd,
                  AppTheme.spaceXxl,
                ),
                emptyState: const _EmptyShipments(),
                itemBuilder: (context, shipment, index) => StaggeredEntrance(
                  delay: Duration(milliseconds: (index % 10) * 40),
                  child: _buildShipmentCard(shipment),
                ),
              )
            else
              PagedSliverList<Shipment>(
                paginatedList: sortedSearch,
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMd,
                  AppTheme.spaceSm,
                  AppTheme.spaceMd,
                  AppTheme.spaceXxl,
                ),
                emptyState: const _NoSearchResults(),
                itemBuilder: (context, shipment, index) => StaggeredEntrance(
                  delay: Duration(milliseconds: (index % 10) * 40),
                  child: _buildShipmentCard(shipment),
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
      builder: (context) => const SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: NotificationsSheet(),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SMART SORTING + SHIPPER CARD
  // --------------------------------------------------------------------------

  Widget _buildSmartFilters(ClientSort current) {
    const options = [
      (sort: ClientSort.none, label: 'Toutes', icon: Icons.tune_rounded),
      (sort: ClientSort.price, label: '💰 Meilleur prix', icon: null),
      (sort: ClientSort.fastest, label: '⚡ Plus rapide', icon: null),
      (sort: ClientSort.topRated, label: '⭐ Top avis', icon: null),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceXs,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: Row(
        children: [
          for (final option in options) ...[
            ChoiceChip(
              label: Text(option.label),
              selected: current == option.sort,
              onSelected: (_) {
                ref.read(clientSortProvider.notifier).state = option.sort;
              },
              showCheckmark: false,
              avatar: _sortAvatar(
                icon: option.icon,
                selected: current == option.sort,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSm),
          ],
        ],
      ),
    );
  }

  List<Shipment> _applySort(List<Shipment> items, ClientSort sort) {
    final list = List<Shipment>.from(items);
    switch (sort) {
      case ClientSort.price:
        list.sort((a, b) {
          final byPrice = a.pricePerKg.compareTo(b.pricePerKg);
          if (byPrice != 0) return byPrice;
          return (b.shipper?.rating ?? 0).compareTo(a.shipper?.rating ?? 0);
        });
        break;
      case ClientSort.fastest:
        list.sort(
          (a, b) => a.arrivalDate.compareTo(b.arrivalDate),
        );
        break;
      case ClientSort.topRated:
        list.sort((a, b) {
          final byRating =
              (b.shipper?.rating ?? 0).compareTo(a.shipper?.rating ?? 0);
          if (byRating != 0) return byRating;
          return a.pricePerKg.compareTo(b.pricePerKg);
        });
        break;
      case ClientSort.none:
        break;
    }
    return list;
  }

  Widget _sortAvatar({
    required IconData? icon,
    required bool selected,
  }) {
    if (icon == null) return const SizedBox.shrink();
    return Icon(icon, size: 18, color: selected ? AppTheme.primaryColor : null);
  }

  Widget _buildShipmentCard(Shipment shipment) {
    final shipper = shipment.shipper;
    return ShipperCard(
      shipperId: shipper?.id ?? shipment.shipperId,
      name: shipper?.user?.fullName ?? 'Expéditeur',
      avatarUrl: shipper?.user?.profilePictureUrl,
      rating: shipper?.rating ?? 0,
      shipmentsCount: shipper?.totalShipments,
      isVerified: shipper?.isVerified ?? false,
      origin: shipment.originCountry,
      destination: shipment.destinationCity,
      flightNumber: shipment.flightNumber,
      availableKg: shipment.remainingWeightKg,
      totalKg: shipment.availableWeightKg,
      pricePerKg: shipment.pricePerKg,
      arrivalDate: shipment.arrivalDate,
      isAvailable: shipment.isActive && !shipment.isFull,
      onTap:
          shipper?.id != null ? () => _openShipperProfile(shipper!.id) : null,
      onBook: () => Navigator.of(context).pushNamed(
        '/booking-wizard',
        arguments: shipment.id,
      ),
      onChat: shipper?.user?.id != null
          ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    counterpartUserId: shipper!.user!.id,
                    counterpartName: shipper.user?.fullName ?? 'Expéditeur',
                    counterpartAvatarUrl: shipper.user?.profilePictureUrl,
                    bookingId: null,
                  ),
                ),
              )
          : null,
    );
  }

  void _openShipperProfile(String shipperId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShipperPublicProfileScreen(shipperId: shipperId),
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
// The search feed now renders the reusable ShipperCard
// (lib/components/shipper_card.dart) instead of a screen-private card.

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
// NOTIFICATIONS BADGE  (shared widgets now live in core/widgets/notification_widgets.dart)
// ============================================================================
