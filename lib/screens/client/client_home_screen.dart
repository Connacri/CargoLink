import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final destination = ref.watch(destinationFilterProvider);
    final origin = ref.watch(originFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final activeShipments = ref.watch(
      activeShipmentsProvider(
        (
          destinationCity: destination,
          originCountry: origin,
          limit: 50,
          offset: 0,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('CargoLink'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _showNotificationsSheet(context, ref),
              child: const _UnreadBadge(),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeShipmentsProvider((
            destinationCity: destination,
            originCountry: origin,
            limit: 50,
            offset: 0,
          )));
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header avec greeting
              _buildHeader(currentUser),

              // Search bar
              _buildSearchBar(context, ref),

              // Filters
              _buildFilters(context, ref),

              // Available shipments
              _buildShipmentsList(activeShipments, searchQuery),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<User?> currentUser) {
    return currentUser.when(
      data: (user) {
        if (user == null) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.primaryLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenue, ${user.fullName}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Trouvez les meilleurs micro-importateurs pour vos commandes',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
        decoration: InputDecoration(
          hintText: 'Rechercher par destination...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref) {
    final destination = ref.watch(destinationFilterProvider);
    final origin = ref.watch(originFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Destination filter
          FilterChip(
            label: Text(destination ?? 'Destination'),
            selected: destination != null,
            onSelected: (selected) {
              if (selected) {
                _showDestinationPicker(context, ref);
              } else {
                ref.read(destinationFilterProvider.notifier).state = null;
              }
            },
          ),
          const SizedBox(width: 8),

          // Origin filter
          FilterChip(
            label: Text(origin ?? 'Origine'),
            selected: origin != null,
            onSelected: (selected) {
              if (selected) {
                _showOriginPicker(context, ref);
              } else {
                ref.read(originFilterProvider.notifier).state = null;
              }
            },
          ),
          const SizedBox(width: 8),

          // Clear filters
          if (destination != null || origin != null)
            FilterChip(
              label: const Text('Effacer'),
              onSelected: (_) {
                ref.read(destinationFilterProvider.notifier).state = null;
                ref.read(originFilterProvider.notifier).state = null;
              },
            ),
        ],
      ),
    );
  }

  Widget _buildShipmentsList(
    AsyncValue<List<Shipment>> shipments,
    String searchQuery,
  ) {
    return shipments.when(
      data: (data) {
        final query = searchQuery.trim().toLowerCase();
        final filtered = query.isEmpty
            ? data
            : data
                .where((s) =>
                    s.originCountry.toLowerCase().contains(query) ||
                    s.destinationCity.toLowerCase().contains(query) ||
                    (s.description?.toLowerCase().contains(query) ?? false))
                .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.local_shipping,
                    size: 64,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun shipment disponible',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _ShipmentCard(shipment: filtered[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Erreur: $error'),
      ),
    );
  }

  void _showDestinationPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        children: AppConstants.majorCities
            .map(
              (city) => ListTile(
                title: Text(city),
                onTap: () {
                  ref.read(destinationFilterProvider.notifier).state = city;
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _showOriginPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        children: AppConstants.populateOrigins
            .map(
              (origin) => ListTile(
                title: Text(origin),
                onTap: () {
                  ref.read(originFilterProvider.notifier).state = origin;
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => NotificationsSheet(),
    );
  }
}

// ============================================================================
// SHIPMENT CARD WIDGET
// ============================================================================

class _ShipmentCard extends ConsumerWidget {
  final Shipment shipment;

  const _ShipmentCard({required this.shipment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToBooking(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              color: AppTheme.primaryLight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${shipment.originCountry} → ${shipment.destinationCity}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Arrive: ${shipment.arrivalDate.day}/${shipment.arrivalDate.month}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Rating
                  if (shipment.shipper != null)
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          shipment.shipper!.ratingDisplay,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Weight info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Poids disponible:'),
                      Text(
                        '${shipment.remainingWeightKg.toStringAsFixed(1)} kg',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Progress bar
                  LinearProgressIndicator(
                    value: shipment.utilizationPercent / 100,
                    minHeight: 6,
                    backgroundColor: AppTheme.dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      shipment.isFull ? AppTheme.errorColor : AppTheme.accentColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Prix par kg:'),
                      Text(
                        '${shipment.pricePerKg.toStringAsFixed(0)} DZD',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer - Book button
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: shipment.isFull
                      ? null
                      : () => _navigateToBooking(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    disabledBackgroundColor: AppTheme.textSecondaryColor,
                  ),
                  child: Text(
                    shipment.isFull ? 'Complet' : 'Réserver',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToBooking(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pushNamed(
      '/booking',
      arguments: shipment.id,
    );
  }
}

// ============================================================================
// NOTIFICATIONS BADGE
// ============================================================================

class _UnreadBadge extends ConsumerWidget {
  const _UnreadBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.read(authServiceProvider).currentUserId;
    if (userId == null) {
      return const Icon(Icons.notifications_outlined);
    }

    final notifs = ref.watch(notificationStreamProvider(userId));

    return notifs.when(
      data: (list) {
        final count = list.where((n) => !n.isRead).length;
        if (count == 0) {
          return const Icon(Icons.notifications_outlined);
        }
        return Badge.count(
          count: count > 99 ? 99 : count,
          child: const Icon(Icons.notifications_outlined),
        );
      },
      loading: () => const Icon(Icons.notifications_outlined),
      error: (error, stack) => const Icon(Icons.notifications_outlined),
    );
  }
}

// ============================================================================
// NOTIFICATIONS SHEET
// ============================================================================

class NotificationsSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final userId = authService.currentUserId;

    if (userId == null) {
      return Center(child: Text('Utilisateur non identifié'));
    }

    final notifications = ref.watch(
      notificationStreamProvider(userId),
    );

    return notifications.when(
      data: (notifs) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(notificationServiceProvider)
                          .markAllAsRead(userId);
                    },
                    child: const Text('Marquer tout comme lu'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: notifs.isEmpty
                  ? Center(child: Text('Aucune notification'))
                  : ListView.builder(
                      itemCount: notifs.length,
                      itemBuilder: (context, index) {
                        final notif = notifs[index];
                        return ListTile(
                          title: Text(notif.title),
                          subtitle: Text(notif.message),
                          trailing: !notif.isRead
                              ? CircleAvatar(
                                  radius: 4,
                                  backgroundColor: AppTheme.primaryColor,
                                )
                              : null,
                          onTap: () {
                            ref
                                .read(notificationServiceProvider)
                                .markAsRead(notif.id);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Erreur: $error')),
    );
  }
}
