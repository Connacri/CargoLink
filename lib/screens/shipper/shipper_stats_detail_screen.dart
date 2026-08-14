import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';
import '../../components/revenue_bar_chart.dart';
import 'shipper_dashboard_screen.dart';
import 'shipper_booking_detail_screen.dart';

/// Paginated list of all bookings belonging to a shipper (across shipments).
final shipperBookingsPagerProvider = StateNotifierProvider.family<
    PaginatedListNotifier<Booking>,
    PaginatedList<Booking>,
    String>((ref, shipperId) {
  return createPaginatedNotifier(
    (limit, offset) => ref.read(shipperBookingsProvider((
      shipperId: shipperId,
      limit: limit,
      offset: offset,
    )).future),
    pageSize: 15,
  );
});

enum ShipperStatsDetailType { shipments, active, bookings, revenue }

extension ShipperStatsDetailTypeX on ShipperStatsDetailType {
  String get title {
    switch (this) {
      case ShipperStatsDetailType.shipments:
        return 'Toutes les offres';
      case ShipperStatsDetailType.active:
        return 'Offres actives';
      case ShipperStatsDetailType.bookings:
        return 'Commandes reçues';
      case ShipperStatsDetailType.revenue:
        return 'Chiffre d\'affaires';
    }
  }

  IconData get icon {
    switch (this) {
      case ShipperStatsDetailType.shipments:
        return Icons.local_shipping_rounded;
      case ShipperStatsDetailType.active:
        return Icons.play_circle_outline_rounded;
      case ShipperStatsDetailType.bookings:
        return Icons.receipt_long_rounded;
      case ShipperStatsDetailType.revenue:
        return Icons.payments_outlined;
    }
  }
}

/// Shows a detail list/grid for one of the dashboard stat cards.
class ShipperStatsDetailScreen extends ConsumerStatefulWidget {
  final String shipperId;
  final ShipperStatsDetailType type;

  const ShipperStatsDetailScreen({
    Key? key,
    required this.shipperId,
    required this.type,
  }) : super(key: key);

  @override
  ConsumerState<ShipperStatsDetailScreen> createState() =>
      _ShipperStatsDetailScreenState();
}

