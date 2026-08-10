import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';
import 'shipper_stats_detail_screen.dart';

// ============================================================================
// PAGINATED PROVIDERS (local to this file)
// ============================================================================

final shipperShipmentsPagerProvider = StateNotifierProvider.family<
    PaginatedListNotifier<Shipment>, PaginatedList<Shipment>, String>(
  (ref, shipperId) {
    return createPaginatedNotifier(
      (limit, offset) => ref
          .read(shipmentServiceProvider)
          .getShipperShipments(shipperId: shipperId, limit: limit, offset: offset),
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
  const ShipperDashboardScreen({Key? key}) : super(key: key);

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
    _syncPager();
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
  }

  void _onStatusSelected(String? status) {
    if (status == _statusFilter) return;
    setState(() => _statusFilter = status);
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
      }
    });

    return shipper.when(
      data: (shipperData) {
        if (shipperData == null || !shipperData.isVerified) {
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
    final title =
        isRejected ? 'Dossier rejeté' : 'Vérification en attente';
    final message = isRejected
        ? shipper?.rejectionReason ??
            'Veuillez soumettre à nouveau vos documents.'
        : 'Un administrateur doit valider votre identité avant '
            'de pouvoir publier des offres de transport.';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
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
                        isRejected
                            ? 'Soumettre à nouveau'
                            : 'Voir mon dossier',
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
            GradientSliverHeader(
              title: 'Tableau de bord',
              subtitle:
                  '${shipper.user?.fullName ?? 'Espace expéditeur'}  •  ★ ${shipper.ratingDisplay}',
              icon: Icons.local_shipping_rounded,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Publier une offre',
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.white),
                    onPressed: () => _showPublishDialog(shipper.id),
                  ),
                  const LogoutIconButton(),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: _buildStats(shipper),
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
                  icon: Icons.local_shipping_rounded,
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
    final flightController = TextEditingController();
    final descriptionController = TextEditingController();
    String originCountry = AppConstants.populateOrigins.first;
    String destinationCity = AppConstants.majorCities.first;
    DateTime departure = DateTime.now().add(const Duration(days: 3));
    DateTime arrival = DateTime.now().add(const Duration(days: 7));
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
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
                  DropdownButtonFormField<String>(
                    initialValue: originCountry,
                    decoration: const InputDecoration(labelText: 'Origine'),
                    items: AppConstants.populateOrigins
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setSheetState(() => originCountry = v ?? originCountry),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: destinationCity,
                    decoration: const InputDecoration(labelText: 'Destination'),
                    items: AppConstants.majorCities
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setSheetState(
                        () => destinationCity = v ?? destinationCity),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Poids disponible (kg)',
                      prefixIcon: Icon(Icons.scale),
                    ),
                    validator: (v) {
                      final w = double.tryParse(v ?? '');
                      if (w == null || w <= AppConstants.minWeightKg) {
                        return 'Poids invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Prix par kg (DZD)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (v) {
                      final p = double.tryParse(v ?? '');
                      if (p == null || p < AppConstants.minPricePerKg) {
                        return 'Minimum ${AppConstants.minPricePerKg} DZD/kg';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: flightController,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de vol (optionnel)',
                      prefixIcon: Icon(Icons.flight),
                    ),
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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: sheetContext,
                              initialDate: departure,
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setSheetState(() => departure = date);
                            }
                          },
                          icon: const Icon(Icons.flight_takeoff, size: 18),
                          label: Text('Départ ${departure.day}/${departure.month}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: sheetContext,
                              initialDate: arrival,
                              firstDate: departure,
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setSheetState(() => arrival = date);
                            }
                          },
                          icon: const Icon(Icons.flight_land, size: 18),
                          label: Text('Arrivée ${arrival.day}/${arrival.month}'),
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
                            setSheetState(() => submitting = true);
                            try {
                              await ref
                                  .read(shipmentServiceProvider)
                                  .publishShipment(
                                    shipperId: shipperId,
                                    originCountry: originCountry,
                                    destinationCity: destinationCity,
                                    availableWeightKg:
                                        double.parse(weightController.text),
                                    pricePerKg:
                                        double.parse(priceController.text),
                                    departureDate: departure,
                                    arrivalDate: arrival,
                                    flightNumber: flightController.text.isEmpty
                                        ? null
                                        : flightController.text,
                                    description:
                                        descriptionController.text.isEmpty
                                            ? null
                                            : descriptionController.text,
                                  );
                              await ref
                                  .read(shipperShipmentsPagerProvider(shipperId)
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
                                  const SnackBar(
                                    content: Text('Offre publiée avec succès'),
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
                  icon: Icons.local_shipping_rounded,
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
                      const SizedBox(height: AppTheme.spaceXs),
                      Row(
                        children: [
                          const Icon(
                            Icons.event_rounded,
                            size: 14,
                            color: AppTheme.textMutedColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Départ ${_formatDate(shipment.departureDate)}',
                            style: AppTheme.caption,
                          ),
                          if (shipment.flightNumber != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• Vol ${shipment.flightNumber}',
                              style: AppTheme.caption,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                GradientBadge(
                  label: _shipmentStatusLabel(shipment.status),
                  gradient: _shipmentStatusGradient(shipment.status),
                  compact: true,
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
                    value: '${shipment.remainingWeightKg.toStringAsFixed(1)} kg',
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
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

// ============================================================================
// SHIPPER SHIPMENTS LIST (TAB)
// ============================================================================

class ActiveShipmentsScreen extends ConsumerStatefulWidget {
  const ActiveShipmentsScreen({Key? key}) : super(key: key);

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
    _syncPager();
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
        if (shipperData == null || !shipperData.isVerified) {
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
        onRefresh: () =>
            ref.read(shipperShipmentsPagerProvider(shipper.id).notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const GradientSliverHeader(
              title: 'Mes Offres',
              subtitle: 'Toutes tes offres publiées',
              icon: Icons.local_shipping_rounded,
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

  const ShipperShipmentDetailScreen({Key? key, required this.shipment})
      : super(key: key);

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
    _syncPager();
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
    final live = ref.watch(shipmentByIdProvider(widget.shipment.id)).valueOrNull;
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
            GradientSliverHeader(
              title: '${shipment.originCountry} → ${shipment.destinationCity}',
              subtitle: 'Commandes reçues pour cette offre',
              icon: Icons.local_shipping_rounded,
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

class _ManageBookingCard extends ConsumerWidget {
  final Booking booking;

  const _ManageBookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = BookingStatusExt.fromString(booking.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: GlassCard(
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
                      Text(
                        '${booking.client?.fullName ?? 'Client'} • '
                        '${booking.allocatedWeightKg.toStringAsFixed(1)} kg',
                        style: AppTheme.caption,
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
      _reload(context, ref);
      _notifyShipper(context, ref);
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
      await ref.read(notificationServiceProvider).notifyClientShipmentDispatched(
            clientId: booking.clientId,
            bookingId: booking.id,
            destination: booking.shipment?.destinationCity ?? 'destination',
          );
      _reload(context, ref);
    } catch (e) {
      _showError(context, e);
    }
  }

  Future<void> _markDelivered(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(bookingServiceProvider).markAsDelivered(booking.id);
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
      _reload(context, ref);
    } catch (e) {
      _showError(context, e);
    }
  }

  Future<void> _cancelBooking(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(bookingServiceProvider).cancelBooking(booking.id);
      _reload(context, ref);
    } catch (e) {
      _showError(context, e);
    }
  }

  void _reload(BuildContext context, WidgetRef ref) {
    ref
        .read(shipperShipmentBookingsPagerProvider(booking.shipmentId).notifier)
        .refresh();
    final shipperId = booking.shipment?.shipperId ?? '';
    if (shipperId.isNotEmpty) {
      ref.read(shipperShipmentsPagerProvider(shipperId).notifier).refresh();
    }
  }

  void _notifyShipper(BuildContext context, WidgetRef ref) {
    ref.read(notificationServiceProvider).notifyShipperBookingConfirmed(
          shipperId: booking.shipment?.shipperId ?? '',
          bookingId: booking.id,
          productName: booking.productName,
          allocatedWeight: booking.allocatedWeightKg,
        );
  }

  void _showError(BuildContext context, Object error) {
    if (!context.mounted) return;
    showAppErrorDialog(context, message: 'Erreur: $error');
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
          Icons.local_shipping_outlined,
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
