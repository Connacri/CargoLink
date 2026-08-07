import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../supabase_config.dart';

class TrackingScreen extends ConsumerWidget {
  final String bookingId;

  const TrackingScreen({Key? key, required this.bookingId}) : super(key: key);

  static String statusLabel(String status) {
    switch (status) {
      case 'collected':
        return 'Colis récupéré';
      case 'in_transit':
        return 'En transit';
      case 'customs_cleared':
        return 'Douane passée';
      case 'delivered':
        return 'Livré';
      default:
        return status;
    }
  }

  static IconData statusIcon(String status) {
    switch (status) {
      case 'collected':
        return Icons.inventory_2_outlined;
      case 'in_transit':
        return Icons.local_shipping_outlined;
      case 'customs_cleared':
        return Icons.verified_outlined;
      case 'delivered':
        return Icons.check_circle_outline;
      default:
        return Icons.circle_outlined;
    }
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
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            return _buildTimelineItem(event, events.length - 1 - index);
                          },
                        ),
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
          const SizedBox(height: 8),
          if (booking.shipment != null)
            Text(
              '${booking.shipment!.originCountry} → ${booking.shipment!.destinationCity}',
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
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

  Widget _buildTimelineItem(ShipmentTracking event, int indexFromLatest) {
    final isLatest = indexFromLatest == 0;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLatest ? AppTheme.accentColor : AppTheme.primaryColor,
                ),
                child: isLatest
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: Container(width: 2, color: AppTheme.dividerColor),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        statusIcon(event.status),
                        size: 18,
                        color: AppTheme.textPrimaryColor,
                      ),
                      const SizedBox(width: 8),
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
                  if (event.notes != null && event.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 26, top: 4),
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
