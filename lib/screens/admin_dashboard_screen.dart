import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../supabase_config.dart';
import '../error_dialog.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Annonces',
            icon: const Icon(Icons.campaign),
            onPressed: () =>
                Navigator.of(context).pushNamed('/broadcast'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.verified_user), text: 'Expéditeurs'),
            Tab(icon: Icon(Icons.gavel), text: 'Litiges'),
            Tab(icon: Icon(Icons.monetization_on), text: 'Revenus'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ShippersTab(),
          _DisputesTab(),
          _RevenueTab(),
        ],
      ),
    );
  }
}

// ============================================================================
// SHIPPERS VERIFICATION TAB
// ============================================================================

class _ShippersTab extends ConsumerWidget {
  const _ShippersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(pendingShippersProvider((limit: 100, offset: 0)));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(pendingShippersProvider((limit: 100, offset: 0)));
      },
      child: list.when(
        data: (shippers) {
          if (shippers.isEmpty) {
            return const Center(
              child: Text(
                'Aucun dossier en attente',
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: shippers.length,
            itemBuilder: (context, index) {
              return _ShipperVerificationCard(shipper: shippers[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _ShipperVerificationCard extends ConsumerWidget {
  final Shipper shipper;

  const _ShipperVerificationCard({required this.shipper});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminId = ref.read(authServiceProvider).currentUserId ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryLight,
                  child: Text(
                    (shipper.user?.fullName ?? '?')
                        .split(' ')
                        .map((w) => w.isNotEmpty ? w[0] : '')
                        .take(2)
                        .join(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shipper.user?.fullName ?? 'Utilisateur',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        'Passport: ${shipper.passportNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (shipper.passportPhotoUrl.isNotEmpty)
              _preview(context, 'Photo passeport', shipper.passportPhotoUrl),
            if (shipper.livePhotoUrl.isNotEmpty)
              _preview(context, 'Photo en direct', shipper.livePhotoUrl),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _verify(context, ref, adminId),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Vérifier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(context, ref, adminId),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rejeter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(BuildContext context, String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 80,
                child: Center(child: Text('Aperçu indisponible')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verify(BuildContext context, WidgetRef ref, String adminId) async {
    try {
      await ref.read(shipperServiceProvider).verifyShipper(
            shipperId: shipper.id,
            adminId: adminId,
          );
      ref.invalidate(pendingShippersProvider((limit: 100, offset: 0)));
      // Refresh the verified shipper so their dashboard unlocks
      ref.invalidate(currentShipperProvider);
      ref.invalidate(shipperByIdProvider(shipper.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expéditeur vérifié'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      _showError(context, e);
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, String adminId) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter le dossier'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Motif du rejet'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, reasonController.text.trim()),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await ref.read(shipperServiceProvider).rejectShipper(
            shipperId: shipper.id,
            adminId: adminId,
            rejectionReason: reason,
          );
      ref.invalidate(pendingShippersProvider((limit: 100, offset: 0)));
    } catch (e) {
      _showError(context, e);
    }
  }

  void _showError(BuildContext context, Object error) {
    if (!context.mounted) return;
    showAppErrorDialog(context, message: 'Erreur: $error');
  }
}

// ============================================================================
// DISPUTES TAB
// ============================================================================

class _DisputesTab extends ConsumerWidget {
  const _DisputesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(openDisputesProvider((limit: 100, offset: 0)));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(openDisputesProvider((limit: 100, offset: 0)));
      },
      child: list.when(
        data: (disputes) {
          if (disputes.isEmpty) {
            return const Center(
              child: Text(
                'Aucun litige ouvert',
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: disputes.length,
            itemBuilder: (context, index) {
              return _DisputeCard(dispute: disputes[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _DisputeCard extends ConsumerWidget {
  final Dispute dispute;

  const _DisputeCard({required this.dispute});

  static String _disputeTypeLabel(String type) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.gavel,
                  size: 18,
                  color: dispute.type == 'fraud'
                      ? AppTheme.errorColor
                      : AppTheme.warningColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _disputeTypeLabel(dispute.type),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dispute.description,
              style: const TextStyle(color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _resolveInFavorOfClient(context, ref),
                    icon: const Icon(Icons.thumb_up, size: 18),
                    label: const Text('Rembourser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(context, ref),
                    icon: const Icon(Icons.thumb_down, size: 18),
                    label: const Text('Rejeter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolveWithStatus(
    BuildContext context,
    WidgetRef ref,
    String label, {
    required bool refund,
  }) async {
    final controller = TextEditingController();
    final resolution = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Résolution'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (resolution == null || resolution.isEmpty) return;

    try {
      if (refund) {
        await ref.read(disputeServiceProvider).resolveInFavorOfClient(
              disputeId: dispute.id,
              resolution: resolution,
            );
      } else {
        await ref.read(disputeServiceProvider).rejectDispute(
              disputeId: dispute.id,
              resolution: resolution,
            );
      }
      ref.invalidate(openDisputesProvider((limit: 100, offset: 0)));
    } catch (e) {
      if (context.mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    }
  }

  Future<void> _resolveInFavorOfClient(BuildContext context, WidgetRef ref) =>
      _resolveWithStatus(context, ref, 'Résolution en faveur du client (remboursement)', refund: true);

  Future<void> _reject(BuildContext context, WidgetRef ref) =>
      _resolveWithStatus(context, ref, 'Rejeter le litige', refund: false);
}

// ============================================================================
// REVENUE TAB
// ============================================================================

class _RevenueTab extends ConsumerWidget {
  const _RevenueTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenue = ref.watch(revenueStatsProvider((startDate: null, endDate: null)));

    return revenue.when(
      data: (stats) {
        final total = (stats?['total_revenue'] as num?)?.toDouble() ?? 0;
        final transactions = (stats?['total_transactions'] as num?)?.toInt() ?? 0;
        final average = (stats?['average_transaction'] as num?)?.toDouble() ?? 0;
        final commission = total * AppConstants.platformCommissionPercent / 100;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: AppTheme.surfaceColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.trending_up,
                        color: AppTheme.accentColor, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      '${total.toStringAsFixed(0)} ${AppConstants.defaultCurrency}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const Text(
                      'Chiffre d\'affaires',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _revenueRow('Transactions', transactions.toString()),
            _revenueRow('Panier moyen', '${average.toStringAsFixed(0)} DZD'),
            _revenueRow(
              'Commission plateforme (${AppConstants.platformCommissionPercent}%)',
              '${commission.toStringAsFixed(0)} DZD',
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _revenueRow(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor)),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ),
    );
  }
}