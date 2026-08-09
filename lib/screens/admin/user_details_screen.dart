import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';

/// Full dossier of a single user for the founder dashboard: profile,
/// shipper record (if any), shipments, bookings, payments and disputes.
class UserDetailsScreen extends ConsumerStatefulWidget {
  final User user;
  const UserDetailsScreen({Key? key, required this.user}) : super(key: key);

  @override
  ConsumerState<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends ConsumerState<UserDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isShipper = user.role == 'shipper';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dossier utilisateur'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Profil'),
            Tab(text: 'Expéditions'),
            Tab(text: 'Commandes'),
            Tab(text: 'Finance'),
            Tab(text: 'Litiges'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProfileTab(user: user),
          isShipper
              ? _ShipmentsTab(user: user)
              : const _EmptyTab(
                  message: 'Aucune expédition (rôle non-expéditeur)'),
          _OrdersTab(user: user),
          _FinanceTab(user: user),
          _DisputesTab(user: user),
        ],
      ),
    );
  }
}

// ============================================================================
// PROFILE
// ============================================================================

class _ProfileTab extends ConsumerWidget {
  final User user;
  const _ProfileTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipper = ref.watch(shipperByUserIdProvider(user.id));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppTheme.primaryLight,
              backgroundImage: user.profilePictureUrl != null
                  ? NetworkImage(user.profilePictureUrl!)
                  : null,
              child: user.profilePictureUrl == null
                  ? const Icon(Icons.person,
                      size: 32, color: AppTheme.primaryColor)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _pill(_roleLabel(user.role), _roleColor(user.role)),
                      const SizedBox(width: 6),
                      _pill(
                        user.isActive ? 'Actif' : 'Désactivé',
                        user.isActive
                            ? AppTheme.accentColor
                            : AppTheme.errorColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _infoCard('Informations du compte', [
          _row('Téléphone', user.phone),
          _row('Membre depuis', _formatDate(user.createdAt)),
          if (user.deactivatedAt != null)
            _row('Désactivé le', _formatDate(user.deactivatedAt!)),
          if (user.deletionRequestedAt != null)
            _row(
                'Suppression demandée', _formatDate(user.deletionRequestedAt!)),
        ]),
        const SizedBox(height: 12),
        _infoCard('Réseaux sociaux', [
          _row('WeChat', user.wechat ?? '—'),
          _row('WhatsApp', user.whatsapp ?? '—'),
          _row('Telegram', user.telegram ?? '—'),
          _row('Facebook', user.facebook ?? '—'),
          _row('Instagram', user.instagram ?? '—'),
          _row('TikTok', user.tiktok ?? '—'),
        ]),
        if (user.role == 'shipper') ...[
          const SizedBox(height: 12),
          shipper.when(
            data: (s) => _infoCard('Dossier expéditeur', [
              if (s == null)
                const Text('Aucun dossier expéditeur',
                    style: TextStyle(color: AppTheme.textSecondaryColor))
              else ...[
                _row('Statut', _verificationLabel(s.verificationStatus)),
                _row('Passeport', s.passportNumber),
                _row('Note', s.ratingDisplay),
                _row('Expéditions', '${s.totalShipments}'),
                _row('Rejeté', s.rejectionReason ?? '—'),
                if (s.verifiedAt != null)
                  _row('Vérifié le', _formatDate(s.verifiedAt!)),
              ],
            ]),
            loading: () => const LinearProgressIndicator(),
            error: (e, s) => const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
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

  Color _roleColor(String role) {
    switch (role) {
      case 'shipper':
        return AppTheme.warningColor;
      case 'admin':
        return AppTheme.errorColor;
      case 'super_admin':
        return AppTheme.primaryDark;
      default:
        return AppTheme.accentColor;
    }
  }

  String _verificationLabel(String status) {
    switch (status) {
      case 'verified':
        return 'Vérifié';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'En attente';
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

// ============================================================================
// SHIPMENTS (shipper's published flights)
// ============================================================================

class _ShipmentsTab extends ConsumerWidget {
  final User user;
  const _ShipmentsTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipper = ref.watch(shipperByUserIdProvider(user.id));

    return shipper.when(
      data: (s) {
        if (s == null) {
          return const _EmptyTab(message: 'Aucun dossier expéditeur');
        }
        final shipments = ref.watch(userShipmentsProvider(s.id));
        return shipments.when(
          data: (items) {
            if (items.isEmpty) {
              return const _EmptyTab(message: 'Aucune expédition publiée');
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final sh = items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading:
                        const Icon(Icons.flight, color: AppTheme.accentColor),
                    title: Text(
                      '${sh.originCountry} → ${sh.destinationCity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    subtitle: Text(
                      '${sh.pricePerKg} DZD/kg · ${sh.availableWeightKg}kg dispo · '
                      '${sh.reservedWeightKg}kg réservé · ${sh.status}\n'
                      'Départ ${_date(sh.departureDate)} · Arrivée ${_date(sh.arrivalDate)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Erreur: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const _EmptyTab(message: 'Erreur chargement'),
    );
  }

  String _date(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ============================================================================
// ORDERS (bookings as client)
// ============================================================================

class _OrdersTab extends ConsumerWidget {
  final User user;
  const _OrdersTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(userBookingsProvider(user.id));
    return bookings.when(
      data: (items) {
        if (items.isEmpty) {
          return const _EmptyTab(message: 'Aucune commande');
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
                  '${b.totalPrice} DZD · ${b.status} · Paiement ${b.paymentStatus}\n'
                  '${b.shipment?.originCountry ?? ''}→${b.shipment?.destinationCity ?? ''} · '
                  '${b.allocatedWeightKg}kg',
                  style: const TextStyle(fontSize: 12),
                ),
                isThreeLine: true,
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
// FINANCE (payments)
// ============================================================================

class _FinanceTab extends ConsumerWidget {
  final User user;
  const _FinanceTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(userPaymentsProvider(user.id));
    return payments.when(
      data: (items) {
        final total = items.fold<double>(0, (sum, p) => sum + p.amount);
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              color: AppTheme.surfaceColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        color: AppTheme.accentColor, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      '${total.toStringAsFixed(0)} DZD',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const Text(
                      'Total payé',
                      style: TextStyle(
                          color: AppTheme.textSecondaryColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Aucun paiement',
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                ),
              )
            else
              ...items.map(
                (p) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      p.isCompleted ? Icons.check_circle : Icons.pending,
                      color: p.isCompleted
                          ? AppTheme.accentColor
                          : AppTheme.warningColor,
                    ),
                    title: Text(
                      '${p.amount.toStringAsFixed(0)} ${p.currency}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    subtitle: Text(
                      '${p.status} · ${p.paymentMethod ?? '—'} · ${_date(p.createdAt)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
    );
  }

  String _date(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ============================================================================
// DISPUTES
// ============================================================================

class _DisputesTab extends ConsumerWidget {
  final User user;
  const _DisputesTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disputes = ref.watch(userDisputesProvider(user.id));
    return disputes.when(
      data: (items) {
        if (items.isEmpty) {
          return const _EmptyTab(message: 'Aucun litige');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final d = items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  Icons.gavel,
                  color: d.isOpen ? AppTheme.errorColor : AppTheme.accentColor,
                ),
                title: Text(
                  _typeLabel(d.type),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                subtitle: Text(
                  '${d.status} · ${_date(d.createdAt)}\n${d.description}',
                  style: const TextStyle(fontSize: 12),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'fraud':
        return 'Fraude';
      case 'customs_seizure':
        return 'Saisie Douane';
      case 'damage':
        return 'Endommagé';
      case 'non_delivery':
        return 'Non Livré';
      default:
        return 'Autre';
    }
  }

  String _date(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyTab extends StatelessWidget {
  final String message;
  const _EmptyTab({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondaryColor),
        ),
      ),
    );
  }
}
