import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/enums/app_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../../components/tracking_timeline.dart';
import '../chat/chat_screen.dart';
import '../shipper/shipper_public_profile_screen.dart';

class TrackingScreen extends ConsumerWidget {
  final String bookingId;

  const TrackingScreen({super.key, required this.bookingId});

  /// Ordered list of possible tracking stages (DHL/UPS/FedEx style).
  static const List<String> _order = [
    'order_processed',
    'collected',
    'departed_origin',
    'in_transit',
    'arrived_destination',
    'customs_cleared',
    'out_for_delivery',
    'delivered',
  ];

  static String statusLabel(String status) {
    switch (status) {
      case 'order_processed':
        return 'Commande traitÃ©e';
      case 'collected':
        return 'Colis rÃ©cupÃ©rÃ©';
      case 'departed_origin':
        return 'DÃ©part du pays d\'origine';
      case 'in_transit':
        return 'En transit';
      case 'arrived_destination':
        return 'ArrivÃ© Ã  destination';
      case 'customs_cleared':
        return 'Douane passÃ©e';
      case 'out_for_delivery':
        return 'En cours de livraison';
      case 'delivered':
        return 'LivrÃ©';
      default:
        return status;
    }
  }

  /// Icon per stage: package / truck / flight / plane / delivery.
  static IconData statusIcon(String status) {
    switch (status) {
      case 'order_processed':
        return Icons.inventory_2_outlined;
      case 'collected':
        return Icons.move_to_inbox_outlined;
      case 'departed_origin':
        return Icons.flight_takeoff;
      case 'in_transit':
        return Icons.flight;
      case 'arrived_destination':
        return Icons.flight_land;
      case 'customs_cleared':
        return Icons.verified_outlined;
      case 'out_for_delivery':
        return Icons.flight_takeoff_outlined;
      case 'delivered':
        return Icons.check_circle_outline;
      default:
        return Icons.circle_outlined;
    }
  }

  /// 0-based stage index for the progress bar.
  static int stageIndex(String status) {
    final i = _order.indexOf(status);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingByIdProvider(bookingId));
    final tracking = ref.watch(trackingHistoryProvider(bookingId));

