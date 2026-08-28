import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../../core/widgets/booking_acceptance_chip.dart';
import '../../core/widgets/airport_picker_field.dart';
import '../../core/widgets/country_city_picker_field.dart';
import '../../core/widgets/notification_widgets.dart';
import '../../core/widgets/chat_widgets.dart';
import '../../core/widgets/subscription_pack_sheet.dart';
import '../../core/utils/qr_booking.dart';
import '../../components/shipper_card.dart';
import '../../components/workflow_slider.dart';
import '../shipper/shipper_public_profile_screen.dart';
import '../chat/chat_screen.dart';
import '../shared/qr_scan_screen.dart';
import 'delivery_request_screen.dart';
import 'tracking_screen.dart';

/// Smart sort applied to the (server-side filtered) search feed.
enum ClientSort { none, price, fastest, topRated }

final clientSortProvider = StateProvider<ClientSort>((ref) => ClientSort.none);

/// Colis du client **pas encore livrés** (hors annulés) pour la section
/// « Suivi de colis » de l'accueil : chaque colis en cours apparaît avec son
/// avancement ; les colis livrés restent accessibles via « Voir tout »
/// (écran Mes colis). autoDispose → recalculée à chaque retour sur l'accueil.
///
/// Combined with wallet stats to avoid a second identical `getClientBookings`
/// call — single DB fetch for both tracking list and wallet summary.
final activeTrackingBookingsProvider =
    FutureProvider.autoDispose<List<Booking>>((ref) async {
  final clientId = ref.watch(authServiceProvider).currentUserId;
  if (clientId == null) return const [];
  final bookings = await ref
      .read(bookingServiceProvider)
      .getClientBookings(clientId: clientId, limit: 100);
  return bookings
      .where((b) => b.status != 'delivered' && b.status != 'cancelled')
      .toList();
});

/// Portefeuille client : total réglé et restant à payer — computed from the
/// same fetch as `activeTrackingBookingsProvider` via `clientWalletFromBookings`.
final clientWalletProvider =
    FutureProvider.autoDispose<({double paid, double due})>((ref) async {
  final clientId = ref.watch(authServiceProvider).currentUserId;
  if (clientId == null) return (paid: 0.0, due: 0.0);
  final bookings = await ref
      .read(bookingServiceProvider)
      .getClientBookings(clientId: clientId, limit: 100);
  return _computeWallet(bookings);
});

({double paid, double due}) _computeWallet(List<Booking> bookings) {
  var paid = 0.0;
  var due = 0.0;
  for (final b in bookings) {
    if (b.status == 'cancelled') continue;
    final amount = b.allocatedWeightKg * (b.shipment?.pricePerKg ?? 0);
    if (b.paymentStatus == 'paid') {
      paid += amount;
    } else {
      due += amount;
    }
  }
  return (paid: paid, due: due);
}

/// Lazy paged source for active shipments, keyed by the active filters.
final clientShipmentsPagerProvider = StateNotifierProvider.family<
    PaginatedListNotifier<Shipment>,
    PaginatedList<Shipment>,
    ({String? destination, String? origin, String? shipperType})>(
  (ref, params) {
    return createPaginatedNotifier(
      (limit, offset) => ref.read(shipmentServiceProvider).getActiveShipments(
            destinationCity: params.destination,
            originCountry: params.origin,
            shipperType: params.shipperType,
            limit: limit,
            offset: offset,
          ),
      pageSize: 15,
      idOf: (shipment) => shipment.id,
    );
  },
);

