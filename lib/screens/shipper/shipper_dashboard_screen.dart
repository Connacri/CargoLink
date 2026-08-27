import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/utils/profile_navigation.dart';
import '../../core/widgets/airport_picker_field.dart';
import '../../core/widgets/country_city_picker_field.dart';
import '../../core/widgets/ui_kit.dart';
import '../../core/widgets/notification_widgets.dart';
import '../../core/widgets/chat_widgets.dart';
import '../shared/qr_scan_screen.dart';
import 'delivery_browse_screen.dart';
import 'shipper_stats_detail_screen.dart';
import 'shipper_booking_detail_screen.dart';
import 'shipper_finance_screen.dart';
import 'shipper_orders_screen.dart';

// ============================================================================
// PAGINATED PROVIDERS (local to this file)
// ============================================================================

final shipperShipmentsPagerProvider = StateNotifierProvider.family<
    PaginatedListNotifier<Shipment>, PaginatedList<Shipment>, String>(
  (ref, shipperId) {
    return createPaginatedNotifier(
      (limit, offset) => ref.read(shipmentServiceProvider).getShipperShipments(
          shipperId: shipperId, limit: limit, offset: offset),
      pageSize: 15,
    );
  },
);

final shipperShipmentBookingsPagerProvider = StateNotifierProvider.family<
    PaginatedListNotifier<Booking>, PaginatedList<Booking>, String>(
  (ref, shipmentId) {
    return createPaginatedNotifier(
      (limit, offset) => ref.read(shipmentBookingsProvider((
        shipmentId: shipmentId,
        limit: limit,
        offset: offset,
      )).future),
      pageSize: 15,
    );
  },
);

// ============================================================================
// SHIPPER DASHBOARD
// ============================================================================

class ShipperDashboardScreen extends ConsumerStatefulWidget {
  const ShipperDashboardScreen({super.key});

  @override
  ConsumerState<ShipperDashboardScreen> createState() =>
      _ShipperDashboardScreenState();
}

