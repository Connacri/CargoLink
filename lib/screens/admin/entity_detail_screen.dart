import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../../core/widgets/user_avatar.dart';
import 'user_details_screen.dart';

/// Full, read-only detail page for a shipment (vol) or a booking (commande),
/// used by the founder/admin from the drill-down lists. Everything is wrapped
/// in [SafeArea] so no content hides behind notches or gesture bars.
class EntityDetailScreen extends StatelessWidget {
  final Shipment? shipment;
  final Booking? booking;

  const EntityDetailScreen({super.key, this.shipment, this.booking});

  @override
  Widget build(BuildContext context) {
    if (booking != null) return _BookingDetail(booking: booking!);
    if (shipment != null) return _ShipmentDetail(shipment: shipment!);
    return const Scaffold(body: Center(child: Text('Aucune donnée')));
  }
}

// ============================================================================
// SHIPMENT DETAIL
// ============================================================================

class _ShipmentDetail extends StatelessWidget {
  final Shipment shipment;

  const _ShipmentDetail({required this.shipment});

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  LinearGradient _statusGradient(String status) {
    switch (status) {
      case 'active':
        return AppTheme.successGradient;
      case 'completed':
        return AppTheme.infoGradient;
      case 'cancelled':
        return AppTheme.errorGradient;
      default:
        return AppTheme.warningGradient;
    }
  }

