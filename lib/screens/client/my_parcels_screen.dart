import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/tracking_timeline.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/qr_booking.dart';
import '../../core/widgets/booking_acceptance_chip.dart';
import '../../core/widgets/qr_ticket_dialog.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../client/tracking_screen.dart';

/// Toutes les réservations du client (hors annulées), colis en cours d'abord
/// puis livrés du plus récent au plus ancien. autoDispose → recalcul à chaque
/// ouverture de l'écran.
final myParcelsProvider = FutureProvider.autoDispose<List<Booking>>((ref) async {
  final clientId = ref.watch(authServiceProvider).currentUserId;
  if (clientId == null) return const [];
  final bookings = await ref
      .read(bookingServiceProvider)
      .getClientBookings(clientId: clientId, limit: 100);
  final visible =
      bookings.where((b) => b.status != 'cancelled').toList();
  int rank(String status) => status == 'delivered' ? 1 : 0;
  visible.sort((a, b) {
    final r = rank(a.status).compareTo(rank(b.status));
    if (r != 0) return r;
    return b.updatedAt.compareTo(a.updatedAt);
  });
  return visible;
});

/// « Mes colis » : la liste complète des colis du client, chacun dépliable
/// avec ses détails et sa frise de suivi complète. Un appui sur le QR rouvre
/// le billet de réservation (même dialog que dans le wizard).
class MyParcelsScreen extends ConsumerWidget {
  const MyParcelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parcelsAsync = ref.watch(myParcelsProvider);