class _ShipperDashboardScreenState
    extends ConsumerState<ShipperDashboardScreen> {
  static const _statusOptions = [
    (label: 'Toutes', value: null),
    (label: 'Actives', value: 'active'),
    (label: 'Terminées', value: 'completed'),
    (label: 'Annulées', value: 'cancelled'),
  ];

  final _scrollController = ScrollController();
  String? _statusFilter;
  String _lastShipperId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPager());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Never touch a pager provider while the widget tree is building
    // (Riverpod throws and leaves the pager stuck loading). Run post-frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPager());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// (Re)loads the first page whenever the shipper id changes.
  void _syncPager() {
    final shipperId = ref.read(currentShipperProvider).valueOrNull?.id;
    if (shipperId == null || shipperId == _lastShipperId) return;
    _lastShipperId = shipperId;
    ref.read(shipperShipmentsPagerProvider(shipperId).notifier).loadInitial();
    ref.read(shipperBookingsPagerProvider(shipperId).notifier).loadInitial();
  }

  void _onStatusSelected(String? status) {
    if (status == _statusFilter) return;
    setState(() => _statusFilter = status);
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: NotificationsSheet(
            onBookingTap: (bookingId) => _openBooking(context, bookingId),
          ),
        ),
      ),
    );
  }

  void _openQrScanner(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const QrScanScreen(mode: QrScanMode.shipperCollect),
      ),
    );
  }

  void _openBooking(BuildContext context, String bookingId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShipperBookingDetailScreen(bookingId: bookingId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shipper = ref.watch(currentShipperProvider);

    // Robust initial load: whenever the shipper identity resolves (e.g. right
    // after a sign-in), (re)load the first page of the shipments pager. This
    // covers the case where the FutureProvider is still loading when
    // initState/didChangeDependencies run, so published offers always appear.
    ref.listen(currentShipperProvider, (previous, next) {
      final id = next.valueOrNull?.id;
      if (id != null && id != _lastShipperId) {
        _lastShipperId = id;
        ref.read(shipperShipmentsPagerProvider(id).notifier).loadInitial();
        ref.read(shipperBookingsPagerProvider(id).notifier).loadInitial();
      }
    });

    // Filet de sécurité temps réel : si un événement Postgres Changes a été
    // manqué (socket coupé, app en arrière-plan), le retour sur l'onglet
    // recharge la première page des deux pagers + les cartes de stats, comme
    // le fait l'écran « Mes commandes » côté client.
    ref.listen<int>(navigationIndexProvider, (prev, next) {
      if (next == 0 && prev != 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final id = ref.read(currentShipperProvider).valueOrNull?.id;
          if (id == null || id != _lastShipperId) return;
          ref.read(shipperShipmentsPagerProvider(id).notifier).loadInitial();
          ref.read(shipperBookingsPagerProvider(id).notifier).loadInitial();
          ref.invalidate(shipperStatsProvider(id));
          ref.invalidate(shipperEarningsProvider(id));
        });
      }
    });

    return shipper.when(
      data: (shipperData) {
        if (shipperData == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!shipperData.isVerified) {
          return _buildNotVerified(shipperData);
        }
        return _buildDashboard(shipperData);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Erreur: $e'))),
    );
  }

  Widget _buildNotVerified(Shipper? shipper) {
    final isRejected = shipper?.isRejected ?? false;
    final title = isRejected ? 'Dossier rejeté' : 'Vérification en attente';
    final message = isRejected
        ? shipper?.rejectionReason ??
            'Veuillez soumettre à nouveau vos documents.'
        : 'Un administrateur doit valider votre identité avant '
            'de pouvoir publier des offres de transport.';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          top: false,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              child: GlassCard(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedIconDot(
                      icon: isRejected
                          ? Icons.error_outline_rounded
                          : Icons.verified_user_outlined,
                      color: isRejected
                          ? AppTheme.errorColor
                          : AppTheme.warningColor,
                      size: 32,
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTheme.h3,
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTheme.bodySecondary,
                    ),
                    const SizedBox(height: AppTheme.spaceLg),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context)
                          .pushNamed('/shipper-registration'),
                      icon: Icon(
                        isRejected
                            ? Icons.replay_rounded
                            : Icons.assignment_rounded,
                      ),
                      label: Text(
                        isRejected ? 'Soumettre à nouveau' : 'Voir mon dossier',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(Shipper shipper) {
    final pager = ref.watch(shipperShipmentsPagerProvider(shipper.id));

    // Live refresh: whenever a shipment of this shipper changes on the server
    // (e.g. a client books and consumes kg), reload the list and stats so the
    // remaining weight updates instantly.
    ref.listen(
      tableChangesProvider(('shipments', 'shipper_id', shipper.id)),
      (previous, next) {
        if (next.hasValue) {
          ref
              .read(shipperShipmentsPagerProvider(shipper.id).notifier)
              .refresh();
          ref.invalidate(shipperStatsProvider(shipper.id));
          ref.invalidate(shipperEarningsProvider(shipper.id));
        }
      },
    );

    final filtered = _statusFilter == null
        ? null
        : pager.items.where((s) => s.status == _statusFilter).toList();

    // Carrousel des pubs actives ciblées « Expéditeurs », sous la barre fine.
    final activeAds = ref.watch(shipperActiveAdsProvider).valueOrNull ?? [];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(shipperStatsProvider(shipper.id));
          ref.invalidate(shipperEarningsProvider(shipper.id));
          await ref
              .read(shipperShipmentsPagerProvider(shipper.id).notifier)
              .refresh();
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CompactSliverHeader(
              title: 'Tableau de bord',
              subtitle:
                  '${shipper.user?.fullName ?? 'Espace expéditeur'}  •  ★ ${shipper.ratingDisplay}'
                  '${shipper.isMicroImportateur ? '  •  Micro-importateur' : ''}',
              icon: Icons.flight_takeoff_rounded,
              trailing: _headerTrailing(
                canAdvertise: shipper.isMicroImportateur,
              ),
            ),
            if (activeAds.isNotEmpty)
              SliverToBoxAdapter(
                child: AdBannerCarousel(ads: activeAds),
              ),
            SliverToBoxAdapter(
              child: _buildBookingsHeader(shipper.id),
            ),
            ..._buildBookingsList(shipper.id),
            SliverToBoxAdapter(
              child: _buildStats(shipper),
            ),
            SliverToBoxAdapter(
              child: _buildPublishAndScan(shipper),
            ),
            SliverToBoxAdapter(
              child: _buildSubscriptionBanner(shipper),
            ),
            SliverToBoxAdapter(
              child: _buildActiveOrdersCard(shipper.id),
            ),
            SliverToBoxAdapter(
              child: _buildSectionHeader(shipper.id),
            ),
            SliverToBoxAdapter(
              child: _buildStatusFilters(),
            ),
            if (filtered == null)
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
                  child: _ShipmentMiniCard(shipment: shipment),
                ),
              )
            else if (filtered.isEmpty)
              const SliverToBoxAdapter(child: _EmptyFilteredShipments())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMd,
                  AppTheme.spaceSm,
                  AppTheme.spaceMd,
                  AppTheme.spaceXxl,
                ),
                sliver: SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => StaggeredEntrance(
                    delay: Duration(milliseconds: (index % 10) * 40),
                    child: _ShipmentMiniCard(shipment: filtered[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _headerTrailing({required bool canAdvertise}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canAdvertise)
          IconButton(
            tooltip: 'Mes publicités',
            icon: const Icon(Icons.campaign_outlined, color: Colors.white),
            onPressed: () => Navigator.of(context).pushNamed('/my-ads'),
          ),
        const ChatInboxBadge(),
        GestureDetector(
          onTap: () => _showNotificationsSheet(context),
          child: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: UnreadNotificationBadge(),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(Shipper shipper) {
    final stats = ref.watch(shipperStatsProvider(shipper.id));
    final earnings = ref.watch(shipperEarningsProvider(shipper.id));

    final revenue = earnings.valueOrNull ?? 0.0;
    final totalOffers =
        (stats.valueOrNull?['total_shipments'] as num?)?.toInt() ?? 0;
    final totalBookings =
        (stats.valueOrNull?['total_bookings'] as num?)?.toInt() ?? 0;
    final active =
        (stats.valueOrNull?['active_shipments'] as num?)?.toInt() ?? 0;

    void open(ShipperStatsDetailType type) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShipperStatsDetailScreen(
            shipperId: shipper.id,
            type: type,
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd,
            AppTheme.spaceMd,
            AppTheme.spaceMd,
            AppTheme.spaceSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Chiffre d\'affaires',
                  value: _formatCompact(revenue),
                  icon: Icons.payments_outlined,
                  color: AppTheme.accentColor,
                  onTap: () => open(ShipperStatsDetailType.revenue),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: _StatCard(
                  label: 'Offres',
                  value: '$totalOffers',
                  icon: Icons.flight_takeoff_rounded,
                  color: AppTheme.primaryColor,
                  onTap: () => open(ShipperStatsDetailType.shipments),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd,
            0,
            AppTheme.spaceMd,
            AppTheme.spaceSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Commandes',
                  value: '$totalBookings',
                  icon: Icons.receipt_long_rounded,
                  color: AppTheme.infoColor,
                  onTap: () => open(ShipperStatsDetailType.bookings),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: _StatCard(
                  label: 'Offres actives',
                  value: '$active',
                  icon: Icons.play_circle_outline_rounded,
                  color: Colors.amber,
                  onTap: () => open(ShipperStatsDetailType.active),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd,
            0,
            AppTheme.spaceMd,
            AppTheme.spaceSm,
          ),
          child: _FinanceSummaryStrip(shipperId: shipper.id),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String shipperId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceSm,
        AppTheme.spaceMd,
        0,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('Mes offres', style: AppTheme.h2),
          ),
          TextButton.icon(
            onPressed: () => _showPublishDialog(shipperId),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Publier'),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PUBLIER + SCANNER — large "Publier une offre" button with a big QR scanner
  // card below it, both taking the place of the two app-bar icons.
  // --------------------------------------------------------------------------

  Widget _buildPublishAndScan(Shipper shipper) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceSm,
        AppTheme.spaceMd,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Large "Publier une offre" button
          InkWell(
            onTap: () => _showPublishDialog(shipper.id),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Ink(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: AppTheme.spaceMd,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Publier une offre',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          // Big QR scanner card
          InkWell(
            onTap: () => _openQrScanner(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Ink(
              decoration: BoxDecoration(
                gradient: AppTheme.darkGradient,
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
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
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
                          'Scanner un colis',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Scannez le QR code du colis pour confirmer la '
                          'collecte ou la remise au client.',
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
          const SizedBox(height: AppTheme.spaceMd),
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DeliveryBrowseScreen()),
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
                      Icons.delivery_dining_outlined,
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
                          'Demandes de livraison',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Consultez les demandes des clients et proposez '
                          'votre prix pour les livrer.',
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
          if (shipper.isMicroImportateur) ...[
            const SizedBox(height: AppTheme.spaceMd),
            // Big "Publier une publicité" card — réservée aux micro-
            // importateurs : la soumission passe par la validation d'un
            // admin/super admin puis le règlement des frais.
            InkWell(
              onTap: () => Navigator.of(context).pushNamed('/my-ads'),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppTheme.warningGradient,
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
                      Icons.campaign_rounded,
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
                          'Publier une publicité',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sponsorisez votre activité : votre bannière sera '
                          'affichée aux clients après validation de '
                          'l\u2019administration et règlement des frais.',
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
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // ABONNEMENT — bannière de souscription pour les expéditeurs non abonnés
  // --------------------------------------------------------------------------

  Widget _buildSubscriptionBanner(Shipper shipper) {
    final sub = ref.watch(deliverySubscriptionProvider((userId: shipper.userId, role: 'shipper')));
    return sub.when(
      data: (activeSub) {
        if (activeSub != null) return const SizedBox.shrink();
        final settings = ref.watch(platformSettingsProvider);
        final price = settings.valueOrNull?.deliveryShipperSubscriptionPrice ?? 0;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd,
            AppTheme.spaceSm,
            AppTheme.spaceMd,
            0,
          ),
          child: GlassCard(
            child: Row(
              children: [
                const AnimatedIconDot(
                  icon: Icons.card_membership_rounded,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: AppTheme.spaceMd),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Abonnement livraison', style: AppTheme.h3),
                      Text(
                        'Activez un abonnement pour proposer des prix '
                        'et consulter les demandes de livraison.',
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showSubscriptionSheet(price),
                  child: const Text('Activer'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _showSubscriptionSheet(double price) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activer l\'abonnement'),
        content: Text(
          'Prix: ${price.toStringAsFixed(0)} DZD\n'
          'Durée: 30 jours\n\n'
          'Votre demande sera envoyée au fondateur pour validation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Demander l\'activation'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    
    try {
      final userId = ref.read(authServiceProvider).currentUserId;
      if (userId == null) throw Exception('Non authentifié');
      final settings = ref.read(platformSettingsProvider).valueOrNull;
      await ref.read(deliveryServiceProvider).purchaseSubscription(
        userId: userId,
        role: 'shipper',
        price: settings?.deliveryShipperSubscriptionPrice ?? 0,
        durationDays: settings?.deliverySubscriptionDurationDays ?? 30,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande envoyée au fondateur pour validation.'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    }
  }

  // --------------------------------------------------------------------------
  // COMMANDES EN COURS — carte de synthèse des commandes reçues pas encore
  // livrées. Un appui ouvre la liste complète avec frises de suivi et
  // détails (ShipperOrdersInProgressScreen).
  // --------------------------------------------------------------------------

  Widget _buildActiveOrdersCard(String shipperId) {
    final pager = ref.watch(shipperBookingsPagerProvider(shipperId));
    final activeOrders = pager.items
        .where((b) => b.status != 'delivered' && b.status != 'cancelled')
        .toList();
    if (activeOrders.isEmpty) return const SizedBox.shrink();

    final pending =
        activeOrders.where((b) => b.status == 'pending').length;
    final confirmed =
        activeOrders.where((b) => b.status == 'confirmed').length;
    final inTransit = activeOrders
        .where((b) =>
            b.status != 'pending' &&
            b.status != 'confirmed' &&
            b.status != 'delivered' &&
            b.status != 'cancelled')
        .length;
    final totalValue =
        activeOrders.fold(0.0, (sum, b) => sum + b.totalPrice);

    final departureDates = activeOrders
        .map((b) => b.shipment?.departureDate)
        .whereType<DateTime>()
        .toList()
      ..sort();
    final nextDeparture = departureDates.isNotEmpty ? departureDates.first : null;

    void navigate() => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ShipperOrdersInProgressScreen(shipperId: shipperId),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceSm,
        AppTheme.spaceMd,
        0,
      ),
      child: GlassCard(
        onTap: navigate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AnimatedIconDot(
                  icon: Icons.local_shipping_rounded,
                  color: AppTheme.infoColor,
                ),
                const SizedBox(width: AppTheme.spaceSm),
                const Expanded(
                  child: Text('Commandes en cours', style: AppTheme.h3),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceSm,
                    vertical: AppTheme.spaceXs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.infoColor.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusXs),
                  ),
                  child: Text(
                    '${activeOrders.length}',
                    style: AppTheme.label.copyWith(
                      color: AppTheme.infoColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Wrap(
              spacing: AppTheme.spaceSm,
              runSpacing: AppTheme.spaceXs,
              children: [
                if (pending > 0)
                  _statusChip(
                    label: '$pending en attente',
                    color: AppTheme.warningColor,
                  ),
                if (confirmed > 0)
                  _statusChip(
                    label: '$confirmed confirmée${confirmed > 1 ? 's' : ''}',
                    color: AppTheme.accentColor,
                  ),
                if (inTransit > 0)
                  _statusChip(
                    label: '$inTransit en transit',
                    color: AppTheme.infoColor,
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                Icon(
                  Icons.payments_rounded,
                  size: 16,
                  color: AppTheme.accentColor.withValues(alpha: 0.8),
                ),
                const SizedBox(width: AppTheme.spaceXs),
                Text(
                  '${totalValue.toStringAsFixed(0)} DA',
                  style: AppTheme.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                const Text(
                  'valeur totale',
                  style: AppTheme.caption,
                ),
              ],
            ),
            if (nextDeparture != null) ...[
              const SizedBox(height: AppTheme.spaceXs),
              Row(
                children: [
                  const Icon(
                    Icons.flight_takeoff_rounded,
                    size: 16,
                    color: AppTheme.textMutedColor,
                  ),
                  const SizedBox(width: AppTheme.spaceXs),
                  Text(
                    'Prochain départ : ${_formatDepartureDate(nextDeparture)}',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppTheme.spaceSm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: navigate,
                icon: const Icon(Icons.timeline_rounded, size: 18),
                label: const Text('Suivre'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSm,
        vertical: AppTheme.spaceXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.spaceXs),
          Text(
            label,
            style: AppTheme.label.copyWith(
              color: AppTheme.textPrimaryColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDepartureDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.isNegative) return 'passé';
    if (diff.inDays == 0) return 'aujourd\'hui';
    if (diff.inDays == 1) return 'demain';
    if (diff.inDays < 7) return 'dans ${diff.inDays} jours';
    return '${date.day}/${date.month}/${date.year}';
  }

  // --------------------------------------------------------------------------
  // COMMANDES REÇUES — the received-orders feed on the dashboard. Shows every
  // booking (confirmed and not yet) with client + details, clickable to the
  // ShipperBookingDetailScreen. Live-updates when a client books or the
  // booking status changes.
  // --------------------------------------------------------------------------

  Widget _buildBookingsHeader(String shipperId) {
    final pager = ref.watch(shipperBookingsPagerProvider(shipperId));
    final pending = pager.items.where((b) => b.status == 'pending').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        0,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('Commandes reçues', style: AppTheme.h2),
          ),
          if (pending > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppTheme.warningColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$pending en attente',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ShipperStatsDetailScreen(
                  shipperId: shipperId,
                  type: ShipperStatsDetailType.bookings,
                ),
              ),
            ),
            icon: const Icon(Icons.chevron_right_rounded, size: 18),
            label: const Text('Historique'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBookingsList(String shipperId) {
    final pager = ref.watch(shipperBookingsPagerProvider(shipperId));

    // Live refresh: a new booking or a status change by the client/shpper
    // immediately updates the received-orders feed in place.
    ref.listen(
      tableChangesProvider(('bookings', null, null)),
      (previous, next) {
        final event = next.valueOrNull;
        if (event == null) return;
        final notifier =
            ref.read(shipperBookingsPagerProvider(shipperId).notifier);
        final id = event.eventType == PostgresChangeEvent.delete
            ? event.oldRecord['id']
            : event.newRecord['id'];
        if (id is String) {
          if (event.eventType == PostgresChangeEvent.delete) {
            notifier.removeItem(id);
          } else {
            ref.read(bookingServiceProvider).getBookingById(id).then((booking) {
              if (booking == null || booking.shipment?.shipperId != shipperId) {
                notifier.removeItem(id);
              } else {
                notifier.upsertItem(booking);
              }
            }).catchError((Object e) {
              notifier.removeItem(id);
            });
          }
        }
        ref.invalidate(shipperStatsProvider(shipperId));
        ref.invalidate(shipperEarningsProvider(shipperId));
      },
    );

    // Show the most recent bookings (loaded pages) on the dashboard.
    final items = pager.items;
    if (pager.initialLoading) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spaceLg),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }
    if (items.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.spaceMd,
              AppTheme.spaceSm,
              AppTheme.spaceMd,
              AppTheme.spaceSm,
            ),
            child: GlassCard(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spaceLg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: AppTheme.textMutedColor,
                    ),
                    SizedBox(height: AppTheme.spaceMd),
                    Text(
                      'Aucune commande reçue',
                      style: AppTheme.h3,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppTheme.spaceXs),
                    Text(
                      'Les commandes des clients apparaîtront ici dès '
                      'qu\'elles arrivent, pour que vous puissiez les '
                      'consulter et les confirmer.',
                      style: AppTheme.bodySecondary,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMd,
          AppTheme.spaceSm,
          AppTheme.spaceMd,
          AppTheme.spaceSm,
        ),
        sliver: SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, index) => StaggeredEntrance(
            delay: Duration(milliseconds: (index % 10) * 40),
            child: _DashboardBookingCard(
              booking: items[index],
              onTap: () => _openBooking(context, items[index].id),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildStatusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceSm,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: Row(
        children: [
          for (final option in _statusOptions) ...[
            ChoiceChip(
              label: Text(option.label),
              selected: _statusFilter == option.value,
              onSelected: (_) => _onStatusSelected(option.value),
            ),
            const SizedBox(width: AppTheme.spaceSm),
          ],
        ],
      ),
    );
  }

  /// Panneau de calcul real-time dans le formulaire de publication : gain de
  /// l'expéditeur, dus plateforme (avec -30% Visa), et prix/kg payé par le
  /// client (prix expéditeur + commission plateforme).
  Widget _buildPricingPanel({
    required double weight,
    required double pricePerKg,
    required double commissionPercent,
    required String currency,
    required bool payByVisa,
    required ValueChanged<bool?> onToggleVisa,
  }) {
    final gain = weight * pricePerKg;
    final dues = gain * commissionPercent / 100;
    final discountedDues = payByVisa ? dues * 0.7 : dues;
    final clientPricePerKg =
        pricePerKg + (pricePerKg * commissionPercent / 100);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.primaryLighter,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calculate_rounded,
                  size: 18, color: AppTheme.primaryColor),
              SizedBox(width: AppTheme.spaceXs),
              Text(
                'Calcul en temps réel',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          if (pricePerKg <= 0)
            const Text(
              'Entrez votre prix par kg pour voir votre gain, les dus '
              'plateforme et le prix affiché au client.',
              style: AppTheme.caption,
            )
          else ...[
            _PricingRow(
              label: 'Votre gain (${weight.toStringAsFixed(1)} kg × '
                  '${pricePerKg.toStringAsFixed(0)} $currency)',
              value: '${gain.toStringAsFixed(0)} $currency',
            ),
            const SizedBox(height: AppTheme.spaceXs),
            _PricingRow(
              label: 'Dus plateforme (${commissionPercent.toStringAsFixed(0)}%)',
              value: '${discountedDues.toStringAsFixed(0)} $currency',
              highlight: true,
              strikethrough: payByVisa ? '${dues.toStringAsFixed(0)} $currency' : null,
            ),
            const SizedBox(height: AppTheme.spaceXs),
            _PricingRow(
              label: 'Prix/kg payé par le client',
              value: '${clientPricePerKg.toStringAsFixed(0)} $currency',
              bold: true,
            ),
            const SizedBox(height: AppTheme.spaceSm),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: payByVisa,
              onChanged: onToggleVisa,
              title: const Text(
                'Payer par carte Visa (-30% sur les dus)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'L\'offre ne sera visible des clients qu\'après confirmation '
                'du paiement par le fondateur.',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }

  Future<void> _showPublishDialog(String shipperId) async {
    final formKey = GlobalKey<FormState>();
    final weightController = TextEditingController();
    final priceController = TextEditingController();
    final airlineController = TextEditingController();
    final flightController = TextEditingController();
    final descriptionController = TextEditingController();
    final collectionAddressCtrl = TextEditingController();
    String? originCountry;
    String? arrivalAirport;
    String? destinationCity;
    DateTime departure = DateTime.now().add(const Duration(days: 3));
    bool submitting = false;
    bool payByVisa = false;
    bool saveAddressForNextTime = true;

    // Adresses de collecte déjà sauvegardées par l'expéditeur.
    List<String> savedAddresses = [];
    try {
      final shipperProfile =
          await ref.read(shipperServiceProvider).getShipperByUserId(
                ref.read(authServiceProvider).currentUserId ?? '',
              );
      savedAddresses = shipperProfile?.savedAddresses ?? [];
    } catch (_) {
      savedAddresses = [];
    }

    final settings = ref.read(platformSettingsProvider).valueOrNull;
    final minWeight = settings?.minWeightKg ?? AppConstants.minWeightKg;
    final maxWeight = settings?.maxWeightKg ?? AppConstants.maxWeightKg;
    final minPrice = settings?.minPricePerKg ?? AppConstants.minPricePerKg;
    final currency = settings?.defaultCurrency ?? AppConstants.defaultCurrency;
    final commissionPercent =
        settings?.commissionPercent ?? AppConstants.platformCommissionPercent;

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Publier une offre de transport',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AirportPickerField(
                      label: 'Départ — aéroport d\'origine',
                      value: originCountry,
                      prefixIcon: Icons.flight_takeoff_rounded,
                      onChanged: (v) =>
                          setSheetState(() => originCountry = v),
                    ),
                    const SizedBox(height: 12),
                    AirportPickerField(
                      label: 'Arrivée — aéroport de destination',
                      value: arrivalAirport,
                      prefixIcon: Icons.flight_land_rounded,
                      onChanged: (v) =>
                          setSheetState(() => arrivalAirport = v),
                    ),
                    const SizedBox(height: 12),
                    CountryCityPickerField(
                      label: 'Point de collecte — ville',
                      value: destinationCity,
                      prefixIcon: Icons.location_city_rounded,
                      onChanged: (v) =>
                          setSheetState(() => destinationCity = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: weightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setSheetState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Poids disponible (kg)',
                        prefixIcon: Icon(Icons.scale),
                      ),
                      validator: (v) {
                        final w = double.tryParse(v ?? '');
                        if (w == null || w <= minWeight) {
                          return 'Poids invalide';
                        }
                        if (w > maxWeight) {
                          return 'Maximum $maxWeight kg';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setSheetState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Votre prix par kg (DZD)',
                        hintText: 'Votre gain par kg',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (v) {
                        final p = double.tryParse(v ?? '');
                        if (p == null || p < minPrice) {
                          return 'Minimum $minPrice $currency/kg';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildPricingPanel(
                      weight: double.tryParse(weightController.text) ?? 0,
                      pricePerKg: double.tryParse(priceController.text) ?? 0,
                      commissionPercent: commissionPercent,
                      currency: currency,
                      payByVisa: payByVisa,
                      onToggleVisa: (v) =>
                          setSheetState(() => payByVisa = v ?? false),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: airlineController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Compagnie aérienne (optionnel)',
                              prefixIcon: Icon(Icons.airlines),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: flightController,
                            decoration: const InputDecoration(
                              labelText: 'N° de vol (optionnel)',
                              prefixIcon: Icon(Icons.flight),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description (optionnel)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Adresse de collecte : saisie manuelle ou choix parmi
                    // les adresses déjà sauvegardées par l'expéditeur.
                    if (savedAddresses.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final addr in savedAddresses)
                              ActionChip(
                                label: Text(
                                  addr,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                onPressed: () => setSheetState(() =>
                                    collectionAddressCtrl.text = addr),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextFormField(
                      controller: collectionAddressCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText:
                            'Adresse de collecte (lieu où remettre les colis)',
                        hintText: 'ex : Dépôt Bab Ezzouar, Alger',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.my_location_rounded, size: 20),
                          tooltip: 'Ma position actuelle',
                          onPressed: () async {
                            try {
                              LocationPermission permission =
                                  await Geolocator.checkPermission();
                              if (permission == LocationPermission.denied) {
                                permission =
                                    await Geolocator.requestPermission();
                              }
                              if (permission == LocationPermission.denied ||
                                  permission ==
                                      LocationPermission.deniedForever) {
                                if (sheetContext.mounted) {
                                  ScaffoldMessenger.of(sheetContext)
                                      .showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Permission de localisation refusée')),
                                  );
                                }
                                return;
                              }
                              final pos = await Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.medium,
                                timeLimit: const Duration(seconds: 10),
                              );
                              setSheetState(() {
                                collectionAddressCtrl.text =
                                    '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
                              });
                            } catch (_) {
                              if (sheetContext.mounted) {
                                ScaffoldMessenger.of(sheetContext)
                                    .showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Impossible d\'obtenir la position')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      value: saveAddressForNextTime,
                      onChanged: (v) => setSheetState(
                          () => saveAddressForNextTime = v ?? true),
                      title: const Text(
                        'Enregistrer cette adresse pour mes prochaines offres',
                        style: TextStyle(fontSize: 13),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: sheetContext,
                                initialDate: departure,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                if (!sheetContext.mounted) return;
                                final time = await showTimePicker(
                                  context: sheetContext,
                                  initialTime:
                                      TimeOfDay.fromDateTime(departure),
                                );
                                setSheetState(() => departure = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      time?.hour ?? departure.hour,
                                      time?.minute ?? departure.minute,
                                    ));
                              }
                            },
                            icon: const Icon(Icons.flight_takeoff, size: 18),
                            label: Text(
                                'Départ ${departure.day}/${departure.month}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              if (originCountry == null ||
                                  arrivalAirport == null ||
                                  destinationCity == null) {
                                ScaffoldMessenger.of(sheetContext)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Choisissez les aéroports de départ '
                                        'et d\'arrivée ainsi que la ville de '
                                        'collecte'),
                                  ),
                                );
                                return;
                              }
                              setSheetState(() => submitting = true);
                              try {
                                final weight =
                                    double.parse(weightController.text);
                                final price =
                                    double.parse(priceController.text);
                                final publicationFee =
                                    (weight * price * commissionPercent) / 100;
                                final discount = payByVisa ? 30.0 : 0.0;

                                await ref
                                    .read(shipmentServiceProvider)
                                    .publishShipment(
                                      shipperId: shipperId,
                                      originCountry: originCountry!,
                                      arrivalAirport: arrivalAirport!,
                                      destinationCity: destinationCity!,
                                      availableWeightKg: weight,
                                      pricePerKg: price,
                                      departureDate: departure,
                                      airline:
                                          airlineController.text.isEmpty
                                              ? null
                                              : airlineController.text,
                                      flightNumber:
                                          flightController.text.isEmpty
                                              ? null
                                              : flightController.text,
                                      description:
                                          descriptionController.text.isEmpty
                                              ? null
                                              : descriptionController.text,
                                      collectionAddress:
                                          collectionAddressCtrl.text.trim()
                                                  .isEmpty
                                              ? null
                                              : collectionAddressCtrl.text
                                                  .trim(),
                                      publicationFee: publicationFee,
                                      publicationFeeDiscount: discount,
                                    );
                                // Sauvegarde de l'adresse de collecte pour
                                // les prochaines offres (si demandé).
                                final addrToSave =
                                    collectionAddressCtrl.text.trim();
                                if (saveAddressForNextTime &&
                                    addrToSave.isNotEmpty &&
                                    !savedAddresses.contains(addrToSave)) {
                                  try {
                                    await ref
                                        .read(shipperServiceProvider)
                                        .saveCollectionAddress(
                                          shipperId: shipperId,
                                          address: addrToSave,
                                        );
                                  } catch (_) {
                                    // Non bloquant : la pub de l'offre
                                    // réussit quand même.
                                  }
                                }
                                // Le paiement par carte Visa (-30%) place
                                // l'offre en attente de confirmation
                                // fondateur (géré par publishShipment) ;
                                // sans Visa l'offre est visible immédiatement.
                                await ref
                                    .read(
                                        shipperShipmentsPagerProvider(shipperId)
                                            .notifier)
                                    .refresh();
                                ref.invalidate(shipperStatsProvider(shipperId));
                                ref.invalidate(
                                    shipperEarningsProvider(shipperId));
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          payByVisa
                                              ? 'Offre publiée — paiement Visa en '
                                                  'attente de confirmation du fondateur'
                                              : 'Offre publiée — visible des '
                                                  'clients immédiatement',
                                      ),
                                      backgroundColor: AppTheme.accentColor,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (sheetContext.mounted) {
                                  setSheetState(() => submitting = false);
                                  await showAppErrorDialog(
                                    sheetContext,
                                    message: 'Erreur: $e',
                                  );
                                }
                              }
                            },
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Publier'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// STATS CARD
// ============================================================================

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.spaceMd,
        horizontal: AppTheme.spaceSm,
      ),
      child: Column(
        children: [
          AnimatedIconDot(icon: icon, color: color),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.caption,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FinanceSummaryStrip extends ConsumerWidget {
  final String shipperId;

  const _FinanceSummaryStrip({required this.shipperId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(shipperFinanceSummaryProvider(shipperId));
    final settings = ref.watch(platformSettingsProvider);
    final currency =
        settings.valueOrNull?.defaultCurrency ?? AppConstants.defaultCurrency;

    // Profit net comptable : CA total (encaissé + à recevoir) − commissions
    // des commandes déjà payées par les clients. Les commissions des
    // commandes impayées (paiement à la livraison en attente) sont différées.
    final profit = (summary.valueOrNull?['profit'] as num?)?.toDouble() ?? 0;
    final feesDue = ((summary.valueOrNull?['fees_awaiting'] as num?) ?? 0) +
        ((summary.valueOrNull?['fees_pending'] as num?) ?? 0);

    return WalletCard(
      title: 'Portefeuille',
      mainLabel: 'Profit net',
      mainValue: '${profit.toStringAsFixed(0)} $currency',
      badgeLabel: feesDue > 0
          ? 'Dus : ${feesDue.toStringAsFixed(0)} $currency'
          : 'Aucun dû',
      badgePositive: feesDue <= 0,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ShipperFinanceScreen(),
        ),
      ),
    );
  }
}

class _PricingRow extends StatelessWidget {
  const _PricingRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.bold = false,
    this.strikethrough,
  });

  final String label;
  final String value;
  final bool highlight;
  final bool bold;
  final String? strikethrough;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTheme.caption.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        if (strikethrough != null) ...[
          Text(
            strikethrough!,
            style: AppTheme.caption.copyWith(
              decoration: TextDecoration.lineThrough,
              color: AppTheme.textMutedColor,
            ),
          ),
          const SizedBox(width: AppTheme.spaceXs),
        ],
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            color: highlight
                ? AppTheme.warningColor
                : bold
                    ? AppTheme.primaryColor
                    : AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SHIPMENT CARD
// ============================================================================

class _ShipmentMiniCard extends ConsumerWidget {
  final Shipment shipment;

  const _ShipmentMiniCard({required this.shipment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: GlassCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShipperShipmentDetailScreen(shipment: shipment),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedIconDot(
                  icon: Icons.flight_takeoff_rounded,
                  color: _shipmentStatusColor(shipment.status),
                ),
                const SizedBox(width: AppTheme.spaceMd),
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
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: AppTheme.textMutedColor,
                          ),
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
                      if (shipment.flightNumber != null) ...[
                        const SizedBox(height: AppTheme.spaceXs),
                        Row(
                          children: [
                            const Icon(
                              Icons.event_rounded,
                              size: 14,
                              color: AppTheme.textMutedColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                shipment.airline != null
                                    ? '${shipment.airline} · Vol ${shipment.flightNumber}'
                                    : 'Vol ${shipment.flightNumber}',
                                style: AppTheme.caption,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (shipment.description != null &&
                          shipment.description!.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spaceXs),
                        Text(
                          shipment.description!,
                          style: AppTheme.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!shipment.isPublished) ...[
                      const GradientBadge(
                        label: 'Validation en attente',
                        gradient: AppTheme.warningGradient,
                        compact: true,
                      ),
                      const SizedBox(height: AppTheme.spaceXs),
                    ],
                    GradientBadge(
                      label: _shipmentStatusLabel(shipment.status),
                      gradient: _shipmentStatusGradient(shipment.status),
                      compact: true,
                    ),
                    const SizedBox(height: AppTheme.spaceXs),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppTheme.textMutedColor,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flight_takeoff_rounded,
                        size: 14,
                        color: AppTheme.textMutedColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Départ ${_formatDate(shipment.departureDate)}',
                          style: AppTheme.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flight_land_rounded,
                        size: 14,
                        color: AppTheme.textMutedColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Arrivée ${shipment.arrivalDate != null ? _formatDate(shipment.arrivalDate!) : 'N/A'}',
                          style: AppTheme.caption,
                          overflow: TextOverflow.ellipsis,
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
                    label: 'Restant',
                    value:
                        '${shipment.remainingWeightKg.toStringAsFixed(1)} kg',
                  ),
                ),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.payments_outlined,
                    label: 'Prix / kg',
                    value:
                        '${shipment.pricePerKg.toStringAsFixed(0)} ${AppConstants.defaultCurrency}',
                    valueColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.scale_rounded,
                    label: 'Capacité',
                    value:
                        '${shipment.availableWeightKg.toStringAsFixed(1)} kg',
                  ),
                ),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.history_rounded,
                    label: 'Publiée le',
                    value: _formatDate(shipment.createdAt),
                  ),
                ),
              ],
            ),
            if (shipment.isFull) ...[
              const SizedBox(height: AppTheme.spaceSm),
              const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: AppTheme.accentColor,
                  ),
                  SizedBox(width: AppTheme.spaceXs),
                  Text('Offre complète', style: AppTheme.caption),
                ],
              ),
            ],
            const SizedBox(height: AppTheme.spaceXs),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Partager cette offre',
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                  color: AppTheme.primaryColor,
                  onPressed: () => ref
                      .read(offerShareServiceProvider)
                      .shareOffer(context, shipment),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => _formatDateFr(d);
}

const List<String> _frMonths = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

String _formatDateFr(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_frMonths[d.month - 1]} '
    '${(d.year)}';

String _formatShipmentDate(DateTime d) => _formatDateFr(d);

// ============================================================================
// SHIPPER SHIPMENTS LIST (TAB)
// ============================================================================

class ActiveShipmentsScreen extends ConsumerStatefulWidget {
  const ActiveShipmentsScreen({super.key});

  @override
  ConsumerState<ActiveShipmentsScreen> createState() =>
      _ActiveShipmentsScreenState();
}

class _ActiveShipmentsScreenState extends ConsumerState<ActiveShipmentsScreen> {
  final _scrollController = ScrollController();
  String _lastShipperId = '';

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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _syncPager() {
    final shipperId = ref.read(currentShipperProvider).valueOrNull?.id;
    if (shipperId == null || shipperId == _lastShipperId) return;
    _lastShipperId = shipperId;
    ref.read(shipperShipmentsPagerProvider(shipperId).notifier).loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final shipper = ref.watch(currentShipperProvider);

    // Robust initial load (see ShipperDashboardScreen) so offers always show
    // after a fresh sign-in.
    ref.listen(currentShipperProvider, (previous, next) {
      final id = next.valueOrNull?.id;
      if (id != null && id != _lastShipperId) {
        _lastShipperId = id;
        ref.read(shipperShipmentsPagerProvider(id).notifier).loadInitial();
      }
    });

    return shipper.when(
      data: (shipperData) {
        if (shipperData == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!shipperData.isVerified) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spaceLg),
                child: Text(
                  'Complétez votre dossier de vérification pour voir vos offres',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodySecondary,
                ),
              ),
            ),
          );
        }
        return _buildList(shipperData);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Erreur: $e'))),
    );
  }

  Widget _buildList(Shipper shipper) {
    final pager = ref.watch(shipperShipmentsPagerProvider(shipper.id));

    // Live refresh: new/changed shipments for this shipper reload the list.
    ref.listen(
      tableChangesProvider(('shipments', 'shipper_id', shipper.id)),
      (previous, next) {
        if (next.hasValue) {
          ref
              .read(shipperShipmentsPagerProvider(shipper.id).notifier)
              .refresh();
        }
      },
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(shipperShipmentsPagerProvider(shipper.id).notifier)
            .refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const CompactSliverHeader(
              title: 'Mes Offres',
              subtitle: 'Toutes tes offres publiées',
              icon: Icons.flight_takeoff_rounded,
            ),
            PagedSliverList<Shipment>(
              paginatedList: pager,
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd,
                AppTheme.spaceMd,
                AppTheme.spaceMd,
                AppTheme.spaceXxl,
              ),
              emptyState: const _EmptyShipments(),
              itemBuilder: (context, shipment, index) => StaggeredEntrance(
                delay: Duration(milliseconds: (index % 10) * 40),
                child: _ShipmentMiniCard(shipment: shipment),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SHIPMENT DETAIL + BOOKING MANAGEMENT
// ============================================================================

class ShipperShipmentDetailScreen extends ConsumerStatefulWidget {
  final Shipment shipment;

  const ShipperShipmentDetailScreen({super.key, required this.shipment});

  @override
  ConsumerState<ShipperShipmentDetailScreen> createState() =>
      _ShipperShipmentDetailScreenState();
}

class _ShipperShipmentDetailScreenState
    extends ConsumerState<ShipperShipmentDetailScreen> {
  final _scrollController = ScrollController();
  String _lastShipmentId = '';

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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _syncPager() {
    final shipmentId = widget.shipment.id;
    if (shipmentId == _lastShipmentId) return;
    _lastShipmentId = shipmentId;
    ref
        .read(shipperShipmentBookingsPagerProvider(shipmentId).notifier)
        .loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the live shipment so kg values refresh instantly when a client
    // books/reserves weight; falls back to the snapshot passed in.
    final live =
        ref.watch(shipmentByIdProvider(widget.shipment.id)).valueOrNull;
    final shipment = live ?? widget.shipment;
    final pager = ref.watch(shipperShipmentBookingsPagerProvider(shipment.id));

    // Live refresh: new/changed bookings for this shipment reload the list and
    // invalidate the live shipment (kg/progress) too.
    ref.listen(
      tableChangesProvider(('bookings', 'shipment_id', shipment.id)),
      (previous, next) {
        if (next.hasValue) {
          ref
              .read(shipperShipmentBookingsPagerProvider(shipment.id).notifier)
              .refresh();
          ref.invalidate(shipmentByIdProvider(shipment.id));
        }
      },
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(shipperShipmentBookingsPagerProvider(shipment.id).notifier)
            .refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CompactSliverHeader(
              title: '${shipment.originCountry} → ${shipment.destinationCity}',
              subtitle: 'Commandes reçues pour cette offre',
              icon: Icons.flight_takeoff_rounded,
              expandedHeight: 140,
            ),
            SliverToBoxAdapter(
              child: _buildSummary(shipment),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.spaceMd,
                  AppTheme.spaceMd,
                  AppTheme.spaceMd,
                  AppTheme.spaceSm,
                ),
                child: Text('Commandes reçues', style: AppTheme.h2),
              ),
            ),
            PagedSliverList<Booking>(
              paginatedList: pager,
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd,
                0,
                AppTheme.spaceMd,
                AppTheme.spaceXxl,
              ),
              emptyState: const _EmptyBookings(),
              itemBuilder: (context, booking, index) => StaggeredEntrance(
                delay: Duration(milliseconds: (index % 10) * 40),
                child: _ManageBookingCard(booking: booking),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(Shipment shipment) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        0,
      ),
      child: GlassCard(
        child: Column(
          children: [
            if (shipment.airline != null) ...[
              _SummaryRow(
                label: 'Compagnie',
                value: shipment.airline!,
              ),
              const SizedBox(height: AppTheme.spaceSm),
            ],
            _SummaryRow(
              label: 'Vol',
              value: shipment.flightNumber ?? '—',
            ),
            const SizedBox(height: AppTheme.spaceSm),
            _SummaryRow(
              label: 'Départ',
              value: _formatDate(shipment.departureDate),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            _SummaryRow(
              label: 'Arrivée',
              value: shipment.arrivalDate != null ? _formatDate(shipment.arrivalDate!) : 'N/A',
            ),
            const SizedBox(height: AppTheme.spaceSm),
            _SummaryRow(
              label: 'Publiée le',
              value: _formatDate(shipment.createdAt),
            ),
            if (shipment.description != null &&
                shipment.description!.isNotEmpty) ...[
              const Divider(height: AppTheme.spaceLg),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  shipment.description!,
                  style: AppTheme.bodySecondary,
                ),
              ),
            ],
            const Divider(height: AppTheme.spaceLg),
            _SummaryRow(
              label: 'Poids total',
              value: '${shipment.availableWeightKg.toStringAsFixed(1)} kg',
            ),
            const SizedBox(height: AppTheme.spaceSm),
            _SummaryRow(
              label: 'Réservé',
              value: '${shipment.reservedWeightKg.toStringAsFixed(1)} kg',
            ),
            const SizedBox(height: AppTheme.spaceSm),
            _SummaryRow(
              label: 'Restant',
              value: '${shipment.remainingWeightKg.toStringAsFixed(1)} kg',
              valueColor: AppTheme.accentColor,
            ),
            const Divider(height: AppTheme.spaceLg),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (shipment.utilizationPercent / 100).clamp(0, 1),
                minHeight: 8,
                backgroundColor: AppTheme.surfaceMuted,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            _SummaryRow(
              label: 'Prix / kg',
              value: '${shipment.pricePerKg.toStringAsFixed(0)} DZD',
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => _formatDateFr(d);
}

// ============================================================================
// SUMMARY ROW
// ============================================================================

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodySecondary),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: valueColor ?? AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// BOOKING MANAGEMENT CARD
// ============================================================================

class _DashboardBookingCard extends ConsumerWidget {
  final Booking booking;
  final VoidCallback onTap;

  const _DashboardBookingCard({
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = BookingStatusExt.fromString(booking.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: GlassCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedIconDot(
                  icon: Icons.inventory_2_outlined,
                  color: status.color,
                ),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking.productName,
                              style: AppTheme.h3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSm),
                          GradientBadge(
                            label: status.displayName,
                            gradient: _bookingStatusGradient(booking.status),
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceXs),
                      Row(
                        children: [
                          if (booking.client != null) ...[
                            GradientAvatar(
                              initial: booking.client!.fullName,
                              imageUrl: booking.client!.profilePictureUrl,
                              radius: 11,
                              onTap: () => openUserProfileFromUser(
                                context,
                                ref,
                                booking.client!,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceSm),
                          ],
                          Expanded(
                            child: Text(
                              '${booking.client?.fullName ?? 'Client'} • '
                              '${booking.allocatedWeightKg.toStringAsFixed(1)} kg '
                              '• ${booking.shipment?.originCountry ?? ''} → '
                              '${booking.shipment?.destinationCity ?? ''}',
                              style: AppTheme.caption,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Poids',
                    value: '${booking.requestedWeightKg.toStringAsFixed(1)} / '
                        '${booking.allocatedWeightKg.toStringAsFixed(1)} kg',
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textSecondaryColor,
                ),
              ],
            ),
            // Commande annulée : pas de chips « en attente » (paiement /
            // confirmation) — le badge « Annulée » de l'en-tête suffit.
            if (!booking.isCancelled) ...[
              const SizedBox(height: AppTheme.spaceSm),
              Wrap(
                children: [
                  _DashboardStatusChip(
                    icon: booking.isPaid
                        ? Icons.paid_rounded
                        : Icons.schedule_rounded,
                    label:
                        booking.isPaid ? 'Paiement reçu' : 'Paiement en attente',
                    color: booking.isPaid
                        ? AppTheme.accentColor
                        : AppTheme.warningColor,
                  ),
                  const SizedBox(width: AppTheme.spaceSm),
                  _DashboardStatusChip(
                    icon: booking.status == 'confirmed'
                        ? Icons.task_alt_rounded
                        : Icons.pending_actions_rounded,
                    label: booking.status == 'confirmed'
                        ? 'Commande confirmée'
                        : 'En attente de confirmation',
                    color: booking.status == 'confirmed'
                        ? AppTheme.infoColor
                        : AppTheme.warningColor,
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.event_rounded,
                    label: 'Commande',
                    value: _formatShipmentDate(booking.createdAt),
                  ),
                ),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.flight_takeoff_rounded,
                    label: 'Départ',
                    value: booking.shipment != null
                        ? _formatShipmentDate(booking.shipment!.departureDate)
                        : '—',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardStatusChip extends StatelessWidget {
  const _DashboardStatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageBookingCard extends ConsumerWidget {
  final Booking booking;

  const _ManageBookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = BookingStatusExt.fromString(booking.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: GlassCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShipperBookingDetailScreen(bookingId: booking.id),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedIconDot(
                  icon: Icons.inventory_2_outlined,
                  color: status.color,
                ),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking.productName,
                              style: AppTheme.h3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSm),
                          GradientBadge(
                            label: status.displayName,
                            gradient: _bookingStatusGradient(booking.status),
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceXs),
                      Row(
                        children: [
                          if (booking.client != null) ...[
                            GradientAvatar(
                              initial: booking.client!.fullName,
                              imageUrl: booking.client!.profilePictureUrl,
                              radius: 11,
                              onTap: () => openUserProfileFromUser(
                                context,
                                ref,
                                booking.client!,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceSm),
                          ],
                          Expanded(
                            child: Text(
                              '${booking.client?.fullName ?? 'Client'} • '
                              '${booking.allocatedWeightKg.toStringAsFixed(1)} kg',
                              style: AppTheme.caption,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
                    label: 'Poids',
                    value: '${booking.allocatedWeightKg.toStringAsFixed(1)} kg',
                  ),
                ),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.payments_outlined,
                    label: 'Total',
                    value:
                        '${booking.totalPrice.toStringAsFixed(0)} ${AppConstants.defaultCurrency}',
                    valueColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.event_rounded,
                    label: 'Commande',
                    value: _formatShipmentDate(booking.createdAt),
                  ),
                ),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.flight_takeoff_rounded,
                    label: 'Départ',
                    value: booking.shipment != null
                        ? _formatShipmentDate(booking.shipment!.departureDate)
                        : '—',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMd),
            _buildActions(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    final actions = <Widget>[];

    switch (booking.status) {
      case 'pending':
        actions.add(
          FilledButton.icon(
            onPressed: () => _confirmBooking(context, ref),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Confirmer'),
          ),
        );
        actions.add(
          OutlinedButton.icon(
            onPressed: () => _cancelBooking(context, ref),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Refuser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
          ),
        );
        break;
      case 'confirmed':
        actions.add(
          FilledButton.icon(
            onPressed: () => _markShipped(context, ref),
            icon: const Icon(Icons.flight_takeoff_rounded, size: 18),
            label: const Text('Marquer expédié'),
          ),
        );
        actions.add(
          OutlinedButton.icon(
            onPressed: () => _cancelBooking(context, ref),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Annuler'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
          ),
        );
        break;
      case 'shipped':
        actions.add(
          FilledButton.icon(
            onPressed: () => _markDelivered(context, ref),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text('Marquer livré'),
          ),
        );
        break;
    }

    return Wrap(
      spacing: AppTheme.spaceSm,
      runSpacing: AppTheme.spaceSm,
      children: actions,
    );
  }

  Future<void> _confirmBooking(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(bookingServiceProvider).confirmBooking(booking.id);
      // Étape de suivi : la commande est validée, le colis attend d'être
      // remis à l'expéditeur.
      await ref.read(trackingServiceProvider).addTrackingUpdate(
            bookingId: booking.id,
            status: 'order_processed',
            notes: 'Commande confirmée — en attente de collecte du colis '
                'ou marchandises',
            location: booking.shipment?.originCountry,
          );
      if (!context.mounted) return;
      _reload(context, ref);
      _notifyClient(context, ref);
      _showSuccess(context, 'Commande confirmée');
    } catch (e) {
      _showError(context, e);
    }
  }

  Future<void> _markShipped(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(bookingServiceProvider).markAsShipped(booking.id);
      await ref.read(trackingServiceProvider).addTrackingUpdate(
            bookingId: booking.id,
            status: 'departed_origin',
            notes: 'Colis expédié depuis ${booking.shipment?.originCountry}',
            location: booking.shipment?.originCountry,
          );
      await ref
          .read(notificationServiceProvider)
          .notifyClientShipmentDispatched(
            clientId: booking.clientId,
            bookingId: booking.id,
            destination: booking.shipment?.destinationCity ?? 'destination',
          );
      if (!context.mounted) return;
      _reload(context, ref);
      _showSuccess(context, 'Commande marquée comme expédiée');
    } catch (e) {
      _showError(context, e);
    }
  }

  Future<void> _markDelivered(BuildContext context, WidgetRef ref) async {
    final photo = await pickProofPhoto(context, title: 'Preuve de livraison');
    if (photo == null) return;
    if (!context.mounted) return;
    try {
      final url =
          await ref.read(storageServiceProvider).uploadBookingProofPhoto(
                file: photo,
                bookingId: booking.id,
                type: 'delivery',
              );
      await ref
          .read(bookingServiceProvider)
          .markAsDelivered(booking.id, deliveryPhotoUrl: url);
      await ref.read(trackingServiceProvider).addTrackingUpdate(
            bookingId: booking.id,
            status: 'delivered',
            notes: 'Colis livré à ${booking.shipment?.destinationCity}',
            location: booking.shipment?.destinationCity,
          );
      await ref.read(notificationServiceProvider).notifyClientShipmentDelivered(
            clientId: booking.clientId,
            bookingId: booking.id,
          );
      if (!context.mounted) return;
      _reload(context, ref);
      _showSuccess(context, 'Commande marquée comme livrée');
    } catch (e) {
      _showError(context, e);
    }
  }

  Future<void> _cancelBooking(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(bookingServiceProvider).cancelBooking(booking.id);
      if (!context.mounted) return;
      _reload(context, ref);
      _showSuccess(context, 'Commande annulée');
    } catch (e) {
      _showError(context, e);
    }
  }

  void _reload(BuildContext context, WidgetRef ref) {
    if (!context.mounted) return;
    ref
        .read(shipperShipmentBookingsPagerProvider(booking.shipmentId).notifier)
        .refresh();
    final shipperId = booking.shipment?.shipperId ?? '';
    if (shipperId.isNotEmpty) {
      ref.read(shipperShipmentsPagerProvider(shipperId).notifier).refresh();
    }
  }

  void _notifyClient(BuildContext context, WidgetRef ref) {
    ref.read(notificationServiceProvider).notifyClientBookingConfirmed(
          clientId: booking.clientId,
          bookingId: booking.id,
          productName: booking.productName,
        );
  }

  void _showError(BuildContext context, Object error) {
    if (!context.mounted) return;
    showAppErrorDialog(context, message: 'Erreur: $error');
  }

  void _showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// ============================================================================
// SHARED HELPERS
// ============================================================================

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
        const SizedBox(width: AppTheme.spaceSm),
        Expanded(
          child: Column(
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
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
        Icon(
          Icons.flight_takeoff_outlined,
          size: 64,
          color: AppTheme.textMutedColor,
        ),
        SizedBox(height: AppTheme.spaceMd),
        Text('Aucune offre publiée', style: AppTheme.h3),
        SizedBox(height: AppTheme.spaceSm),
        Text(
          'Publie ta première offre pour commencer.',
          style: AppTheme.bodySecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _EmptyFilteredShipments extends StatelessWidget {
  const _EmptyFilteredShipments();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppTheme.spaceXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_alt_off_outlined,
            size: 56,
            color: AppTheme.textMutedColor,
          ),
          SizedBox(height: AppTheme.spaceMd),
          Text('Aucune offre pour ce filtre', style: AppTheme.h3),
        ],
      ),
    );
  }
}

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 64,
          color: AppTheme.textMutedColor,
        ),
        SizedBox(height: AppTheme.spaceMd),
        Text('Aucune commande pour cette offre', style: AppTheme.h3),
      ],
    );
  }
}

String _shipmentStatusLabel(String status) {
  switch (status) {
    case 'active':
      return 'Active';
    case 'completed':
      return 'Terminée';
    case 'cancelled':
      return 'Annulée';
    default:
      return status;
  }
}

Color _shipmentStatusColor(String status) {
  switch (status) {
    case 'active':
      return AppTheme.accentColor;
    case 'completed':
      return AppTheme.primaryColor;
    case 'cancelled':
      return AppTheme.errorColor;
    default:
      return AppTheme.textSecondaryColor;
  }
}

LinearGradient _shipmentStatusGradient(String status) {
  switch (status) {
    case 'active':
      return AppTheme.successGradient;
    case 'completed':
      return AppTheme.primaryGradient;
    case 'cancelled':
      return AppTheme.errorGradient;
    default:
      return AppTheme.primaryGradient;
  }
}

LinearGradient _bookingStatusGradient(String status) {
  switch (status) {
    case 'pending':
      return AppTheme.warningGradient;
    case 'confirmed':
    case 'shipped':
      return AppTheme.primaryGradient;
    case 'delivered':
      return AppTheme.successGradient;
    case 'cancelled':
      return AppTheme.errorGradient;
    default:
      return AppTheme.primaryGradient;
  }
}
