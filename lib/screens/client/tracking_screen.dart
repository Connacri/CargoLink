import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/enums/app_enums.dart';
import '../../core/theme/app_theme.dart';

class TrackingScreen extends ConsumerWidget {
  final String bookingId;

  const TrackingScreen({Key? key, required this.bookingId}) : super(key: key);

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
        return 'Commande traitée';
      case 'collected':
        return 'Colis récupéré';
      case 'departed_origin':
        return 'Départ du pays d\'origine';
      case 'in_transit':
        return 'En transit';
      case 'arrived_destination':
        return 'Arrivé à destination';
      case 'customs_cleared':
        return 'Douane passée';
      case 'out_for_delivery':
        return 'En cours de livraison';
      case 'delivered':
        return 'Livré';
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
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.check_circle_outline;
      default:
        return Icons.circle_outlined;
    }
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'order_processed':
        return AppTheme.textSecondaryColor;
      case 'collected':
        return AppTheme.warningColor;
      case 'departed_origin':
        return AppTheme.primaryColor;
      case 'in_transit':
        return AppTheme.primaryColor;
      case 'arrived_destination':
        return AppTheme.primaryColor;
      case 'customs_cleared':
        return AppTheme.warningColor;
      case 'out_for_delivery':
        return AppTheme.accentColor;
      case 'delivered':
        return AppTheme.accentColor;
      default:
        return AppTheme.textSecondaryColor;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de colis'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: booking.when(
        data: (bookingData) {
          if (bookingData == null) {
            return const Center(child: Text('Réservation introuvable'));
          }
          return Column(
            children: [
              _buildHeader(bookingData),
              const Divider(height: 1),
              Expanded(
                child: tracking.when(
                  data: (events) => events.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucune mise à jour de suivi pour le moment',
                            style: TextStyle(color: AppTheme.textSecondaryColor),
                          ),
                        )
                      : _buildProgressAndTimeline(events),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, s) => Center(child: Text('Erreur: $e')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildProgressAndTimeline(List<ShipmentTracking> events) {
    final latest = events.last;
    final latestIndex = stageIndex(latest.status);
    return Column(
      children: [
        _buildProgressBar(latestIndex),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[events.length - 1 - index];
              return _buildTimelineItem(event, index == 0);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(int latestIndex) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: AppTheme.backgroundColor,
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
                              : AppTheme.dividerColor,
                        ),
                        child: Icon(
                          statusIcon(_order[i]),
                          size: 15,
                          color: reached ? Colors.white : AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _order[i] == 'delivered'
                            ? 'Livré'
                            : stageLabel(_order[i]),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 9,
                          height: 1.1,
                          fontWeight: reached ? FontWeight.bold : FontWeight.normal,
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
                    color: reached ? AppTheme.accentColor : AppTheme.dividerColor,
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
        return 'Traitée';
      case 'collected':
        return 'Récupéré';
      case 'departed_origin':
        return 'Départ';
      case 'in_transit':
        return 'Transit';
      case 'arrived_destination':
        return 'Arrivée';
      case 'customs_cleared':
        return 'Douane';
      case 'out_for_delivery':
        return 'Livraison';
      case 'delivered':
        return 'Livré';
      default:
        return status;
    }
  }

  Widget _buildHeader(Booking booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: AppTheme.primaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  booking.productName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (booking.trackingNumber != null &&
              booking.trackingNumber!.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.qr_code_2,
                    size: 16, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 6),
                Text(
                  'N° suivi: ${booking.trackingNumber}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          if (booking.shipment != null)
            Row(
              children: [
                const Icon(Icons.flight_takeoff,
                    size: 16, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${booking.shipment!.originCountry} → ${booking.shipment!.destinationCity}',
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          if (booking.shipment?.flightNumber != null &&
              booking.shipment!.flightNumber!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 4),
              child: Text(
                'Vol ${booking.shipment!.flightNumber}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statusChip(booking.status),
              const Spacer(),
              Text(
                '${booking.allocatedWeightKg.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = BookingStatusExt.fromString(status).color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        BookingStatusExt.fromString(status).displayName,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTimelineItem(ShipmentTracking event, bool isLatest) {
    final color = statusColor(event.status);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLatest ? AppTheme.accentColor : color.withOpacity(0.15),
                  border: Border.all(color: isLatest ? AppTheme.accentColor : color, width: 1.5),
                ),
                child: Icon(
                  statusIcon(event.status),
                  size: 17,
                  color: isLatest ? Colors.white : color,
                ),
              ),
              Expanded(
                child: Container(width: 2, color: AppTheme.dividerColor),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          statusLabel(event.status),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(event.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (event.location != null && event.location!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: AppTheme.textSecondaryColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (event.notes != null && event.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        event.notes!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
