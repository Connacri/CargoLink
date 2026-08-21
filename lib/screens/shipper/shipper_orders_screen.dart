import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/tracking_timeline.dart';
import '../../core/enums/app_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/profile_navigation.dart';
import '../../core/widgets/qr_ticket_dialog.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import 'shipper_booking_detail_screen.dart';
import 'shipper_stats_detail_screen.dart';

/// « Commandes en cours » : toutes les commandes reçues pas encore livrées,
/// chacune dépliable avec les détails du dossier et la frise de suivi.
class ShipperOrdersInProgressScreen extends ConsumerStatefulWidget {
  final String shipperId;

  const ShipperOrdersInProgressScreen({super.key, required this.shipperId});

  @override
  ConsumerState<ShipperOrdersInProgressScreen> createState() =>
      _ShipperOrdersInProgressScreenState();
}

class _ShipperOrdersInProgressScreenState
    extends ConsumerState<ShipperOrdersInProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(shipperBookingsPagerProvider(widget.shipperId).notifier)
          .loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pager = ref.watch(shipperBookingsPagerProvider(widget.shipperId));
    final activeOrders = pager.items
        .where((b) => b.status != 'delivered' && b.status != 'cancelled')
        .toList();

    // Live refresh : nouvelle commande ou changement de statut → la liste se
    // met à jour instantanément.
    ref.listen(
      tableChangesProvider(('bookings', null, null)),
      (previous, next) {
        final event = next.valueOrNull;
        if (event == null) return;
        final id =
            (event.newRecord['id'] ?? event.oldRecord['id']) as String?;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref
              .read(
                shipperBookingsPagerProvider(widget.shipperId).notifier,
              )
              .refresh();
          if (id != null) ref.invalidate(trackingHistoryProvider(id));
        });
      },
    );

    return Scaffold(
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => ref
              .read(shipperBookingsPagerProvider(widget.shipperId).notifier)
              .refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              GradientSliverHeader(
                title: 'Commandes en cours',
                subtitle:
                    '${activeOrders.length} commande${activeOrders.length > 1 ? 's' : ''} pas encore livrée${activeOrders.length > 1 ? 's' : ''}',
                icon: Icons.local_shipping_rounded,
              ),
              if (activeOrders.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.task_alt_rounded,
                          size: 64, color: AppTheme.accentColor),
                      SizedBox(height: AppTheme.spaceMd),
                      Text('Aucune commande en cours', style: AppTheme.h3),
                      SizedBox(height: AppTheme.spaceSm),
                      Text(
                        'Toutes les commandes reçues sont livrées.',
                        style: AppTheme.bodySecondary,
                      ),
                    ],
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceMd,
                    AppTheme.spaceMd,
                    AppTheme.spaceMd,
                    AppTheme.spaceXxl,
                  ),
                  sliver: SliverList.builder(
                    itemCount: activeOrders.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
                      child: _OrderTile(booking: activeOrders[index]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Une commande dépliable : en-tête compact (produit, client, badge), contenu
/// déplié = détails du dossier + frise de suivi + QR + détail complet.
class _OrderTile extends ConsumerWidget {
  final Booking booking;

  const _OrderTile({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = BookingStatusExt.fromString(booking.status);
    final trackingAsync = ref.watch(trackingHistoryProvider(booking.id));
    final events = trackingAsync.valueOrNull ?? const <ShipmentTracking>[];
    final latest = events.isEmpty ? null : events.last;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMd,
            vertical: AppTheme.spaceXs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd,
            0,
            AppTheme.spaceMd,
            AppTheme.spaceLg,
          ),
          iconColor: AppTheme.textSecondaryColor,
          collapsedIconColor: AppTheme.textSecondaryColor,
          leading: AnimatedIconDot(
            icon: Icons.inventory_2_outlined,
            color: status.color,
            size: 18,
          ),
          title: Text(
            booking.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '${booking.client?.fullName ?? 'Client'} • '
                    '${booking.allocatedWeightKg.toStringAsFixed(1)} kg',
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.caption,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Flexible(
                  child: Text(
                    latest != null
                        ? shipmentStatusLabel(latest.status)
                        : status.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.infoColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GradientBadge(
                label: status.displayName,
                gradient: _statusGradient(booking.status),
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            _detailRow(
              Icons.person_outline_rounded,
              'Client',
              booking.client?.fullName ?? '—',
              onAvatarTap: booking.client == null
                  ? null
                  : () => openUserProfileFromUser(context, ref, booking.client!),
              avatarUrl: booking.client?.profilePictureUrl,
            ),
            _detailRow(
              Icons.flight_takeoff_rounded,
              'Trajet',
              booking.shipment == null
                  ? '—'
                  : '${booking.shipment!.originCountry} → ${booking.shipment!.destinationCity}',
            ),
            if (booking.shipment?.flightNumber?.isNotEmpty == true)
              _detailRow(
                Icons.airplanemode_active_rounded,
                'Vol',
                booking.shipment!.airline != null
                    ? '${booking.shipment!.airline} · ${booking.shipment!.flightNumber}'
                    : booking.shipment!.flightNumber!,
              ),
            _detailRow(
              Icons.monitor_weight_outlined,
              'Poids demandé / alloué',
              '${booking.requestedWeightKg.toStringAsFixed(1)} / '
                  '${booking.allocatedWeightKg.toStringAsFixed(1)} kg',
            ),
            if (booking.deliveryAddress?.isNotEmpty == true)
              _detailRow(
                Icons.location_on_outlined,
                'Adresse de livraison',
                booking.deliveryAddress!,
              ),
            if (booking.deliveryPhone?.isNotEmpty == true)
              _detailRow(
                Icons.phone_outlined,
                'Téléphone',
                booking.deliveryPhone!,
              ),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _paymentChip(booking.isPaid),
                  ),
                ),
                IconButton(
                  tooltip: 'Billet QR',
                  onPressed: () => showQrTicketDialog(context, booking),
                  icon: const Icon(
                    Icons.qr_code_2_rounded,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Frise de suivi',
                style: AppTheme.body.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            trackingAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppTheme.spaceLg),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMd),
                child: Text('Erreur de suivi : $e', style: AppTheme.caption),
              ),
              data: (events) => events.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppTheme.spaceMd),
                      child: Text(
                        'Aucune mise à jour de suivi pour le moment.',
                        style: AppTheme.bodySecondary,
                      ),
                    )
                  : TrackingTimeline(
                      events:
                          mapShipmentTrackingToTimeline(events, delivered: false),
                    ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ShipperBookingDetailScreen(bookingId: booking.id),
                  ),
                ),
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: const Text('Ouvrir le détail complet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onAvatarTap,
    String? avatarUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceXs + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppTheme.textSecondaryColor),
          const SizedBox(width: AppTheme.spaceXs + 2),
          Text('$label : ', style: AppTheme.caption),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTheme.caption.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (onAvatarTap != null) ...[
            const SizedBox(width: AppTheme.spaceXs),
            GradientAvatar(
              initial: value,
              imageUrl: avatarUrl,
              radius: 9,
              onTap: onAvatarTap,
            ),
          ],
        ],
      ),
    );
  }

  Widget _paymentChip(bool paid) {
    final Color color = paid ? AppTheme.accentColor : AppTheme.warningColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            paid ? Icons.paid_rounded : Icons.schedule_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            paid ? 'Paiement reçu' : 'Paiement en attente',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

LinearGradient _statusGradient(String status) {
  switch (status) {
    case 'pending':
      return AppTheme.warningGradient;
    case 'confirmed':
    case 'accepted':
      return AppTheme.primaryGradient;
    case 'collected':
    case 'verifying':
    case 'shipped':
      return AppTheme.infoGradient;
    case 'arrived':
    case 'out_for_delivery':
      return AppTheme.warningGradient;
    case 'delivered':
      return AppTheme.successGradient;
    case 'cancelled':
      return AppTheme.errorGradient;
    default:
      return AppTheme.primaryGradient;
  }
}