/// Lazy paged server-side search source, keyed by the query AND the active
/// shipper-type chip (changer de chip pendant une recherche relance la
/// recherche avec le même filtre que le feed).
final clientSearchPagerProvider = StateNotifierProvider.family<
    PaginatedListNotifier<Shipment>,
    PaginatedList<Shipment>,
    ({String query, String? shipperType})>((ref, params) {
  return createPaginatedNotifier(
    (limit, offset) => ref.read(shipmentServiceProvider).searchShipments(
          query: params.query,
          shipperType: params.shipperType,
          limit: limit,
          offset: offset,
        ),
    pageSize: 15,
    idOf: (shipment) => shipment.id,
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
    final shipperType = ref.read(shipperTypeFilterProvider);
    final key = '$destination|$origin|$shipperType';
    if (key == _lastFilterKey) return;
    _lastFilterKey = key;
    final notifier = ref.read(
      clientShipmentsPagerProvider((
        destination: destination,
        origin: origin,
        shipperType: shipperType,
      )).notifier,
    );
    notifier.loadInitial();
  }

  /// True when [shipment] still qualifies for the current feed filters.
  bool _matchesFeedFilters(Shipment shipment) {
    final destination = ref.read(destinationFilterProvider);
    final origin = ref.read(originFilterProvider);
    final shipperType = ref.read(shipperTypeFilterProvider);
    if (destination != null &&
        !shipment.destinationCity
            .toLowerCase()
            .contains(destination.toLowerCase())) {
      return false;
    }
    if (origin != null &&
        !shipment.originCountry.toLowerCase().contains(origin.toLowerCase())) {
      return false;
    }
    if (shipperType != null) {
      final shipperMatches = shipment.shipper?.isMicroImportateur ==
          (shipperType == 'micro_importateur');
      if (!shipperMatches) return false;
    }
    return true;
  }

  /// Realtime INSERT/UPDATE/DELETE on `shipments`: refetch the touched row
  /// (the payload only carries raw columns, without the embedded shipper) and
  /// patch just that tile instead of reloading the whole feed.
  void _applyShipmentEvent(PostgresChangePayload event) {
    final id = (event.newRecord['id'] ?? event.oldRecord['id']) as String?;
    if (id == null) return;

    final feedNotifier = ref.read(
      clientShipmentsPagerProvider(
        (
          destination: ref.read(destinationFilterProvider),
          origin: ref.read(originFilterProvider),
          shipperType: ref.read(shipperTypeFilterProvider),
        ),
      ).notifier,
    );

    if (event.eventType == PostgresChangeEvent.delete) {
      feedNotifier.removeItem(id);
      _removeFromSearch(id);
      return;
    }

    ref.read(shipmentServiceProvider).getShipmentById(id).then((shipment) {
      if (shipment == null ||
          !shipment.isActive ||
          shipment.isFull ||
          !_matchesFeedFilters(shipment)) {
        feedNotifier.removeItem(id);
      } else {
        feedNotifier.upsertItem(shipment);
      }

      final searchQuery = ref.read(searchQueryProvider).trim().toLowerCase();
      if (searchQuery.isEmpty || shipment == null) return;
      final matchesQuery =
          shipment.originCountry.toLowerCase().contains(searchQuery) ||
              shipment.destinationCity.toLowerCase().contains(searchQuery);
      if (matchesQuery) {
        ref
            .read(clientSearchPagerProvider((
              query: ref.read(searchQueryProvider).trim(),
              shipperType: ref.read(shipperTypeFilterProvider),
            )).notifier)
            .upsertItem(shipment);
      } else {
        _removeFromSearch(id);
      }
    });
  }

  void _removeFromSearch(String id) {
    final searchQuery = ref.read(searchQueryProvider).trim();
    if (searchQuery.isEmpty) return;
    ref
        .read(clientSearchPagerProvider((
          query: searchQuery,
          shipperType: ref.read(shipperTypeFilterProvider),
        )).notifier)
        .removeItem(id);
  }

  /// (Re)load server-side search results when the query or the type chip
  /// changes.
  void _syncSearch() {
    final query = ref.read(searchQueryProvider).trim();
    if (query.isEmpty) return;
    final key = '$query|${ref.read(shipperTypeFilterProvider)}';
    if (key == _lastSearchKey) return;
    _lastSearchKey = key;
    final notifier = ref.read(clientSearchPagerProvider((
      query: query,
      shipperType: ref.read(shipperTypeFilterProvider),
    )).notifier);
    notifier.loadInitial();
  }

  /// Filet de sécurité local : même si le filtre serveur régressait, aucune
  /// offre hors critères ne doit jamais s'afficher. Vérifie le type
  /// d'expéditeur sur les données embarquées de chaque offre, et exclut les
  /// offres « terminées » (arrivée dépassée) ou pleines — un statut encore
  /// `active` en base mais dont la date de vol est passée ne doit jamais être
  /// montré au client.
  bool _passesLocalFilters(Shipment shipment, String? shipperType) {
    if (!shipment.isActive || shipment.isFull) return false;
    if (shipperType != null) {
      final matches = shipment.shipper?.isMicroImportateur ==
          (shipperType == 'micro_importateur');
      if (!matches) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final destination = ref.watch(destinationFilterProvider);
    final origin = ref.watch(originFilterProvider);
    final shipperType = ref.watch(shipperTypeFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final pager = ref.watch(
      clientShipmentsPagerProvider((
        destination: destination,
        origin: origin,
        shipperType: shipperType,
      )),
    );
    final searchPager = ref.watch(clientSearchPagerProvider((
      query: searchQuery.trim(),
      shipperType: shipperType,
    )));
    final activeAds = ref.watch(activeAdsProvider).valueOrNull ?? [];

    final isSearching = searchQuery.trim().isNotEmpty;
    final sort = ref.watch(clientSortProvider);

    // Smart sort applied locally on top of the server-side filters. Keeping
    // the same PaginatedList (via copyWith) preserves infinite scrolling and
    // pull-to-refresh callbacks. Le filtre local du type d'expéditeur est
    // réappliqué en dernier recours : l'UI ne doit jamais montrer une offre
    // hors critères, même si le filtre serveur régressait.
    final sortedFeed = pager.copyWith(
      items: _applySort(
        pager.items.where((s) => _passesLocalFilters(s, shipperType)).toList(),
        sort,
      ),
    );
    final sortedSearch = searchPager.copyWith(
      items: _applySort(
        searchPager.items
            .where((s) => _passesLocalFilters(s, shipperType))
            .toList(),
        sort,
      ),
    );

    // Live refresh: a newly published shipment appears in the feed without a
    // manual pull-to-refresh. Only the touched tile is patched in place.
    ref.listen(
      tableChangesProvider(('shipments', null, null)),
      (previous, next) {
        if (next.hasValue) {
          _applyShipmentEvent(next.requireValue);
        }
      },
    );

    // Re-sync the pager when the origin/destination chips change. (Provider
    // changes rebuild the widget but do NOT trigger didChangeDependencies, so
    // the pager used to keep showing the previous filter's results.)
    ref.listen(destinationFilterProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncPager());
    });
    ref.listen(originFilterProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncPager());
    });
    ref.listen(shipperTypeFilterProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncPager();
        _syncSearch();
      });
    });

    // Deterministic reload after a booking is created (realtime is the live
    // path, but an event can be missed while the booking wizard is open).
    ref.listen(shipmentsFeedRefreshTickProvider, (_, next) {
      if (next == 0) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(
              clientShipmentsPagerProvider((
                destination: destination,
                origin: origin,
                shipperType: shipperType,
              )).notifier,
            )
            .refresh();
      });
    });

    // Live refresh du portefeuille et du suivi : tout changement sur bookings
    // (paiement, statut, nouvelle réservation) invalide les providers.
    ref.listen(
      tableChangesProvider(('bookings', null, null)),
      (previous, next) {
        if (!next.hasValue) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(clientWalletProvider);
          ref.invalidate(activeTrackingBookingsProvider);
        });
      },
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          if (isSearching) {
            await ref
                .read(clientSearchPagerProvider((
                  query: searchQuery.trim(),
                  shipperType: shipperType,
                )).notifier)
                .refresh();
            return;
          }
          await ref
              .read(
                clientShipmentsPagerProvider((
                  destination: destination,
                  origin: origin,
                  shipperType: shipperType,
                )).notifier,
              )
              .refresh();
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // if (currentAd != null)
            //   AdSliverHeader(
            //     ad: currentAd,
            //     trailing: Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         const ChatInboxBadge(),
            //         IconButton(
            //           onPressed: () =>
            //               ref.read(navigationIndexProvider.notifier).state = 1,
            //           tooltip: 'Mes colis',
            //           icon: const Icon(Icons.connecting_airports_rounded),
            //         ),
            //         IconButton(
            //           onPressed: () => _openQrScanner(context),
            //           tooltip: 'Scanner un colis',
            //           icon: const Icon(Icons.qr_code_scanner_rounded),
            //         ),
            //         GestureDetector(
            //           onTap: () => _showNotificationsSheet(context),
            //           child: const Padding(
            //             padding: EdgeInsets.only(right: 8),
            //             child: UnreadNotificationBadge(),
            //           ),
            //         ),
            //         const LogoutIconButton(),
            //       ],
            //     ),
            //   )
            // else
            CompactSliverHeader(
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
                ],
              ),
            ),
            // Carrousel des pubs actives : toutes les bannières défilent.
            if (activeAds.isNotEmpty)
              SliverToBoxAdapter(
                child: AdBannerCarousel(ads: activeAds),
              ),
            SliverToBoxAdapter(
              child: _buildGreeting(currentUser),
            ),
            const SliverToBoxAdapter(
              child: _ClientWalletCard(),
            ),
            const SliverToBoxAdapter(
              child: _HomeTrackingCard(),
            ),
            SliverToBoxAdapter(
              child: _buildQrScannerCard(context),
            ),
            SliverToBoxAdapter(
              child: _buildDeliveryCard(context),
            ),
            SliverToBoxAdapter(
              child: _buildSubscriptionCard(context),
            ),
            SliverToBoxAdapter(
              child: _buildHowItWorks(),
            ),
            SliverToBoxAdapter(
              child: _buildSearchBar(),
            ),
            SliverToBoxAdapter(
              child: _buildFilters(),
            ),
            SliverToBoxAdapter(
              child: _buildTypeFilters(),
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

  Widget _buildHowItWorks() {
    return const Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spaceMd,
        right: AppTheme.spaceMd,
        top: AppTheme.spaceSm,
      ),
      child: WorkflowSlider(
        height: 270,
        slides: [
          WorkflowSlide(
            title: '1. Trouvez votre offre',
            subtitle: 'Recherchez parmi les micro-importateurs vérifiés',
            icon: Icons.search_rounded,
            steps: [
              'Filtrez par destination, origine et prix',
              'Choisissez une offre active (poids disponible)',
              'Le poids est réservé dès la réservation',
            ],
          ),
          WorkflowSlide(
            title: '2. Réservez votre colis',
            subtitle: 'Produit, photos et poids demandé',
            icon: Icons.inventory_2_rounded,
            steps: [
              'Décrivez le produit (0,1 à 50 kg)',
              'Ajoutez des photos du produit',
              'Paiement : Espèces, Virement, CCP, Chargily ou Stripe',
            ],
            gradient: AppTheme.infoGradient,
          ),
          WorkflowSlide(
            title: '3. Suivez votre colis',
            subtitle: '8 étapes en temps réel, DHL-style',
            icon: Icons.timeline_rounded,
            steps: [
              'De la prise en charge à la livraison',
              'Preuve photo à la livraison',
              'Confirmez la réception et notez l\'expéditeur',
            ],
            gradient: AppTheme.successGradient,
          ),
        ],
      ),
    );
  }

  Widget _buildQrScannerCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceSm,
        AppTheme.spaceMd,
        0,
      ),
      child: InkWell(
        onTap: () => _openQrScanner(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryDark,
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.shadowMd,
          ),
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scanner un colis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Scannez le QR code d\'un colis pour confirmer la reception.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceSm,
        AppTheme.spaceMd,
        0,
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DeliveryRequestScreen()),
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppTheme.infoGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.shadowMd,
          ),
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demande de livraison',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Publiez une demande : décrivez votre produit '
                      'et les expéditeurs vous proposeront un prix.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceSm,
        AppTheme.spaceMd,
        0,
      ),
      child: Consumer(
        builder: (context, ref, _) {
          final userId = ref.watch(authServiceProvider).currentUserId;
          if (userId == null) return const SizedBox.shrink();

          final subAsync = ref.watch(
            deliverySubscriptionProvider(
                (userId: userId, role: 'client')),
          );

          return subAsync.when(
            data: (sub) {
              if (sub != null && sub.isActive) {
                final daysLeft =
                    sub.expiresAt.difference(DateTime.now()).inDays;
                return InkWell(
                  onTap: () =>
                      _showSubscriptionSheet(context, ref, userId),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusLg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                          color: Colors.green.shade200, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Colors.green.shade600, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Abonnement actif',
                                style: AppTheme.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              Text(
                                'Expire dans $daysLeft jour(s) — appuyez pour changer',
                                style: AppTheme.caption.copyWith(
                                  color: Colors.green.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.swap_horiz_rounded,
                            color: Colors.green.shade500, size: 20),
                      ],
                    ),
                  ),
                );
              }
              // Abonnement en attente de validation par le fondateur
              if (sub != null && sub.status == 'pending') {
                return InkWell(
                  onTap: () =>
                      _showSubscriptionSheet(context, ref, userId),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusLg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                          color: Colors.amber.shade200, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_top_rounded,
                            color: Colors.amber.shade700, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Validation en attente',
                                style: AppTheme.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                              Text(
                                'Approuvé dès validation du fondateur — '
                                'appuyez pour changer de pack',
                                style: AppTheme.caption.copyWith(
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.swap_horiz_rounded,
                            color: Colors.amber.shade500, size: 20),
                      ],
                    ),
                  ),
                );
              }
              // Pas d'abonnement → card CTA
              return InkWell(
                onTap: () =>
                    _showSubscriptionSheet(context, ref, userId),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusLg),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade600,
                        Colors.orange.shade500,
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: AppTheme.shadowMd,
                  ),
                  padding:
                      const EdgeInsets.all(AppTheme.spaceLg),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color:
                              Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.card_membership_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMd),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Activer l\'abonnement',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Accédez aux demandes de livraison '
                              '(client)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd, AppTheme.spaceSm, AppTheme.spaceMd, 0,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                onTap: () => _showSubscriptionSheet(context, ref, userId),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade600, Colors.orange.shade500],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: AppTheme.shadowMd,
                  ),
                  padding: const EdgeInsets.all(AppTheme.spaceLg),
                  child: Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.card_membership_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: AppTheme.spaceMd),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Activer l\'abonnement',
                                style: TextStyle(color: Colors.white,
                                    fontSize: 16, fontWeight: FontWeight.w800)),
                            SizedBox(height: 4),
                            Text('Choisissez un pack d\'abonnement',
                                style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSubscriptionSheet(
      BuildContext context, WidgetRef ref, String userId) {
    ref.invalidate(subscriptionPacksProvider('client'));
    final sub = ref
        .read(deliverySubscriptionProvider((userId: userId, role: 'client')))
        .valueOrNull;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubscriptionPackSheet(
        userId: userId,
        role: 'client',
        currentSubscription: sub,
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
                  Icons.flight_takeoff_rounded,
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

  /// Filtre par type d'expéditeur (voyageur ordinaire / micro-importateur).
  Widget _buildTypeFilters() {
    final selected = ref.watch(shipperTypeFilterProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceXs,
        AppTheme.spaceMd,
        AppTheme.spaceXs,
      ),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Tous'),
            selected: selected == null,
            showCheckmark: false,
            avatar: const Icon(Icons.group_rounded, size: 18),
            onSelected: (_) =>
                ref.read(shipperTypeFilterProvider.notifier).state = null,
          ),
          const SizedBox(width: AppTheme.spaceSm),
          ChoiceChip(
            label: const Text('Voyageurs'),
            // Valeur stockée en base : shipper_type = 'voyageur_ordinaire'.
            selected: selected == 'voyageur_ordinaire',
            showCheckmark: false,
            avatar: const Icon(Icons.flight_takeoff_rounded, size: 18),
            onSelected: (_) => ref
                .read(shipperTypeFilterProvider.notifier)
                .state = 'voyageur_ordinaire',
          ),
          const SizedBox(width: AppTheme.spaceSm),
          ChoiceChip(
            label: const Text('Micro-importateurs'),
            selected: selected == 'micro_importateur',
            showCheckmark: false,
            avatar: const Icon(Icons.storefront_rounded, size: 18),
            onSelected: (_) => ref
                .read(shipperTypeFilterProvider.notifier)
                .state = 'micro_importateur',
          ),
        ],
      ),
    );
  }

  void _showDestinationPicker() async {
    final result = await CountryCityPickerField.showPicker(context);
    if (result != null) {
      ref.read(destinationFilterProvider.notifier).state = result;
    }
  }

  void _showOriginPicker() async {
    final result = await AirportPickerField.showPicker(context);
    if (result != null) {
      ref.read(originFilterProvider.notifier).state = result;
    }
  }

  void _openQrScanner(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const QrScanScreen(mode: QrScanMode.clientReceipt),
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
          (a, b) => (a.arrivalDate ?? a.departureDate)
              .compareTo(b.arrivalDate ?? b.departureDate),
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
    final settings = ref.watch(platformSettingsProvider).valueOrNull;
    final commissionPercent = settings?.commissionPercent ?? 5.0;
    final commission = shipment.pricePerKg * commissionPercent / 100;
    return ShipperCard(
      shipperId: shipper?.id ?? shipment.shipperId,
      name: shipper?.user?.fullName ?? 'Expéditeur',
      avatarUrl: shipper?.user?.profilePictureUrl,
      rating: shipper?.rating ?? 0,
      shipmentsCount: shipper?.totalShipments,
      isVerified: shipper?.isVerified ?? false,
      isMicroImportateur: shipper?.isMicroImportateur ?? false,
      origin: shipment.originCountry,
      destination: shipment.arrivalAirport ?? shipment.destinationCity,
      destinationCityLabel: (shipment.arrivalAirport != null &&
              shipment.arrivalAirport!.isNotEmpty)
          ? shipment.destinationCity
          : null,
      airline: shipment.airline,
      flightNumber: shipment.flightNumber,
      availableKg: shipment.remainingWeightKg,
      totalKg: shipment.availableWeightKg,
      pricePerKg: shipment.pricePerKg,
      clientPricePerKg: shipment.pricePerKg + commission,
      arrivalDate: shipment.arrivalDate,
      departureDate: shipment.departureDate,
      isAvailable: shipment.isActive && !shipment.isFull,
      // Le tap sur la card ouvre le DÉTAIL de l'offre — la réservation se
      // fait uniquement via le bouton « Réserver » (ou l'écran détail).
      onTap: () => Navigator.of(context).pushNamed(
        '/offer-detail',
        arguments: shipment.id,
      ),
      onAvatarTap:
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
      onShare: () => ref
          .read(offerShareServiceProvider)
          .shareOffer(context, shipment),
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

/// Carte « Portefeuille » de l'accueil client : total réglé, restant à payer,
/// un appui ouvre la liste des colis (Mes colis) pour le détail par commande.
class _ClientWalletCard extends ConsumerWidget {
  const _ClientWalletCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(clientWalletProvider);
    final settings = ref.watch(platformSettingsProvider);
    final currency =
        settings.valueOrNull?.defaultCurrency ?? AppConstants.defaultCurrency;
    final data = wallet.valueOrNull ?? (paid: 0.0, due: 0.0);

    return WalletCard(
      title: 'Portefeuille',
      mainLabel: 'Total dépensé',
      mainValue: '${data.paid.toStringAsFixed(0)} $currency',
      badgeLabel: data.due > 0
          ? 'À payer : ${data.due.toStringAsFixed(0)} $currency'
          : 'Tout est réglé',
      badgePositive: data.due <= 0,
      onTap: () => Navigator.of(context).pushNamed('/my-parcels'),
    );
  }
}

/// Section d'accueil « Suivi de colis » : liste des colis **pas encore
/// livrés**, chacun avec son avancement ; un appui ouvre le suivi détaillé,
/// « Voir tout » ouvre la liste complète (écran Mes colis, timelines incluses).
class _HomeTrackingCard extends ConsumerWidget {
  const _HomeTrackingCard();

  static const int _maxRows = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(activeTrackingBookingsProvider);

    // Live refresh : création / changement de statut d'une commande → la
    // section se met à jour sans attendre un pull-to-refresh.
    ref.listen(
      tableChangesProvider(('bookings', null, null)),
      (previous, next) {
        if (!next.hasValue) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(activeTrackingBookingsProvider);
        });
      },
    );

    return bookingsAsync.maybeWhen(
      data: (bookings) {
        if (bookings.isEmpty) return const SizedBox.shrink();
        final extra = bookings.length - _maxRows;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd,
            AppTheme.spaceSm,
            AppTheme.spaceMd,
            0,
          ),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AnimatedIconDot(
                      icon: Icons.local_shipping_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: AppTheme.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Suivi de colis', style: AppTheme.h3),
                          Text(
                            '${bookings.length} '
                            '${bookings.length == 1 ? 'colis en cours' : 'colis en cours'}',
                            style: AppTheme.caption,
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/my-parcels'),
                      icon: const Icon(Icons.list_rounded, size: 18),
                      label: const Text('Voir tout'),
                    ),
                  ],
                ),
                ...bookings.take(_maxRows).map(
                      (b) => _ParcelProgressRow(booking: b),
                    ),
                if (extra > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spaceXs),
                    child: Text(
                      '+ $extra autre${extra > 1 ? 's' : ''} colis en cours — '
                      '« Voir tout » pour la liste complète',
                      style: AppTheme.caption,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Une ligne par colis en cours : produit, N° de suivi, statut courant et
/// barre de progression. Un appui ouvre le suivi détaillé du colis.
class _ParcelProgressRow extends ConsumerWidget {
  final Booking booking;

  const _ParcelProgressRow({required this.booking});

  static const int _stageCount = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(trackingHistoryProvider(booking.id)).valueOrNull ??
        const <ShipmentTracking>[];
    final latest = events.isEmpty ? null : events.last;
    final progress =
        (TrackingScreen.stageIndex(latest?.status ?? 'order_processed') + 1) /
            _stageCount;

    return InkWell(
      onTap: () =>
          Navigator.of(context).pushNamed('/tracking', arguments: booking.id),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (latest != null)
                  Text(
                    TrackingScreen.statusLabel(latest.status),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.infoColor,
                    ),
                  ),
                const SizedBox(width: AppTheme.spaceXs),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppTheme.textSecondaryColor,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXs),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: AppTheme.surfaceMuted,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                if (booking.canSeeTracking)
                  Text(
                    'N° ${booking.trackingNumber?.isNotEmpty ?? false ? booking.trackingNumber : QrBookingPayload.refCodeFor(booking.id)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppTheme.primaryDark,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Align(
              alignment: Alignment.centerLeft,
              child: BookingAcceptanceChip(booking: booking),
            ),
          ],
        ),
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
        Icon(Icons.flight_takeoff_outlined,
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
