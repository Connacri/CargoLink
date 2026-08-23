import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/micro_badge.dart';
import '../../core/widgets/ui_kit.dart';
import '../chat/chat_screen.dart';

// ============================================================================
// PAGINATED PROVIDERS (local to this screen)
// ============================================================================

final userShipmentsPagerProvider = StateNotifierProvider.family<
    PaginatedListNotifier<Shipment>, PaginatedList<Shipment>, String>(
  (ref, shipperId) {
    return createPaginatedNotifier(
      (limit, offset) => ref.read(shipmentServiceProvider).getShipperShipments(
            shipperId: shipperId,
            limit: limit,
            offset: offset,
          ),
      pageSize: 15,
    );
  },
);

final userBookingsPagerProvider = StateNotifierProvider.family<
    PaginatedListNotifier<Booking>, PaginatedList<Booking>, String>(
  (ref, clientId) {
    return createPaginatedNotifier(
      (limit, offset) => ref.read(bookingServiceProvider).getClientBookings(
            clientId: clientId,
            limit: limit,
            offset: offset,
          ),
      pageSize: 15,
    );
  },
);

enum _AdminAction { toggleActive, delete, chat }

/// Full dossier of a single user for the founder dashboard: profile,
/// shipper record (if any), shipments, bookings, payments and disputes.
class UserDetailsScreen extends ConsumerStatefulWidget {
  final User user;
  const UserDetailsScreen({super.key, required this.user});