    return booking.when(
      data: (bookingData) {
        if (bookingData == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Suivi de colis')),
            body: const Center(child: Text('RÃ©servation introuvable')),
          );
        }
        return Scaffold(
          floatingActionButton: bookingData.shipment?.shipper?.user != null
              ? FloatingActionButton.extended(
                  heroTag: 'tracking_chat',
                  onPressed: () => _openShipperChat(context, bookingData),
                  icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                  label: const Text('Discuter'),
                )
              : null,
          body: CustomScrollView(
            slivers: [
              GradientSliverHeader(
                title: 'Suivi de colis',
                subtitle: bookingData.productName,
                icon: Icons.connecting_airports_rounded,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceMd,
                    AppTheme.spaceMd,
                    AppTheme.spaceMd,
                    0,
                  ),
                  child: _buildHeader(bookingData),
                ),
              ),
              if (bookingData.shipment?.shipper?.user != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spaceMd,
                      AppTheme.spaceMd,
                      AppTheme.spaceMd,
                      0,
                    ),
                    child: _buildShipperCard(context, bookingData),
                  ),
                ),
              if (bookingData.status == 'delivered')
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spaceMd,
                      AppTheme.spaceMd,
                      AppTheme.spaceMd,
                      0,
                    ),
                    child: _DeliveryProofSection(booking: bookingData),
                  ),
                ),
              if (bookingData.status == 'delivered')
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spaceMd,
                      AppTheme.spaceMd,
                      AppTheme.spaceMd,
                      0,
                    ),
                    child: _RatePrompt(booking: bookingData),
                  ),
                ),
              ...tracking.when<List<Widget>>(
                data: (events) => events.isEmpty
                    ? [SliverToBoxAdapter(child: _buildEmptyTimeline())]
                    : [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppTheme.spaceMd,
                              AppTheme.spaceMd,
                              AppTheme.spaceMd,
                              AppTheme.spaceSm,
                            ),
                            child: _buildProgressBar(
                              stageIndex(events.last.status),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.spaceMd,
                            AppTheme.spaceSm,
                            AppTheme.spaceMd,
                            AppTheme.spaceXxl,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: TrackingTimeline(
                              events: _toTimelineEvents(
                                events,
                                delivered: bookingData.status == 'delivered',
                              ),
                            ),
                          ),
                        ),
                      ],
                loading: () => const [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (e, s) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Erreur: $e')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        body: Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildProgressBar(int latestIndex) {
    return GlassCard(
      child: Row(
        children: List.generate(_order.length, (i) {
          final reached = i <= latestIndex;
          final isLast = i == _order.length - 1;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: reached
                              ? AppTheme.accentColor
                              : AppTheme.surfaceMuted,
                          border: Border.all(
                            color: reached
                                ? AppTheme.accentColor
                                : AppTheme.dividerColor,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          statusIcon(_order[i]),
                          size: 15,
                          color: reached
                              ? Colors.white
                              : AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXs),
                      Text(
                        stageLabel(_order[i]),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 9,
                          height: 1.1,
                          fontWeight:
                              reached ? FontWeight.bold : FontWeight.normal,
                          color: reached
                              ? AppTheme.textPrimaryColor
                              : AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    height: 2,
                    width: 10,
                    color:
                        reached ? AppTheme.accentColor : AppTheme.dividerColor,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String stageLabel(String status) {
    switch (status) {
      case 'order_processed':
        return 'TraitÃ©e';
      case 'collected':
        return 'RÃ©cupÃ©rÃ©';
      case 'departed_origin':
        return 'DÃ©part';
      case 'in_transit':
        return 'Transit';
      case 'arrived_destination':
        return 'ArrivÃ©e';
      case 'customs_cleared':
        return 'Douane';
      case 'out_for_delivery':
        return 'Livraison';
      case 'delivered':
        return 'LivrÃ©';
      default:
        return status;
    }
  }

  void _openShipperChat(BuildContext context, Booking booking) {
    final shipperUser = booking.shipment?.shipper?.user;
    if (shipperUser == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          counterpartUserId: shipperUser.id,
          counterpartName: shipperUser.fullName,
          counterpartAvatarUrl: shipperUser.profilePictureUrl,
          bookingId: booking.id,
        ),
      ),
    );
  }

  Widget _buildShipperCard(BuildContext context, Booking booking) {
    final shipper = booking.shipment?.shipper;
    final shipperUser = shipper?.user;
    if (shipperUser == null) return const SizedBox.shrink();

    final isVerified = shipper?.verificationStatus == 'verified';
    return GlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () {
          if (shipper?.id != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ShipperPublicProfileScreen(shipperId: shipper!.id),
              ),
            );
          }
        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spaceXs,
                    ),
          child: Row(
            children: [
              GradientAvatar(
                initial: shipperUser.fullName,
                imageUrl: shipperUser.profilePictureUrl,
                radius: 22,
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ExpÃ©diteur',
                      style: AppTheme.caption,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            shipperUser.fullName,
                            style: AppTheme.body
                                .copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: AppTheme.spaceXs),
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppTheme.infoColor,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          shipper?.rating != null
                              ? shipper!.rating.toStringAsFixed(1)
                              : 'â€”',
                          style: AppTheme.caption,
                        ),
                        const SizedBox(width: AppTheme.spaceSm),
                        Text(
                          '${shipper?.totalShipments ?? 0} envois',
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppTheme.textMutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Booking booking) {
    final status = BookingStatusExt.fromString(booking.status);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AnimatedIconDot(
                icon: Icons.inventory_2_rounded,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Text(booking.productName, style: AppTheme.h3),
              ),
            ],
          ),
          if (booking.trackingNumber != null &&
              booking.trackingNumber!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                const Icon(
                  Icons.qr_code_2_rounded,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'NÂ° suivi: ${booking.trackingNumber}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
          if (booking.shipment != null) ...[
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                const Icon(
                  Icons.flight_takeoff_rounded,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${booking.shipment!.originCountry} â†’ ${booking.shipment!.destinationCity}',
                    style: AppTheme.bodySecondary,
                  ),
                ),
              ],
            ),
            if (booking.shipment!.flightNumber != null &&
                booking.shipment!.flightNumber!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text(
                  'Vol ${booking.shipment!.flightNumber}',
                  style: AppTheme.caption,
                ),
              ),
            ],
          ],
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            children: [
              GradientBadge(
                label: status.displayName,
                gradient: _bookingGradient(booking.status),
              ),
              const Spacer(),
              Text(
                '${booking.allocatedWeightKg.toStringAsFixed(1)} kg',
                style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTimeline() {
    return const Padding(
      padding: EdgeInsets.all(AppTheme.spaceXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timeline_rounded,
            size: 56,
            color: AppTheme.textMutedColor,
          ),
          SizedBox(height: AppTheme.spaceMd),
          Text('Aucune mise Ã  jour de suivi', style: AppTheme.h3),
          SizedBox(height: AppTheme.spaceSm),
          Text(
            'Le suivi sera disponible dÃ¨s la prise en charge du colis.',
            style: AppTheme.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Maps raw tracking rows (chronological) to the reusable
  /// [TrackingEvent] model consumed by [TrackingTimeline].
  List<TrackingEvent> _toTimelineEvents(
    List<ShipmentTracking> events, {
    required bool delivered,
  }) {
    final mapped = <TrackingEvent>[];
    for (var i = events.length - 1; i >= 0; i--) {
      final event = events[i];
      final isLatest = i == events.length - 1;
      final description = <String>[
        if (event.location != null && event.location!.isNotEmpty)
          '${event.location}',
        if (event.notes != null && event.notes!.isNotEmpty) '${event.notes}',
      ].join(' â€¢ ');
      mapped.add(
        TrackingEvent(
          title: statusLabel(event.status),
          timestamp: event.timestamp,
          status: isLatest
              ? (delivered
                  ? TrackingStatus.completed
                  : TrackingStatus.inProgress)
              : TrackingStatus.completed,
          description: description.isEmpty ? null : description,
        ),
      );
    }
    return mapped;
  }
}

/// Shows the shipper's delivery proof photo and lets the client confirm
/// receipt by taking a photo of their own.
class _DeliveryProofSection extends ConsumerWidget {
  final Booking booking;

  const _DeliveryProofSection({required this.booking});

  Future<void> _confirmReceipt(BuildContext context, WidgetRef ref) async {
    final photo = await pickProofPhoto(context, title: 'Confirmation de rÃ©ception');
    if (photo == null) return;
    try {
      final url = await ref
          .read(storageServiceProvider)
          .uploadBookingProofPhoto(
            file: photo,
            bookingId: booking.id,
            type: 'receipt',
          );
      await ref.read(bookingServiceProvider).confirmReceipt(
            booking.id,
            receiptPhotoUrl: url,
          );
      final shipperId = booking.shipment?.shipperId;
      if (shipperId != null) {
        await ref.read(notificationServiceProvider).notifyShipperReceiptConfirmed(
              shipperId: shipperId,
              bookingId: booking.id,
            );
      }
      ref.invalidate(bookingByIdProvider(booking.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('RÃ©ception confirmÃ©e. Merci !'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryPhoto = booking.deliveryPhotoUrl;
    final receiptPhoto = booking.receiptPhotoUrl;
    final receiptConfirmed = booking.receiptConfirmedAt != null;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Preuve de livraison',
            style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          if (deliveryPhoto != null && deliveryPhoto.isNotEmpty) ...[
            GestureDetector(
              onTap: () =>
                  showFullScreenImage(context, imageUrl: deliveryPhoto),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Image.network(
                  deliveryPhoto,
                  height: 160,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: AppTheme.surfaceMuted,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined,
                        color: AppTheme.textSecondaryColor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            const Text(
              'Photo prise par l\'expÃ©diteur Ã  la livraison. '
              'Touchez pour agrandir.',
              style: AppTheme.caption,
            ),
          ] else
            const Text(
              'Aucune preuve photo fournie par l\'expÃ©diteur.',
              style: AppTheme.caption,
            ),
          if (!receiptConfirmed) ...[
            const SizedBox(height: AppTheme.spaceMd),
            FilledButton.icon(
              onPressed: () => _confirmReceipt(context, ref),
              icon: const Icon(Icons.verified_rounded, size: 18),
              label: const Text('Confirmer la rÃ©ception'),
            ),
          ] else ...[
            const SizedBox(height: AppTheme.spaceMd),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.accentColor, size: 18),
                const SizedBox(width: AppTheme.spaceXs),
                Expanded(
                  child: Text(
                    'RÃ©ception confirmÃ©e le '
                    '${booking.receiptConfirmedAt!.day}/${booking.receiptConfirmedAt!.month}/${booking.receiptConfirmedAt!.year}',
                    style: AppTheme.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (receiptPhoto != null && receiptPhoto.isNotEmpty)
                  IconButton(
                    onPressed: () =>
                        showFullScreenImage(context, imageUrl: receiptPhoto),
                    icon: const Icon(Icons.photo_rounded),
                    tooltip: 'Voir ma confirmation',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Prompts the client to rate the shipper once the parcel is delivered.
class _RatePrompt extends ConsumerWidget {
  final Booking booking;

  const _RatePrompt({required this.booking});

  Future<void> _rate(BuildContext context, WidgetRef ref) async {
    final shipment = booking.shipment;
    final shipperId = shipment?.shipperId;
    if (shipment == null || shipperId == null) return;
    final clientId = ref.read(authServiceProvider).currentUserId;
    if (clientId == null) return;

    final submitted = await showRateShipperSheet(
      context,
      shipperName: shipment.shipper?.user?.fullName ?? 'l\'expÃ©diteur',
      onSubmit: (rating, comment) async {
        await ref.read(reviewServiceProvider).submitReview(
              bookingId: booking.id,
              shipmentId: booking.shipmentId,
              shipperId: shipperId,
              clientId: clientId,
              rating: rating,
              comment: comment,
            );
        ref.invalidate(hasReviewedProvider(booking.id));
      },
    );

    if (submitted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci pour votre avis !'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rated = ref.watch(hasReviewedProvider(booking.id)).valueOrNull;

    return GlassCard(
      child: Row(
        children: [
          const AnimatedIconDot(
            icon: Icons.star_rounded,
            color: Colors.amber,
          ),
          const SizedBox(width: AppTheme.spaceSm + 4),
          Expanded(
            child: Text(
              rated == true
                  ? 'ExpÃ©diteur notÃ©. Merci !'
                  : 'Colis reÃ§u ? Notez votre expÃ©diteur.',
              style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: AppTheme.spaceSm),
          FilledButton.icon(
            onPressed: rated == true ? null : () => _rate(context, ref),
            icon: const Icon(Icons.star_rounded, size: 18),
            label: Text(rated == true ? 'NotÃ©' : 'Noter'),
          ),
        ],
      ),
    );
  }
}

LinearGradient _bookingGradient(String status) {
  switch (status) {
    case 'pending':
      return AppTheme.warningGradient;
    case 'confirmed':
      return AppTheme.primaryGradient;
    case 'shipped':
      return AppTheme.infoGradient;
    case 'delivered':
      return AppTheme.successGradient;
    case 'cancelled':
      return AppTheme.errorGradient;
    default:
      return AppTheme.primaryGradient;
  }
}
