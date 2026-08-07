import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../supabase_config.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  String? _statusFilter;

  Future<void> _cancelBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la commande'),
        content: const Text(
          'Voulez-vous vraiment annuler cette commande ? '
          'Le poids réservé sera libéré et le paiement remboursé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(bookingServiceProvider).cancelBooking(bookingId);
        final userId = ref.read(authServiceProvider).currentUserId;
        if (userId != null) {
          ref.invalidate(clientBookingsProvider((
            clientId: userId,
            status: _statusFilter,
            limit: 100,
            offset: 0,
          )));
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Commande annulée et remboursée'),
              backgroundColor: AppTheme.accentColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authServiceProvider).currentUserId;
    if (userId == null) {
      return const Center(child: Text('Utilisateur non identifié'));
    }

    final bookings = ref.watch(clientBookingsProvider((
      clientId: userId,
      status: _statusFilter,
      limit: 100,
      offset: 0,
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Commandes'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _statusFilter = value == 'all' ? null : value;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'all', child: Text('Toutes')),
              PopupMenuItem(value: 'pending', child: Text('En attente')),
              PopupMenuItem(value: 'confirmed', child: Text('Confirmées')),
              PopupMenuItem(value: 'shipped', child: Text('Expédiées')),
              PopupMenuItem(value: 'delivered', child: Text('Livrées')),
              PopupMenuItem(value: 'cancelled', child: Text('Annulées')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(clientBookingsProvider((
            clientId: userId,
            status: _statusFilter,
            limit: 100,
            offset: 0,
          )));
        },
        child: bookings.when(
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: AppTheme.textSecondaryColor,
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Aucune commande',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _BookingCard(
                  booking: items[index],
                  onTrack: () => Navigator.of(context)
                      .pushNamed('/tracking', arguments: items[index].id),
                  onCancel: (items[index].status == 'pending' ||
                          items[index].paymentStatus == 'pending')
                      ? () => _cancelBooking(items[index].id)
                      : null,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Erreur: $e')),
        ),
      ),
    );
  }
}

// ============================================================================
// BOOKING CARD
// ============================================================================

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTrack;
  final VoidCallback? onCancel;

  const _BookingCard({
    required this.booking,
    required this.onTrack,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = BookingStatusExt.fromString(booking.status).color;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    BookingStatusExt.fromString(booking.status).displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
                  fontSize: 13,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${booking.allocatedWeightKg.toStringAsFixed(1)} kg',
                  style: const TextStyle(color: AppTheme.textSecondaryColor),
                ),
                Text(
                  '${booking.totalPrice.toStringAsFixed(0)} ${AppConstants.defaultCurrency}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Paiement: ${booking.isPaid ? 'Payé' : 'En attente'}',
              style: TextStyle(
                fontSize: 12,
                color: booking.isPaid
                    ? AppTheme.accentColor
                    : AppTheme.warningColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTrack,
                    icon: const Icon(Icons.route, size: 18),
                    label: const Text('Suivre'),
                  ),
                ),
                if (onCancel != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Annuler'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}