  @override
  ConsumerState<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends ConsumerState<UserDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _lastBookingsKey = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBookingsPager());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Never touch a pager provider while the widget tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBookingsPager());
  }

  void _syncBookingsPager() {
    final key = widget.user.id;
    if (key == _lastBookingsKey) return;
    _lastBookingsKey = key;
    ref.read(userBookingsPagerProvider(key).notifier).loadInitial();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openChat() async {
    final myId = ref.read(authServiceProvider).currentUserId;
    if (myId == null) return;
    final user = widget.user;
    if (user.id == myId) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          counterpartUserId: user.id,
          counterpartName: user.fullName,
          counterpartAvatarUrl: user.profilePictureUrl,
        ),
      ),
    );
  }

  Future<void> _toggleActive() async {
    final user = widget.user;
    try {
      await ref
          .read(authServiceProvider)
          .setUserActive(user.id, !user.isActive);
      ref.invalidate(shipperByUserIdProvider(user.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(user.isActive ? 'Compte désactivé' : 'Compte réactivé'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    }
  }

  Future<void> _deleteUser() async {
    final user = widget.user;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer définitivement le compte'),
        content: Text(
          'Toutes les données de "${user.fullName}" (${user.email}) seront '
          'supprimées : commandes, offres, fichiers, compte auth. '
          'Cette action est irréversible.\n\nContinuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(authServiceProvider).deleteUserAsAdmin(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte supprimé définitivement'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isShipper = user.role == 'shipper';

    return Scaffold(
      body: SafeArea(
        top: false,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            CompactSliverHeader(
              title: 'Dossier',
              subtitle: user.fullName,
              icon: Icons.folder_shared_outlined,
              trailing: PopupMenuButton<_AdminAction>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (action) async {
                  switch (action) {
                    case _AdminAction.chat:
                      await _openChat();
                      break;
                    case _AdminAction.toggleActive:
                      await _toggleActive();
                      break;
                    case _AdminAction.delete:
                      await _deleteUser();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _AdminAction.chat,
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            color: AppTheme.infoColor),
                        SizedBox(width: 8),
                        Text('Contacter'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _AdminAction.toggleActive,
                    child: Text(
                      user.isActive
                          ? 'Désactiver le compte'
                          : 'Réactiver le compte',
                    ),
                  ),
                  const PopupMenuItem(
                    value: _AdminAction.delete,
                    child: Text(
                      'Supprimer définitivement',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                  ),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textSecondaryColor,
                  indicatorColor: AppTheme.primaryColor,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Profil'),
                    Tab(text: 'Expéditions'),
                    Tab(text: 'Commandes'),
                    Tab(text: 'Finance'),
                    Tab(text: 'Litiges'),
                  ],
                ),
              ),
            ),
          ],
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
// PROFILE
// ============================================================================

class _ProfileTab extends ConsumerWidget {
  final User user;
  const _ProfileTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipper = ref.watch(shipperByUserIdProvider(user.id));
    final isShipper = user.role == 'shipper';

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  child: Row(
                    children: [
                      GradientAvatar(
                        initial: user.fullName,
                        imageUrl: user.profilePictureUrl,
                        radius: 28,
                      ),
                      const SizedBox(width: AppTheme.spaceMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.h3,
                            ),
                            Text(
                              user.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.bodySecondary,
                            ),
                            const SizedBox(height: AppTheme.spaceSm),
                            Wrap(
                              spacing: AppTheme.spaceXs,
                              runSpacing: AppTheme.spaceXs,
                              children: [
                                GradientBadge(
                                  label: _roleLabel(user.role),
                                  gradient: _roleGradient(user.role),
                                  compact: true,
                                ),
                                GradientBadge(
                                  label: user.isActive ? 'Actif' : 'Désactivé',
                                  gradient: user.isActive
                                      ? AppTheme.successGradient
                                      : AppTheme.errorGradient,
                                  compact: true,
                                ),
                                if (isShipper)
                                  shipper.maybeWhen(
                                    data: (s) => s == null
                                        ? const SizedBox.shrink()
                                        : ShipperTypeBadge(
                                            isMicroImportateur:
                                                s.isMicroImportateur),
                                    orElse: () => const SizedBox.shrink(),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSm + 4),
                _infoCard('Informations du compte', [
                  if (user.phone.trim().isNotEmpty)
                    _row('Téléphone', user.phone),
                  _row('Membre depuis', _formatDate(user.createdAt)),
                  if (user.deactivatedAt != null)
                    _row('Désactivé le', _formatDate(user.deactivatedAt!)),
                  if (user.deletionRequestedAt != null)
                    _row('Suppression demandée',
                        _formatDate(user.deletionRequestedAt!)),
                ]),
                if (_hasAnySocial(user)) ...[
                  const SizedBox(height: AppTheme.spaceSm + 4),
                  _infoCard('Réseaux sociaux', _socialRows(user)),
                ],
                if (isShipper) ...[
                  const SizedBox(height: AppTheme.spaceSm + 4),
                  shipper.when(
                    data: (s) => _infoCard('Dossier expéditeur', [
                      if (s == null)
                        const Text('Aucun dossier expéditeur',
                            style: AppTheme.bodySecondary)
                      else ...[
                        _row(
                            'Type',
                            s.isMicroImportateur
                                ? 'Micro-Importateur'
                                : 'Voyageur ordinaire'),
                        _row(
                            'Statut', _verificationLabel(s.verificationStatus)),
                        _row('Passeport', s.passportNumber),
                        _row('Note', s.ratingDisplay),
                        _row('Expéditions', '${s.totalShipments}'),
                        _row('Rejeté', s.rejectionReason ?? '—'),
                        if (s.verifiedAt != null)
                          _row('Vérifié le', _formatDate(s.verifiedAt!)),
                      ],
                    ]),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppTheme.spaceSm),
                      child: LinearProgressIndicator(),
                    ),
                    error: (e, s) => const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXs - 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(label, style: AppTheme.caption),
            ),
            Expanded(
              child: Text(
                value,
                style: AppTheme.body.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );

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

  LinearGradient _roleGradient(String role) {
    switch (role) {
      case 'shipper':
        return AppTheme.warningGradient;
      case 'admin':
        return AppTheme.errorGradient;
      case 'super_admin':
        return AppTheme.darkGradient;
      default:
        return AppTheme.successGradient;
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

  bool _hasAnySocial(User u) =>
      (u.wechat?.isNotEmpty ?? false) ||
      (u.whatsapp?.isNotEmpty ?? false) ||
      (u.telegram?.isNotEmpty ?? false) ||
      (u.facebook?.isNotEmpty ?? false) ||
      (u.instagram?.isNotEmpty ?? false) ||
      (u.tiktok?.isNotEmpty ?? false);

  List<Widget> _socialRows(User u) => [
        if (u.whatsapp?.isNotEmpty ?? false) _row('WhatsApp', u.whatsapp!),
        if (u.telegram?.isNotEmpty ?? false) _row('Telegram', u.telegram!),
        if (u.wechat?.isNotEmpty ?? false) _row('WeChat', u.wechat!),
        if (u.facebook?.isNotEmpty ?? false) _row('Facebook', u.facebook!),
        if (u.instagram?.isNotEmpty ?? false) _row('Instagram', u.instagram!),
        if (u.tiktok?.isNotEmpty ?? false) _row('TikTok', u.tiktok!),
      ];
}

// ============================================================================
// SHIPMENTS (shipper's published flights) — paginated
// ============================================================================

class _ShipmentsTab extends ConsumerStatefulWidget {
  final User user;
  const _ShipmentsTab({required this.user});

  @override
  ConsumerState<_ShipmentsTab> createState() => _ShipmentsTabState();
}

class _ShipmentsTabState extends ConsumerState<_ShipmentsTab> {
  String? _shipperId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Never touch a pager provider while the widget tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  void _sync() {
    final shipper = ref.read(shipperByUserIdProvider(widget.user.id)).value;
    final id = shipper?.id;
    if (id == null || id == _shipperId) return;
    _shipperId = id;
    ref.read(userShipmentsPagerProvider(id).notifier).loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final shipper = ref.watch(shipperByUserIdProvider(widget.user.id));

    return shipper.when(
      data: (s) {
        if (s == null) {
          return const _EmptyTab(message: 'Aucun dossier expéditeur');
        }
        final pager = ref.watch(userShipmentsPagerProvider(s.id));
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            PagedSliverList<Shipment>(
              paginatedList: pager,
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              emptyState: const _EmptyTab(message: 'Aucune expédition publiée'),
              itemBuilder: (context, sh, index) => StaggeredEntrance(
                delay: Duration(milliseconds: (index % 10) * 40),
                child: _ShipmentRow(shipment: sh),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const _EmptyTab(message: 'Erreur chargement'),
    );
  }
}

// ============================================================================
// ORDERS (bookings as client) — paginated
// ============================================================================

class _OrdersTab extends ConsumerWidget {
  final User user;
  const _OrdersTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pager = ref.watch(userBookingsPagerProvider(user.id));

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        PagedSliverList<Booking>(
          paginatedList: pager,
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          emptyState: const _EmptyTab(message: 'Aucune commande'),
          itemBuilder: (context, b, index) => StaggeredEntrance(
            delay: Duration(milliseconds: (index % 10) * 40),
            child: _BookingRow(booking: b),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// FINANCE (payments) — simple list (service has no offset pagination)
// ============================================================================

class _FinanceTab extends ConsumerWidget {
  final User user;
  const _FinanceTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(userPaymentsProvider(user.id));

    return payments.when(
      data: (items) {
        final completed = items.where((p) => p.isCompleted).toList();
        final totalPaid = completed.fold<double>(0, (sum, p) => sum + p.amount);
        final totalAll = items.fold<double>(0, (sum, p) => sum + p.amount);
        final pending = items.where((p) => p.status == 'pending').length;
        final refunded = items.where((p) => p.status == 'refunded').length;
        final failed = items.where((p) => p.status == 'failed').length;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FinanceStats(
                      totalPaid: totalPaid,
                      totalAll: totalAll,
                      count: items.length,
                      pending: pending,
                      refunded: refunded,
                      failed: failed,
                    ),
                    const SizedBox(height: AppTheme.spaceLg),
                    Text(
                      'Transactions (${items.length})',
                      style: AppTheme.h3,
                    ),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyTab(message: 'Aucun paiement'),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceMd, 0, AppTheme.spaceMd, AppTheme.spaceXxl),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) => StaggeredEntrance(
                    delay: Duration(milliseconds: (index % 10) * 40),
                    child: _PaymentRow(payment: items[index]),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) =>
          Center(child: Text('Erreur: $e', style: AppTheme.bodySecondary)),
    );
  }
}

/// Statistics block for the "Finance" tab: totals and status breakdown for the
/// selected user (client payments + shipper earnings combined).
class _FinanceStats extends StatelessWidget {
  const _FinanceStats({
    required this.totalPaid,
    required this.totalAll,
    required this.count,
    required this.pending,
    required this.refunded,
    required this.failed,
  });

  final double totalPaid;
  final double totalAll;
  final int count;
  final int pending;
  final int refunded;
  final int failed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          decoration: BoxDecoration(
            gradient: AppTheme.successGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.shadowLg,
          ),
          child: Column(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 32),
              const SizedBox(height: AppTheme.spaceSm),
              Text(
                '${totalPaid.toStringAsFixed(0)} DZD',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'Total payé (réglé)',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.receipt_long_rounded,
                label: 'Transactions',
                value: '$count',
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: _StatTile(
                icon: Icons.payments_rounded,
                label: 'Total global',
                value: totalAll.toStringAsFixed(0),
                color: AppTheme.accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.schedule_rounded,
                label: 'En attente',
                value: '$pending',
                color: AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: _StatTile(
                icon: Icons.replay_rounded,
                label: 'Remboursés',
                value: '$refunded',
                color: AppTheme.infoColor,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: _StatTile(
                icon: Icons.error_rounded,
                label: 'Échoués',
                value: '$failed',
                color: AppTheme.errorColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXs),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DISPUTES — simple list (service has no offset pagination)
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
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              sliver: SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, index) => StaggeredEntrance(
                  delay: Duration(milliseconds: (index % 10) * 40),
                  child: _DisputeRow(dispute: items[index]),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) =>
          Center(child: Text('Erreur: $e', style: AppTheme.bodySecondary)),
    );
  }
}

// ============================================================================
// ROW WIDGETS
// ============================================================================

class _ShipmentRow extends StatelessWidget {
  const _ShipmentRow({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final s = shipment;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        child: Row(
          children: [
            const AnimatedIconDot(
              icon: Icons.flight_rounded,
              color: AppTheme.accentColor,
            ),
            const SizedBox(width: AppTheme.spaceSm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${s.originCountry} → ${s.destinationCity}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.pricePerKg.toStringAsFixed(0)} DZD/kg · '
                    '${s.availableWeightKg.toStringAsFixed(0)}kg dispo · '
                    '${s.reservedWeightKg.toStringAsFixed(0)}kg réservé\n'
                    'Départ ${_date(s.departureDate)} · '
                    'Arrivée ${_date(s.arrivalDate)}',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
            GradientBadge(
              label: _statusLabel(s.status),
              gradient: _statusGradient(s.status),
              compact: true,
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  LinearGradient _statusGradient(String status) {
    switch (status) {
      case 'active':
        return AppTheme.successGradient;
      case 'completed':
        return AppTheme.infoGradient;
      case 'cancelled':
        return AppTheme.errorGradient;
      default:
        return AppTheme.warningGradient;
    }
  }

  String _date(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        child: Row(
          children: [
            const AnimatedIconDot(
              icon: Icons.receipt_long_rounded,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: AppTheme.spaceSm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${b.totalPrice.toStringAsFixed(0)} DZD · ${b.status} · '
                    'Paiement ${b.paymentStatus}\n'
                    '${b.shipment?.originCountry ?? ''}→'
                    '${b.shipment?.destinationCity ?? ''} · '
                    '${b.allocatedWeightKg.toStringAsFixed(0)}kg',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
            GradientBadge(
              label: _statusLabel(b.status),
              gradient: _statusGradient(b.status),
              compact: true,
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmé';
      case 'shipped':
        return 'Expédié';
      case 'delivered':
        return 'Livré';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  LinearGradient _statusGradient(String status) {
    switch (status) {
      case 'delivered':
        return AppTheme.successGradient;
      case 'cancelled':
        return AppTheme.errorGradient;
      case 'shipped':
        return AppTheme.infoGradient;
      default:
        return AppTheme.warningGradient;
    }
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        child: Row(
          children: [
            AnimatedIconDot(
              icon: p.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.pending_rounded,
              color:
                  p.isCompleted ? AppTheme.accentColor : AppTheme.warningColor,
            ),
            const SizedBox(width: AppTheme.spaceSm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${p.amount.toStringAsFixed(0)} ${p.currency}',
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${p.status} · ${p.paymentMethod ?? '—'} · '
                    '${_date(p.createdAt)}',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
            GradientBadge(
              label: p.isCompleted ? 'Payé' : p.status,
              gradient: p.isCompleted
                  ? AppTheme.successGradient
                  : AppTheme.warningGradient,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }

  String _date(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _DisputeRow extends StatelessWidget {
  const _DisputeRow({required this.dispute});

  final Dispute dispute;

  @override
  Widget build(BuildContext context) {
    final d = dispute;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        child: Row(
          children: [
            AnimatedIconDot(
              icon: Icons.gavel_rounded,
              color: d.isOpen ? AppTheme.errorColor : AppTheme.accentColor,
            ),
            const SizedBox(width: AppTheme.spaceSm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _typeLabel(d.type),
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${d.status} · ${_date(d.createdAt)}\n${d.description}',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
            GradientBadge(
              label: d.isOpen ? 'Ouvert' : 'Fermé',
              gradient:
                  d.isOpen ? AppTheme.errorGradient : AppTheme.successGradient,
              compact: true,
            ),
          ],
        ),
      ),
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
        padding: const EdgeInsets.all(AppTheme.spaceXl),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTheme.bodySecondary,
        ),
      ),
    );
  }
}