    // Live refresh : un changement de statut met la liste à jour.
    ref.listen(
      tableChangesProvider(('bookings', null, null)),
      (previous, next) {
        if (!next.hasValue) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(myParcelsProvider);
        });
      },
    );

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const CompactSliverHeader(
              title: 'Mes colis',
              subtitle: 'Suivi de tous vos colis',
              icon: Icons.connecting_airports_rounded,
            ),
            parcelsAsync.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Erreur : $e')),
              ),
              data: (parcels) {
                if (parcels.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 64, color: AppTheme.textMutedColor),
                        SizedBox(height: AppTheme.spaceMd),
                        Text('Aucun colis pour le moment', style: AppTheme.h3),
                        SizedBox(height: AppTheme.spaceSm),
                        Text(
                          'Réservez une offre pour suivre vos colis ici.',
                          style: AppTheme.bodySecondary,
                        ),
                      ],
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceMd,
                    AppTheme.spaceMd,
                    AppTheme.spaceMd,
                    AppTheme.spaceXxl,
                  ),
                  sliver: SliverList.builder(
                    itemCount: parcels.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
                      child: _ParcelTile(booking: parcels[index]),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Une carte depliable par colis : en-tete enrichi avec badge statut,
/// chips d'infos (poids, prix, vol), route visuelle, contenu deplie
/// avec details + frise de suivi complete + acces au suivi detaille.
class _ParcelTile extends ConsumerWidget {
  final Booking booking;

  const _ParcelTile({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delivered = booking.status == 'delivered';
    final trackingAsync = ref.watch(trackingHistoryProvider(booking.id));
    final events = trackingAsync.valueOrNull ?? const <ShipmentTracking>[];
    final latest = events.isEmpty ? null : events.last;

    final statusColor = _statusColor(booking.status);
    final statusLabel = latest != null
        ? TrackingScreen.statusLabel(latest.status)
        : _statusFallbackLabel(booking.status);

    final originCountry = booking.shipment?.originCountry ?? '\u2014';
    final destCity = booking.shipment?.destinationCity ?? '\u2014';

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMd,
            vertical: AppTheme.spaceSm,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd,
            0,
            AppTheme.spaceMd,
            AppTheme.spaceLg,
          ),
          iconColor: AppTheme.textSecondaryColor,
          collapsedIconColor: AppTheme.textSecondaryColor,
          leading: Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Text(
            booking.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.body.copyWith(fontWeight: FontWeight.w800),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.flight_rounded, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '$originCountry \u2192 $destCity',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: BookingAcceptanceChip(booking: booking),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (booking.canSeeTracking)
                    _infoChip(
                      icon: Icons.tag_rounded,
                      label:
                          'N\u00b0 ${booking.trackingNumber?.isNotEmpty ?? false ? booking.trackingNumber : QrBookingPayload.refCodeFor(booking.id)}',
                      color: AppTheme.primaryColor,
                    ),
                  _infoChip(
                    icon: Icons.monitor_weight_outlined,
                    label:
                        '${booking.allocatedWeightKg.toStringAsFixed(1)} kg',
                    color: AppTheme.infoColor,
                  ),
                  _infoChip(
                    icon: Icons.payments_outlined,
                    label: '${booking.totalPrice.toStringAsFixed(0)} DZD',
                    color: AppTheme.accentColor,
                  ),
                  _statusChip(statusLabel, statusColor),
                  if (booking.paymentStatus == 'paid')
                    _infoChip(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Pay\u00e9',
                      color: AppTheme.accentColor,
                    )
                  else if (booking.paymentStatus == 'pending')
                    _infoChip(
                      icon: Icons.pending_outlined,
                      label: 'Non pay\u00e9',
                      color: AppTheme.warningColor,
                    ),
                ],
              ),
            ],
          ),
          trailing: booking.canSeeTracking
              ? IconButton(
                  tooltip: 'Billet QR',
                  onPressed: () => showQrTicketDialog(
                    context,
                    booking,
                    onViewDetail: () => Navigator.of(context)
                        .pushNamed('/tracking', arguments: booking.id),
                  ),
                  icon: const Icon(
                    Icons.qr_code_2_rounded,
                    color: AppTheme.primaryColor,
                  ),
                )
              : null,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _statusBadge(delivered),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            _detailRow(
              Icons.flight_takeoff_rounded,
              'Trajet',
              '$originCountry \u2192 $destCity',
            ),
            if (booking.shipment?.flightNumber?.isNotEmpty == true)
              _detailRow(
                Icons.airplanemode_active_rounded,
                'Vol',
                booking.shipment!.airline != null
                    ? '${booking.shipment!.airline} \u00b7 ${booking.shipment!.flightNumber}'
                    : booking.shipment!.flightNumber!,
              ),
            if (booking.shipment?.departureDate != null)
              _detailRow(
                Icons.departure_board_rounded,
                'Depart',
                _formatDate(booking.shipment!.departureDate),
              ),
            _detailRow(
              Icons.monitor_weight_outlined,
              'Poids alloue',
              '${booking.allocatedWeightKg.toStringAsFixed(1)} kg',
            ),
            if (booking.requestedWeightKg != booking.allocatedWeightKg)
              _detailRow(
                Icons.scale_outlined,
                'Poids demande',
                '${booking.requestedWeightKg.toStringAsFixed(1)} kg',
              ),
            if (booking.deliveryAddress?.isNotEmpty == true)
              _detailRow(
                Icons.location_on_outlined,
                'Livraison',
                booking.deliveryAddress!,
              ),
            if (booking.deliveryMethod != null)
              _detailRow(
                Icons.local_shipping_outlined,
                'Mode',
                booking.deliveryMethod == 'courier'
                    ? 'Livraison par coursier'
                    : 'En main propre',
              ),
            if (booking.shipment?.shipper?.user?.fullName != null)
              _detailRow(
                Icons.person_outline_rounded,
                'Expediteur',
                booking.shipment!.shipper!.user!.fullName,
              ),
            const SizedBox(height: AppTheme.spaceMd),
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
                      padding:
                          EdgeInsets.symmetric(vertical: AppTheme.spaceMd),
                      child: Text(
                        'Le suivi sera disponible des la prise en charge '
                        'du colis.',
                        style: AppTheme.bodySecondary,
                      ),
                    )
                  : TrackingTimeline(
                      events: mapShipmentTrackingToTimeline(
                        events,
                        delivered: delivered,
                      ),
                    ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context)
                    .pushNamed('/tracking', arguments: booking.id),
                icon: const Icon(Icons.timeline_rounded, size: 18),
                label: const Text('Ouvrir le suivi detaille'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
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
        ],
      ),
    );
  }

  Widget _statusBadge(bool delivered) {
    final Color color = delivered ? AppTheme.accentColor : AppTheme.infoColor;
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
            delivered
                ? Icons.check_circle_rounded
                : Icons.local_shipping_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            delivered ? 'Livre avec succes' : 'En cours',
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

  static Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppTheme.accentColor;
      case 'shipped':
      case 'arrived':
        return AppTheme.infoColor;
      case 'collected':
      case 'verifying':
      case 'accepted':
        return AppTheme.primaryColor;
      case 'pending':
      case 'confirmed':
        return AppTheme.warningColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.infoColor;
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

String _statusFallbackLabel(String status) {
  switch (status) {
    case 'pending':
      return 'En attente de confirmation';
    case 'confirmed':
      return 'Confirmée';
    default:
      return 'En cours';
  }
}
