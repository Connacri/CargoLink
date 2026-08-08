import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../supabase_config.dart';
import '../error_dialog.dart';

// ============================================================================
// SHIPPER DASHBOARD
// ============================================================================

class ShipperDashboardScreen extends ConsumerStatefulWidget {
  const ShipperDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ShipperDashboardScreen> createState() =>
      _ShipperDashboardScreenState();
}

class _ShipperDashboardScreenState extends ConsumerState<ShipperDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final shipper = ref.watch(currentShipperProvider);

    return shipper.when(
      data: (shipperData) {
        if (shipperData == null || !shipperData.isVerified) {
          return _buildNotVerified(shipperData);
        }
        return _buildDashboard(shipperData);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Erreur: $e'))),
    );
  }

  Widget _buildNotVerified(Shipper? shipper) {
    final isRejected = shipper?.isRejected ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isRejected
                    ? Icons.error_outline
                    : Icons.verified_user_outlined,
                size: 72,
                color: isRejected ? AppTheme.errorColor : AppTheme.warningColor,
              ),
              const SizedBox(height: 16),
              Text(
                isRejected
                    ? 'Votre dossier a été rejeté'
                    : 'Dossier en attente de vérification',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isRejected
                    ? shipper?.rejectionReason ??
                        'Veuillez soumettre à nouveau vos documents.'
                    : 'Un administrateur doit valider votre identité avant '
                        'de pouvoir publier des offres de transport.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .pushNamed('/shipper-registration'),
                child: Text(isRejected ? 'Soumettre à nouveau' : 'Voir mon dossier'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(Shipper shipper) {
    final stats = ref.watch(shipperStatsProvider(shipper.id));
    final shipments = ref.watch(shipperShipmentsProvider((
      shipperId: shipper.id,
      limit: 10,
      offset: 0,
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(shipperStatsProvider(shipper.id));
          ref.invalidate(shipperShipmentsProvider((
            shipperId: shipper.id,
            limit: 10,
            offset: 0,
          )));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatsGrid(stats.valueOrNull),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Offres récentes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showPublishDialog(shipper.id),
                  icon: const Icon(Icons.add),
                  label: const Text('Publier'),
                ),
              ],
            ),
            shipments.when(
              data: (items) => items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Aucune offre publiée. Publiez votre première offre !',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      ),
                    )
                  : Column(
                      children: items
                          .map((s) => _ShipmentMiniCard(shipment: s))
                          .toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Erreur: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic>? stats) {
    return Row(
      children: [
        _statCard(
          'Offres',
          '${stats?['total_shipments'] ?? 0}',
          Icons.local_shipping,
          AppTheme.primaryColor,
        ),
        _statCard(
          'Commandes',
          '${stats?['total_bookings'] ?? 0}',
          Icons.receipt_long,
          AppTheme.accentColor,
        ),
        _statCard(
          'Actives',
          '${stats?['active_shipments'] ?? 0}',
          Icons.play_circle,
          AppTheme.warningColor,
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setSheetState(() => originCountry = v ?? originCountry),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: destinationCity,
                    decoration: const InputDecoration(labelText: 'Destination'),
                    items: AppConstants.majorCities
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setSheetState(() => destinationCity = v ?? destinationCity),
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
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setSheetState(() => departure = date);
                            }
                          },
                          icon: const Icon(Icons.flight_takeoff, size: 18),
                          label: Text(
                            'Départ ${departure.day}/${departure.month}',
                          ),
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
                              lastDate: DateTime.now().add(const Duration(days: 365)),
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
                                    description: descriptionController.text
                                            .isEmpty
                                        ? null
                                        : descriptionController.text,
                                  );
                              ref.invalidate(shipperShipmentsProvider((
                                shipperId: shipperId,
                                limit: 10,
                                offset: 0,
                              )));
                              ref.invalidate(
                                  shipperStatsProvider(shipperId));
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

class _ShipmentMiniCard extends ConsumerWidget {
  final Shipment shipment;

  const _ShipmentMiniCard({required this.shipment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.primaryLight,
          child: Icon(Icons.local_shipping, color: AppTheme.primaryColor),
        ),
        title: Text(
          '${shipment.originCountry} → ${shipment.destinationCity}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${shipment.remainingWeightKg.toStringAsFixed(1)} kg restants • '
          '${shipment.pricePerKg.toStringAsFixed(0)} DZD/kg',
        ),
        trailing: shipment.isFull
            ? const Icon(Icons.check_circle, color: AppTheme.accentColor)
            : null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShipperShipmentDetailScreen(shipment: shipment),
          ),
        ),
      ),
    );
  }
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
  @override
  Widget build(BuildContext context) {
    final shipper = ref.watch(currentShipperProvider);

    return shipper.when(
      data: (shipperData) {
        if (shipperData == null || !shipperData.isVerified) {
          return const Center(
            child: Text(
              'Complétez votre dossier de vérification pour voir vos offres',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          );
        }
        return _buildList(shipperData);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _buildList(Shipper shipper) {
    final shipments = ref.watch(shipperShipmentsProvider((
      shipperId: shipper.id,
      limit: 100,
      offset: 0,
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Offres'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(shipperShipmentsProvider((
            shipperId: shipper.id,
            limit: 100,
            offset: 0,
          )));
        },
        child: shipments.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Text(
                  'Aucune offre. Publiez depuis le tableau de bord.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _ShipmentMiniCard(shipment: items[index]);
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
// SHIPMENT DETAIL + BOOKING MANAGEMENT
// ============================================================================

class ShipperShipmentDetailScreen extends ConsumerWidget {
  final Shipment shipment;

  const ShipperShipmentDetailScreen({Key? key, required this.shipment})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(shipmentBookingsProvider((
      shipmentId: shipment.id,
      limit: 100,
      offset: 0,
    )));

    return Scaffold(
      appBar: AppBar(
        title: Text('${shipment.originCountry} → ${shipment.destinationCity}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(shipmentBookingsProvider((
            shipmentId: shipment.id,
            limit: 100,
            offset: 0,
          )));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummary(),
            const SizedBox(height: 16),
            const Text(
              'Commandes reçues',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            bookings.when(
              data: (items) => items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Aucune commande pour cette offre',
                          style: TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      ),
                    )
                  : Column(
                      children: items
                          .map((b) => _ManageBookingCard(booking: b))
                          .toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Erreur: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Poids total', style: _labelStyle),
                Text(
                  '${shipment.availableWeightKg.toStringAsFixed(1)} kg',
                  style: _valueStyle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Réservé', style: _labelStyle),
                Text(
                  '${shipment.reservedWeightKg.toStringAsFixed(1)} kg',
                  style: _valueStyle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Restant', style: _labelStyle),
                Text(
                  '${shipment.remainingWeightKg.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            LinearProgressIndicator(
              value: shipment.utilizationPercent / 100,
              minHeight: 8,
              backgroundColor: AppTheme.dividerColor,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Prix/kg', style: _labelStyle),
                Text(
                  '${shipment.pricePerKg.toStringAsFixed(0)} DZD',
                  style: _valueStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const _labelStyle =
      TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14);
  static const _valueStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: AppTheme.textPrimaryColor,
    fontSize: 14,
  );
}

// ============================================================================
// BOOKING MANAGEMENT CARD
// ============================================================================

class _ManageBookingCard extends ConsumerWidget {
  final Booking booking;

  const _ManageBookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = BookingStatusExt.fromString(booking.status).color;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    BookingStatusExt.fromString(booking.status).displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${booking.client?.fullName ?? 'Client'} • '
              '${booking.allocatedWeightKg.toStringAsFixed(1)} kg • '
              '${booking.totalPrice.toStringAsFixed(0)} DZD',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
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
          ElevatedButton(
            onPressed: () => _confirmBooking(context, ref),
            child: const Text('Confirmer'),
          ),
        );
        actions.add(
          TextButton(
            onPressed: () => _cancelBooking(context, ref),
            child: const Text('Refuser', style: TextStyle(color: AppTheme.errorColor)),
          ),
        );
        break;
      case 'confirmed':
        actions.add(
          ElevatedButton(
            onPressed: () => _markShipped(context, ref),
            child: const Text('Marquer expédié'),
          ),
        );
        actions.add(
          TextButton(
            onPressed: () => _cancelBooking(context, ref),
            child: const Text('Annuler', style: TextStyle(color: AppTheme.errorColor)),
          ),
        );
        break;
      case 'shipped':
        actions.add(
          ElevatedButton(
            onPressed: () => _markDelivered(context, ref),
            child: const Text('Marquer livré'),
          ),
        );
        break;
    }

    return Wrap(
      spacing: 8,
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
            status: 'in_transit',
            notes: 'Colis expédié depuis ${booking.shipment?.originCountry}',
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
    ref.invalidate(shipmentBookingsProvider((
      shipmentId: booking.shipmentId,
      limit: 100,
      offset: 0,
    )));
    ref.invalidate(shipperShipmentsProvider((
      shipperId: booking.shipment?.shipperId ?? '',
      limit: 100,
      offset: 0,
    )));
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