class _ShipperStatsDetailScreenState
    extends ConsumerState<ShipperStatsDetailScreen> {
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
    if (widget.shipperId == _lastShipperId) return;
    _lastShipperId = widget.shipperId;
    if (widget.type == ShipperStatsDetailType.bookings ||
        widget.type == ShipperStatsDetailType.revenue) {
      ref
          .read(shipperBookingsPagerProvider(widget.shipperId).notifier)
          .loadInitial();
    } else {
      ref
          .read(shipperShipmentsPagerProvider(widget.shipperId).notifier)
          .loadInitial();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBookings = widget.type == ShipperStatsDetailType.bookings ||
        widget.type == ShipperStatsDetailType.revenue;

    // Live refresh on server changes for this shipper.
    ref.listen(
      tableChangesProvider(('shipments', 'shipper_id', widget.shipperId)),
      (previous, next) {
        if (next.hasValue) {
          ref
              .read(shipperShipmentsPagerProvider(widget.shipperId).notifier)
              .refresh();
        }
      },
    );
    ref.listen(
      tableChangesProvider(('bookings', null, null)),
      (previous, next) {
        if (next.hasValue && isBookings) {
          ref
              .read(shipperBookingsPagerProvider(widget.shipperId).notifier)
              .refresh();
        }
      },
    );

    final shipper = ref.watch(shipperByIdProvider(widget.shipperId));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(shipperStatsProvider(widget.shipperId));
          ref.invalidate(shipperEarningsProvider(widget.shipperId));
          final notifier = isBookings
              ? ref
                  .read(shipperBookingsPagerProvider(widget.shipperId).notifier)
              : ref.read(
                  shipperShipmentsPagerProvider(widget.shipperId).notifier);
          await notifier.refresh();
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            GradientSliverHeader(
              title: widget.type.title,
              subtitle: _buildSubtitle(shipper),
              icon: widget.type.icon,
              expandedHeight: 140,
            ),
            if (widget.type == ShipperStatsDetailType.revenue)
              SliverToBoxAdapter(
                child: _buildRevenueHeader(shipper),
              ),
            if (widget.type == ShipperStatsDetailType.revenue)
              SliverToBoxAdapter(
                child: _buildCommissionCard(),
              ),
            if (widget.type == ShipperStatsDetailType.revenue)
              SliverToBoxAdapter(
                child: _buildRevenueChart(),
              ),
            if (widget.type == ShipperStatsDetailType.revenue) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.spaceMd,
                    AppTheme.spaceLg,
                    AppTheme.spaceMd,
                    AppTheme.spaceSm,
                  ),
                  child: Text('Inventaire', style: AppTheme.h2),
                ),
              ),
              _buildInventorySection(),
            ],
            if (isBookings) _buildBookingsList() else _buildShipmentsList(),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle(AsyncValue<Shipper?> shipper) {
    final name = shipper.valueOrNull?.user?.fullName ?? 'Espace expéditeur';
    return name;
  }

  Widget _buildRevenueHeader(AsyncValue<Shipper?> shipper) {
    final earnings = ref.watch(shipperEarningsProvider(widget.shipperId));
    final settings = ref.watch(platformSettingsProvider);
    final currency =
        settings.valueOrNull?.defaultCurrency ?? AppConstants.defaultCurrency;
    final revenue = earnings.valueOrNull ?? 0.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          children: [
            const Text('Revenus totaux', style: AppTheme.caption),
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              '${revenue.toStringAsFixed(0)} $currency',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionCard() {
    final fees = ref.watch(shipperPlatformFeesProvider(widget.shipperId));
    final settings = ref.watch(platformSettingsProvider);
    final rate = settings.valueOrNull?.commissionPercent ??
        AppConstants.platformCommissionPercent;
    final currency =
        settings.valueOrNull?.defaultCurrency ?? AppConstants.defaultCurrency;
    final list = fees.valueOrNull ?? const <PlatformFee>[];
    final total = list.fold<double>(0, (s, f) => s + f.amount);
    final paid =
        list.where((f) => f.isPaid).fold<double>(0, (s, f) => s + f.amount);
    final due = total - paid;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceXs,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Commission plateforme ($rate%)',
              style: AppTheme.h3,
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                Expanded(
                  child: _CommissionStat(
                    icon: Icons.check_circle_rounded,
                    color: AppTheme.accentColor,
                    label: 'Payé',
                    value: '$paid.toStringAsFixed(0) $currency',
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: _CommissionStat(
                    icon: Icons.pending_actions_rounded,
                    color:
                        due > 0 ? AppTheme.warningColor : AppTheme.accentColor,
                    label: 'Dette',
                    value: '$due.toStringAsFixed(0) $currency',
                  ),
                ),
              ],
            ),
            if (due > 0) ...[
              const SizedBox(height: AppTheme.spaceMd),
              FilledButton.icon(
                onPressed: _submittingPay ? null : () => _payDues(),
                icon: _submittingPay
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.payment_rounded, size: 18),
                label: Text(
                  _submittingPay
                      ? 'Paiement...'
                      : 'Payer mes dues (${due.toStringAsFixed(0)} $currency)',
                ),
              ),
            ] else ...[
              const SizedBox(height: AppTheme.spaceSm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.verified_rounded,
                    size: 16,
                    color: AppTheme.accentColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Aucune dette : commission réglée',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _submittingPay = false;

  Future<void> _payDues() async {
    setState(() => _submittingPay = true);
    try {
      await ref.read(paymentServiceProvider).payPlatformFees(widget.shipperId);
      ref.invalidate(shipperPlatformFeesProvider(widget.shipperId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commission réglée, merci !'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _submittingPay = false);
    }
  }

  /// Monthly revenue bar chart fed by the loaded bookings.
  Widget _buildRevenueChart() {
    const months = [
      'J',
      'F',
      'M',
      'A',
      'M',
      'J',
      'J',
      'A',
      'S',
      'O',
      'N',
      'D',
    ];
    final pager = ref.watch(shipperBookingsPagerProvider(widget.shipperId));
    final byMonth = <int, double>{};
    for (final booking in pager.items) {
      final month = booking.createdAt.month;
      byMonth[month] = (byMonth[month] ?? 0) + booking.totalPrice;
    }
    final data = <RevenueBar>[
      for (var m = 1; m <= 12; m++)
        RevenueBar(label: months[m - 1], value: byMonth[m] ?? 0),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceXs,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chiffre d\'affaires par mois', style: AppTheme.h3),
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              'Basé sur les commandes chargées (${pager.items.length})',
              style: AppTheme.caption,
            ),
            const SizedBox(height: AppTheme.spaceMd),
            RevenueBarChart(
              data: data,
              valueFormatter: (v) => v >= 1000
                  ? '${(v / 1000).toStringAsFixed(1)}k'
                  : v.toStringAsFixed(0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySection() {
    final pager = ref.watch(shipperShipmentsPagerProvider(widget.shipperId));
    final items = pager.items;
    if (items.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
          child: Text(
            'Aucun article en inventaire.',
            style: AppTheme.bodySecondary,
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceXs,
        AppTheme.spaceMd,
        AppTheme.spaceLg,
      ),
      sliver: SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, index) => _InventoryTile(shipment: items[index]),
      ),
    );
  }

  Widget _buildBookingsList() {
    final pager = ref.watch(shipperBookingsPagerProvider(widget.shipperId));
    return PagedSliverList<Booking>(
      paginatedList: pager,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceXxl,
      ),
      emptyState: const _EmptyDetail(
        icon: Icons.receipt_long_outlined,
        message: 'Aucune commande reçue',
      ),
      itemBuilder: (context, booking, index) => StaggeredEntrance(
        delay: Duration(milliseconds: (index % 10) * 40),
        child: _BookingTile(booking: booking),
      ),
    );
  }

  Widget _buildShipmentsList() {
    final pager = ref.watch(shipperShipmentsPagerProvider(widget.shipperId));
    final activeOnly = widget.type == ShipperStatsDetailType.active;

    final filtered =
        activeOnly ? pager.items.where((s) => s.isActive).toList() : null;

    if (activeOnly && filtered != null && filtered.isEmpty) {
      return const SliverToBoxAdapter(
        child: _EmptyDetail(
          icon: Icons.play_circle_outline_rounded,
          message: 'Aucune offre active',
        ),
      );
    }

    return PagedSliverList<Shipment>(
      paginatedList: pager,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceXxl,
      ),
      emptyState: const _EmptyDetail(
        icon: Icons.local_shipping_outlined,
        message: 'Aucune offre publiée',
      ),
      itemBuilder: (context, shipment, index) {
        if (activeOnly && !shipment.isActive) {
          return const SizedBox.shrink();
        }
        return StaggeredEntrance(
          delay: Duration(milliseconds: (index % 10) * 40),
          child: _ShipmentTile(shipment: shipment),
        );
      },
    );
  }
}

class _ShipmentTile extends ConsumerWidget {
  final Shipment shipment;

  const _ShipmentTile({required this.shipment});

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
              children: [
                Expanded(
                  child: Text(
                    '${shipment.originCountry} → ${shipment.destinationCity}',
                    style: AppTheme.h3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                GradientBadge(
                  label: shipment.isActive ? 'Active' : 'Terminée',
                  gradient: shipment.isActive
                      ? AppTheme.successGradient
                      : AppTheme.primaryGradient,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
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
          ],
        ),
      ),
    );
  }
}

class _BookingTile extends ConsumerWidget {
  final Booking booking;

  const _BookingTile({required this.booking});

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
              children: [
                AnimatedIconDot(
                  icon: Icons.inventory_2_outlined,
                  color: status.color,
                ),
                const SizedBox(width: AppTheme.spaceMd),
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
                GradientAvatar(
                  initial: booking.client?.fullName,
                  imageUrl: booking.client?.profilePictureUrl,
                  radius: 12,
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: Text(
                    '${booking.client?.fullName ?? 'Client'}'
                    '${booking.client?.phone.isNotEmpty ?? false ? ' · ${booking.client!.phone}' : ''}',
                    style: AppTheme.caption,
                    overflow: TextOverflow.ellipsis,
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
            onPressed: () => _confirm(context, ref),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Confirmer'),
          ),
        );
        actions.add(
          OutlinedButton.icon(
            onPressed: () => _cancel(context, ref),
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
            onPressed: () => _cancel(context, ref),
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

  Future<void> _runAction(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
      _refresh(ref);
    } catch (e) {
      if (context.mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    }
  }

  void _confirm(BuildContext context, WidgetRef ref) => _runAction(
      context,
      ref,
      () => ref.read(bookingServiceProvider).confirmBooking(booking.id),
      'Commande confirmée');

  void _markShipped(BuildContext context, WidgetRef ref) => _runAction(
        context,
        ref,
        () async {
          await ref.read(bookingServiceProvider).markAsShipped(booking.id);
          await ref.read(trackingServiceProvider).addTrackingUpdate(
                bookingId: booking.id,
                status: 'departed_origin',
                notes:
                    'Colis expédié depuis ${booking.shipment?.originCountry}',
                location: booking.shipment?.originCountry,
              );
          await ref
              .read(notificationServiceProvider)
              .notifyClientShipmentDispatched(
                clientId: booking.clientId,
                bookingId: booking.id,
                destination: booking.shipment?.destinationCity ?? 'destination',
              );
        },
        'Commande marquée comme expédiée',
      );

  Future<void> _markDelivered(BuildContext context, WidgetRef ref) async {
    final photo = await pickProofPhoto(context, title: 'Preuve de livraison');
    if (photo == null) return;
    await _runAction(
      context,
      ref,
      () async {
        final url = await ref
            .read(storageServiceProvider)
            .uploadBookingProofPhoto(
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
        await ref
            .read(notificationServiceProvider)
            .notifyClientShipmentDelivered(
              clientId: booking.clientId,
              bookingId: booking.id,
            );
      },
      'Commande marquée comme livrée',
    );
  }

  void _cancel(BuildContext context, WidgetRef ref) => _runAction(
        context,
        ref,
        () => ref.read(bookingServiceProvider).cancelBooking(booking.id),
        'Commande annulée',
      );

  void _refresh(WidgetRef ref) {
    final shipperId = booking.shipment?.shipperId ?? '';
    if (shipperId.isEmpty) return;
    ref.read(shipperBookingsPagerProvider(shipperId).notifier).refresh();
    ref.read(shipperShipmentsPagerProvider(shipperId).notifier).refresh();
    ref.invalidate(shipperStatsProvider(shipperId));
    ref.invalidate(shipperEarningsProvider(shipperId));
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

class _CommissionStat extends StatelessWidget {
  const _CommissionStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppTheme.spaceXs),
          Text(label, style: AppTheme.caption),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  final Shipment shipment;

  const _InventoryTile({required this.shipment});

  @override
  Widget build(BuildContext context) {
    final sold = shipment.reservedWeightKg;
    final remaining = shipment.remainingWeightKg;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${shipment.originCountry} → ${shipment.destinationCity}',
                    style: AppTheme.h3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                GradientBadge(
                  label: shipment.isActive ? 'Active' : 'Terminée',
                  gradient: shipment.isActive
                      ? AppTheme.successGradient
                      : AppTheme.primaryGradient,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMd),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (shipment.utilizationPercent / 100).clamp(0, 1),
                minHeight: 8,
                backgroundColor: AppTheme.surfaceMuted,
                valueColor: AlwaysStoppedAnimation<Color>(
                  shipment.isFull ? AppTheme.errorColor : AppTheme.accentColor,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.sell_outlined,
                    label: 'Vendu',
                    value: '${sold.toStringAsFixed(1)} kg',
                    valueColor: AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.inventory_2_outlined,
                    label: 'Restant',
                    value: '${remaining.toStringAsFixed(1)} kg',
                    valueColor: AppTheme.accentColor,
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

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppTheme.textMutedColor),
          const SizedBox(height: AppTheme.spaceMd),
          Text(message, style: AppTheme.h3),
        ],
      ),
    );
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