  String _date(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final s = shipment;
    final shipperUser = s.shipper?.user;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CompactSliverHeader(
              title: '${s.originCountry} → ${s.destinationCity}',
              subtitle: 'Détail du vol',
              icon: Icons.flight_takeoff_rounded,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.all(AppTheme.spaceMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LabelValue('Statut', _statusLabel(s.status),
                              badge: _statusGradient(s.status)),
                          const SizedBox(height: AppTheme.spaceSm + 4),
                          if (s.airline != null) ...[
                            _LabelValue('Compagnie', s.airline!),
                            const SizedBox(height: AppTheme.spaceSm + 4),
                          ],
                          _LabelValue('Vol', s.flightNumber ?? '—'),
                          const SizedBox(height: AppTheme.spaceSm + 4),
                          _LabelValue(
                            'Dates',
                            'Départ ${_date(s.departureDate)} → '
                            'Arrivée ${_date(s.arrivalDate)}',
                          ),
                          const SizedBox(height: AppTheme.spaceSm + 4),
                          _LabelValue('Prix', '${s.pricePerKg.toStringAsFixed(0)} DZD/kg'),
                          const SizedBox(height: AppTheme.spaceSm + 4),
                          _LabelValue(
                            'Poids',
                            '${s.availableWeightKg.toStringAsFixed(1)} kg disponibles '
                            '· ${s.reservedWeightKg.toStringAsFixed(1)} kg réservés '
                            '· ${s.remainingWeightKg.toStringAsFixed(1)} kg restants',
                          ),
                        ],
                      ),
                    ),
                    if (s.description != null && s.description!.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spaceSm + 4),
                      GlassCard(
                        padding: const EdgeInsets.all(AppTheme.spaceMd),
                        child: _LabelValue('Description', s.description!),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spaceSm + 4),
                    GlassCard(
                      padding: const EdgeInsets.all(AppTheme.spaceMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expéditeur',
                            style: AppTheme.body
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppTheme.spaceSm + 4),
                          if (shipperUser == null)
                            const Text('Non renseigné', style: AppTheme.caption)
                          else
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: UserAvatar(
                                userId: shipperUser.id,
                                initial: shipperUser.fullName,
                                imageUrl: shipperUser.profilePictureUrl,
                                radius: 18,
                              ),
                              title: Text(
                                shipperUser.fullName,
                                style: AppTheme.body
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                shipperUser.email,
                                style: AppTheme.caption,
                              ),
                              trailing: const Icon(Icons.chevron_right,
                                  color: AppTheme.textSecondaryColor),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => UserDetailsScreen(
                                    user: shipperUser,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BOOKING DETAIL
// ============================================================================

class _BookingDetail extends StatelessWidget {
  final Booking booking;

  const _BookingDetail({required this.booking});

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmé';
      case 'shipped':
        return 'Expédié';
      case 'delivered':
        return 'Livré';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  LinearGradient _statusGradient(String status) {
    switch (status) {
      case 'delivered':
        return AppTheme.successGradient;
      case 'cancelled':
        return AppTheme.errorGradient;
      case 'shipped':
        return AppTheme.infoGradient;
      default:
        return AppTheme.warningGradient;
    }
  }

  String _paymentLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Payé';
      case 'refunded':
        return 'Remboursé';
      case 'pending':
        return 'En attente';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final shipment = b.shipment;
    final client = b.client;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CompactSliverHeader(
              title: b.productName,
              subtitle: 'Détail de la commande',
              icon: Icons.receipt_long_rounded,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.all(AppTheme.spaceMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LabelValue('Statut', _statusLabel(b.status),
                              badge: _statusGradient(b.status)),
                          const SizedBox(height: AppTheme.spaceSm + 4),
                          _LabelValue('Paiement', _paymentLabel(b.paymentStatus)),
                          const SizedBox(height: AppTheme.spaceSm + 4),
                          _LabelValue('Tracking', b.trackingNumber ?? '—'),
                          const SizedBox(height: AppTheme.spaceSm + 4),
                          _LabelValue(
                            'Poids',
                            '${b.requestedWeightKg.toStringAsFixed(1)} kg demandés '
                            '· ${b.allocatedWeightKg.toStringAsFixed(1)} kg alloués',
                          ),
                          const SizedBox(height: AppTheme.spaceSm + 4),
                          _LabelValue('Prix total', '${b.totalPrice.toStringAsFixed(0)} DZD'),
                        ],
                      ),
                    ),
                    if (b.productDescription.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spaceSm + 4),
                      GlassCard(
                        padding: const EdgeInsets.all(AppTheme.spaceMd),
                        child:
                            _LabelValue('Description', b.productDescription),
                      ),
                    ],
                    if (b.productPhotosUrl != null &&
                        b.productPhotosUrl!.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spaceSm + 4),
                      GlassCard(
                        padding: const EdgeInsets.all(AppTheme.spaceMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Photos produit',
                              style: AppTheme.body
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppTheme.spaceSm + 4),
                            SizedBox(
                              height: 72,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: b.productPhotosUrl!.length,
                                separatorBuilder: (_, __) => const SizedBox(
                                    width: AppTheme.spaceSm),
                                itemBuilder: (context, i) => GestureDetector(
                                  onTap: () => showFullScreenImage(
                                    context,
                                    imageUrl: b.productPhotosUrl![i],
                                    title: 'Photo produit ${i + 1}',
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm),
                                    child: Image.network(
                                      b.productPhotosUrl![i],
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 72,
                                        height: 72,
                                        color: AppTheme.surfaceColor,
                                        child: const Icon(
                                            Icons.broken_image_outlined),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (b.deliveryPhotoUrl != null ||
                        b.receiptPhotoUrl != null) ...[
                      const SizedBox(height: AppTheme.spaceSm + 4),
                      GlassCard(
                        padding: const EdgeInsets.all(AppTheme.spaceMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preuves photo de livraison',
                              style: AppTheme.body
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppTheme.spaceSm + 4),
                            Row(
                              children: [
                                if (b.deliveryPhotoUrl != null)
                                  _ProofThumb(
                                    label: 'Livraison',
                                    url: b.deliveryPhotoUrl!,
                                  ),
                                if (b.deliveryPhotoUrl != null &&
                                    b.receiptPhotoUrl != null)
                                  const SizedBox(width: AppTheme.spaceSm),
                                if (b.receiptPhotoUrl != null)
                                  _ProofThumb(
                                    label: 'Réception',
                                    url: b.receiptPhotoUrl!,
                                  ),
                              ],
                            ),
                            if (b.receiptConfirmedAt != null) ...[
                              const SizedBox(height: AppTheme.spaceSm),
                              Text(
                                'Réception confirmée le '
                                '${b.receiptConfirmedAt!.day}/${b.receiptConfirmedAt!.month}/${b.receiptConfirmedAt!.year}',
                                style: AppTheme.caption,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (shipment != null) ...[
                      const SizedBox(height: AppTheme.spaceSm + 4),
                      GlassCard(
                        padding: const EdgeInsets.all(AppTheme.spaceMd),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const AnimatedIconDot(
                            icon: Icons.flight_rounded,
                            color: AppTheme.accentColor,
                          ),
                          title: Text(
                            '${shipment.originCountry} → ${shipment.destinationCity}',
                            style: AppTheme.body
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${shipment.pricePerKg.toStringAsFixed(0)} DZD/kg',
                            style: AppTheme.caption,
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: AppTheme.textSecondaryColor),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EntityDetailScreen(
                                shipment: shipment,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (client != null) ...[
                      const SizedBox(height: AppTheme.spaceSm + 4),
                      GlassCard(
                        padding: const EdgeInsets.all(AppTheme.spaceMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Client',
                              style: AppTheme.body
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppTheme.spaceSm + 4),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: UserAvatar(
                                userId: client.id,
                                initial: client.fullName,
                                imageUrl: client.profilePictureUrl,
                                radius: 18,
                              ),
                              title: Text(
                                client.fullName,
                                style: AppTheme.body
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                client.email,
                                style: AppTheme.caption,
                              ),
                              trailing: const Icon(Icons.chevron_right,
                                  color: AppTheme.textSecondaryColor),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => UserDetailsScreen(user: client),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SHARED LABEL + VALUE ROW
// ============================================================================

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;
  final LinearGradient? badge;

  const _LabelValue(this.label, this.value, {this.badge});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.caption),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (badge != null)
              GradientBadge(label: value, gradient: badge!, compact: true),
          ],
        ),
      ],
    );
  }
}

class _ProofThumb extends StatelessWidget {
  final String label;
  final String url;

  const _ProofThumb({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showFullScreenImage(context, imageUrl: url, title: label),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Image.network(
              url,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 96,
                height: 96,
                color: AppTheme.surfaceColor,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceXs),
          Text(label, style: AppTheme.caption),
        ],
      ),
    );
  }
}
