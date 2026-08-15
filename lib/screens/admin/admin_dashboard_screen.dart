import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';
import '../../core/widgets/chat_widgets.dart';
import 'transactions_screen.dart';
import 'commission_screen.dart';
import 'inventory_screen.dart';
import 'depot_detail_screen.dart';

// ============================================================================
// PAGINATED PROVIDERS (local to this screen)
// ============================================================================

final pendingShippersPagerProvider = StateNotifierProvider<
    PaginatedListNotifier<Shipper>, PaginatedList<Shipper>>((ref) {
  return createPaginatedNotifier(
    (limit, offset) => ref
        .read(shipperServiceProvider)
        .getPendingShippers(limit: limit, offset: offset),
    pageSize: 10,
  );
});

final openDisputesPagerProvider = StateNotifierProvider<
    PaginatedListNotifier<Dispute>, PaginatedList<Dispute>>((ref) {
  return createPaginatedNotifier(
    (limit, offset) => ref
        .read(disputeServiceProvider)
        .getOpenDisputes(limit: limit, offset: offset),
    pageSize: 10,
  );
});

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

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
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pendingShippersPagerProvider.notifier).loadInitial();
      ref.read(openDisputesPagerProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          GradientSliverHeader(
            title: '',
            subtitle: 'Vérification, litiges et revenus',
            icon: Icons.shield_outlined,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ChatInboxBadge(),
                IconButton(
                  tooltip: 'Annonces',
                  icon: const Icon(Icons.campaign, color: Colors.white),
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/broadcast'),
                ),
                const LogoutIconButton(),
              ],
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondaryColor,
                indicatorColor: AppTheme.primaryColor,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.verified_user), text: 'Expéditeurs'),
                  Tab(icon: Icon(Icons.gavel), text: 'Litiges'),
                  Tab(icon: Icon(Icons.monetization_on), text: 'Revenus'),
                  Tab(icon: Icon(Icons.warehouse_outlined), text: 'Inventaire'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ShippersTab(),
            _DisputesTab(),
            _RevenueTab(),
            _InventoryTab(),
          ],
        ),
      ),
    );
  }
}

// Delegate that makes the TabBar stick below the gradient header.
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}

// ============================================================================
// SHIPPERS VERIFICATION TAB
// ============================================================================

