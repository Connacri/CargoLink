import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import 'user_details_screen.dart';

enum EntityListType { users, shipments, bookings }

/// Generic drill-down screen opened from a stats card. Shows a grid or list
/// depending on the entity type, and lets the super_admin open a full user
/// dossier from any row that references a user.
class EntityListScreen extends ConsumerWidget {
  final EntityListType type;
  final String? roleFilter;

  const EntityListScreen({Key? key, required this.type, this.roleFilter})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String title;
    switch (type) {
      case EntityListType.users:
        title = roleFilter == null
            ? 'Tous les utilisateurs'
            : 'Utilisateurs · ${_roleLabel(roleFilter!)}';
        break;
      case EntityListType.shipments:
        title = 'Vols / Expéditions';
        break;
      case EntityListType.bookings:
        title = 'Commandes';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    switch (type) {
      case EntityListType.users:
        return _UsersList(roleFilter: roleFilter);
      case EntityListType.shipments:
        return _ShipmentsList();
      case EntityListType.bookings:
        return _BookingsList();
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'shipper':
        return 'Expéditeurs';
      case 'admin':
        return 'Admins';
      case 'super_admin':
        return 'Fondateurs';
      default:
        return 'Clients';
    }
  }
}

// ============================================================================
// USERS (grid)
// ============================================================================

class _UsersList extends ConsumerWidget {
  final String? roleFilter;
  const _UsersList({this.roleFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(allUsersProvider);
    return users.when(
      data: (all) {
        final filtered = roleFilter == null
            ? all
            : all.where((u) => u.role == roleFilter).toList();
        if (filtered.isEmpty) {
          return const Center(
            child: Text(
              'Aucun utilisateur',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.3,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final user = filtered[index];
            return _UserGridCard(user: user);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
    );
  }
}

class _UserGridCard extends ConsumerWidget {
  final User user;
  const _UserGridCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserDetailsScreen(user: user),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryLight,
                backgroundImage: user.profilePictureUrl != null
                    ? NetworkImage(user.profilePictureUrl!)
                    : null,
                child: user.profilePictureUrl == null
                    ? const Icon(Icons.person, color: AppTheme.primaryColor)
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                user.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _roleLabel(user.role),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'shipper':
        return 'Expéditeur';
      case 'admin':
        return 'Admin';
      case 'super_admin':
        return 'Fondateur';
      default:
        return 'Client';
    }
  }
}

// ============================================================================
// SHIPMENTS (list)
// ============================================================================

class _ShipmentsList extends ConsumerWidget {
  const _ShipmentsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipments = ref.watch(allShipmentsProvider);
    return shipments.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'Aucun vol',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final s = items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.flight, color: AppTheme.accentColor),
                title: Text(
                  '${s.originCountry} → ${s.destinationCity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                subtitle: Text(
                  '${s.pricePerKg} DZD/kg · ${s.availableWeightKg}kg dispo · '
                  '${s.status}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: s.shipper?.user != null
                    ? InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => UserDetailsScreen(
                              user: s.shipper!.user!,
                            ),
                          ),
                        ),
                        child: const CircleAvatar(
                          radius: 14,
                          backgroundColor: AppTheme.primaryLight,
                          child: Icon(Icons.person,
                              size: 16, color: AppTheme.primaryColor),
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
    );
  }
}

// ============================================================================
// BOOKINGS (list)
// ============================================================================

class _BookingsList extends ConsumerWidget {
  const _BookingsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(allBookingsProvider);
    return bookings.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'Aucune commande',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final b = items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.receipt_long,
                    color: AppTheme.primaryColor),
                title: Text(
                  b.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                subtitle: Text(
                  '${b.totalPrice} DZD · ${b.status} · '
                  '${b.shipment?.originCountry ?? ''}→${b.shipment?.destinationCity ?? ''}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: b.client != null
                    ? InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => UserDetailsScreen(user: b.client!),
                          ),
                        ),
                        child: const CircleAvatar(
                          radius: 14,
                          backgroundColor: AppTheme.primaryLight,
                          child: Icon(Icons.person,
                              size: 16, color: AppTheme.primaryColor),
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
    );
  }
}