class _ShippersTab extends ConsumerWidget {
  const _ShippersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pager = ref.watch(pendingShippersPagerProvider);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(pendingShippersPagerProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spaceMd,
                AppTheme.spaceMd,
                AppTheme.spaceMd,
                AppTheme.spaceSm,
              ),
              child: Text(
                'Dossiers en attente de vérification',
                style: AppTheme.h3,
              ),
            ),
          ),
          PagedSliverList<Shipper>(
            paginatedList: pager,
            padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd, 0, AppTheme.spaceMd, AppTheme.spaceXxl),
            emptyState: const _EmptyTabState(
              icon: Icons.fact_check_outlined,
              message: 'Aucun dossier en attente',
            ),
            itemBuilder: (context, shipper, index) => StaggeredEntrance(
              delay: Duration(milliseconds: (index % 10) * 40),
              child: _ShipperVerificationCard(shipper: shipper),
            ),
          ),
        ],
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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GradientAvatar(
                  initial: shipper.user?.fullName ?? '?',
                  imageUrl: shipper.user?.profilePictureUrl,
                  radius: 20,
                ),
                const SizedBox(width: AppTheme.spaceSm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shipper.user?.fullName ?? 'Utilisateur',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Passport: ${shipper.passportNumber}',
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm + 4),
            if (shipper.passportPhotoUrl.isNotEmpty)
              _preview(context, 'Photo passeport', shipper.passportPhotoUrl),
            if (shipper.livePhotoUrl.isNotEmpty)
              _preview(context, 'Photo en direct', shipper.livePhotoUrl),
            const SizedBox(height: AppTheme.spaceSm + 4),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _verify(context, ref, adminId),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Vérifier'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(context, ref, adminId),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rejeter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.red,
                      minimumSize: const Size(48, 48),
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
          Text(label, style: AppTheme.caption),
          const SizedBox(height: AppTheme.spaceXs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Image.network(
              url,
              height: 80,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 80,
                child: Center(
                  child: Text('Aperçu indisponible',
                      style: AppTheme.bodySecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verify(
      BuildContext context, WidgetRef ref, String adminId) async {
    try {
      await ref.read(shipperServiceProvider).verifyShipper(
            shipperId: shipper.id,
            adminId: adminId,
          );
      ref.read(pendingShippersPagerProvider.notifier).refresh();
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
      if (context.mounted) _showError(context, e);
    }
  }

  Future<void> _reject(
      BuildContext context, WidgetRef ref, String adminId) async {
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
      ref.read(pendingShippersPagerProvider.notifier).refresh();
    } catch (e) {
      if (context.mounted) _showError(context, e);
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
    final pager = ref.watch(openDisputesPagerProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(openDisputesPagerProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spaceMd,
                AppTheme.spaceMd,
                AppTheme.spaceMd,
                AppTheme.spaceSm,
              ),
              child: Text(
                'Litiges ouverts',
                style: AppTheme.h3,
              ),
            ),
          ),
          PagedSliverList<Dispute>(
            paginatedList: pager,
            padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd, 0, AppTheme.spaceMd, AppTheme.spaceXxl),
            emptyState: const _EmptyTabState(
              icon: Icons.verified_user_outlined,
              message: 'Aucun litige ouvert',
            ),
            itemBuilder: (context, dispute, index) => StaggeredEntrance(
              delay: Duration(milliseconds: (index % 10) * 40),
              child: _DisputeCard(dispute: dispute),
            ),
          ),
        ],
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
    final isFraud = dispute.type == 'fraud';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedIconDot(
                  icon: Icons.gavel_rounded,
                  color: isFraud ? AppTheme.errorColor : AppTheme.warningColor,
                ),
                const SizedBox(width: AppTheme.spaceSm + 4),
                Expanded(
                  child: Text(
                    _disputeTypeLabel(dispute.type),
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              dispute.description,
              style: AppTheme.bodySecondary,
            ),
            const SizedBox(height: AppTheme.spaceSm + 4),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _resolveInFavorOfClient(context, ref),
                    icon: const Icon(Icons.thumb_up, size: 18),
                    label: const FittedBox(child: Text('Rembourser')),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(context, ref),
                    icon: const Icon(Icons.thumb_down, size: 18),
                    label: const Text('Rejeter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.red,
                      minimumSize: const Size(48, 48),
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
      ref.read(openDisputesPagerProvider.notifier).refresh();
    } catch (e) {
      if (context.mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    }
  }

  Future<void> _resolveInFavorOfClient(BuildContext context, WidgetRef ref) =>
      _resolveWithStatus(
          context, ref, 'Résolution en faveur du client (remboursement)',
          refund: true);

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
    final revenue =
        ref.watch(revenueStatsProvider((startDate: null, endDate: null)));
    final settings = ref.watch(platformSettingsProvider);
    final rate = settings.valueOrNull?.commissionPercent ??
        AppConstants.platformCommissionPercent;
    final currency = settings.valueOrNull?.defaultCurrency ??
        AppConstants.defaultCurrency;

    return revenue.when(
      data: (stats) {
        final total = (stats?['total_revenue'] as num?)?.toDouble() ?? 0;
        final transactions =
            (stats?['total_transactions'] as num?)?.toInt() ?? 0;
        final average =
            (stats?['average_transaction'] as num?)?.toDouble() ?? 0;
        final commission = total * rate / 100;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: _RevenueHero(total: total, currency: currency),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMd,
                ),
                child: _RevenueRow(
                  icon: Icons.swap_horiz_rounded,
                  color: AppTheme.infoColor,
                  label: 'Transactions',
                  value: transactions.toString(),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TransactionsScreen(),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd,
                    AppTheme.spaceSm, AppTheme.spaceMd, AppTheme.spaceSm),
                child: _RevenueRow(
                  icon: Icons.calculate_outlined,
                  color: AppTheme.primaryColor,
                  label: 'Panier moyen',
                  value: '${average.toStringAsFixed(0)} $currency',
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceMd,
                    AppTheme.spaceSm,
                    AppTheme.spaceMd,
                    AppTheme.spaceXxl),
                child: _RevenueRow(
                  icon: Icons.percent_rounded,
                  color: AppTheme.warningColor,
                  label: 'Commission plateforme ($rate%)',
                  value: '${commission.toStringAsFixed(0)} $currency',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CommissionScreen(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Text('Erreur: $e', style: AppTheme.bodySecondary),
      ),
    );
  }
}

class _RevenueHero extends StatelessWidget {
  const _RevenueHero({required this.total, required this.currency});

  final double total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowLg,
      ),
      child: Column(
        children: [
          const Icon(Icons.trending_up_rounded,
              color: Colors.white, size: 40),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            '${total.toStringAsFixed(0)} $currency',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Chiffre d\'affaires',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}

class _RevenueRow extends StatelessWidget {
  const _RevenueRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        onTap: onTap,
        child: Row(
          children: [
            AnimatedIconDot(icon: icon, color: color),
            const SizedBox(width: AppTheme.spaceSm + 4),
            Expanded(
              child: Text(
                label,
                style: AppTheme.bodySecondary,
              ),
            ),
            Text(
              value,
              style: AppTheme.body.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppTheme.textMutedColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// INVENTORY TAB (dépôts de collecte des colis)
// ============================================================================

class _InventoryTab extends ConsumerWidget {
  const _InventoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depots = ref.watch(depotsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(depotsProvider),
      child: depots.when(
        data: (items) => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMd,
                  AppTheme.spaceMd,
                  AppTheme.spaceMd,
                  AppTheme.spaceSm,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Dépôts de collecte',
                        style: AppTheme.h3,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        final created = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => const DepotFormScreen(),
                          ),
                        );
                        if (created == true) {
                          ref.invalidate(depotsProvider);
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Dépôt'),
                    ),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: AppTheme.spaceXxl),
                  child: _EmptyTabState(
                    icon: Icons.warehouse_outlined,
                    message: 'Aucun dépôt pour l\'instant',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMd,
                  0,
                  AppTheme.spaceMd,
                  AppTheme.spaceXxl,
                ),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) => StaggeredEntrance(
                    delay: Duration(milliseconds: (index % 10) * 40),
                    child: _DepotSummaryCard(depot: items[index]),
                  ),
                ),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Text('Erreur: $e', style: AppTheme.bodySecondary),
        ),
      ),
    );
  }
}

class _DepotSummaryCard extends ConsumerWidget {
  const _DepotSummaryCard({required this.depot});

  final Depot depot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(depotStatsProvider(depot.id));
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DepotDetailScreen(depot: depot),
          ),
        ),
        child: Row(
          children: [
            const AnimatedIconDot(
              icon: Icons.warehouse_rounded,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: AppTheme.spaceSm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    depot.name,
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (depot.city != null)
                    Text(
                      depot.city!,
                      style: AppTheme.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            stats.when(
              data: (s) => Text(
                '${s?['stored'] ?? 0} colis',
                style: AppTheme.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.infoColor,
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (e, s) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppTheme.textMutedColor,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyTabState extends StatelessWidget {
  const _EmptyTabState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 56, color: AppTheme.textMutedColor),
        const SizedBox(height: AppTheme.spaceMd),
        Text(message, style: AppTheme.h3),
      ],
    );
  }
}
