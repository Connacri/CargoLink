import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/delivery_models.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';

class SubscriptionManagementScreen extends ConsumerStatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  ConsumerState<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends ConsumerState<SubscriptionManagementScreen>
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

  void _refresh() {
    ref.invalidate(allDeliverySubscriptionsProvider);
  }

  Future<void> _approve(DeliverySubscription sub) async {
    try {
      await ref.read(deliveryServiceProvider).approveSubscription(sub.id);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abonnement approuvé'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    }
  }

  Future<void> _reject(DeliverySubscription sub) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter l\'abonnement'),
        content: const Text('Refuser cette demande d\'abonnement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(deliveryServiceProvider).cancelSubscription(sub.id);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abonnement rejeté'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSubs = ref.watch(allDeliverySubscriptionsProvider);

    // Temps réel : une demande d'abonnement soumise/approuvée/rejetée ailleurs
    // met à jour les compteurs et listes en direct.
    ref.listen(
      tableChangesProvider(('delivery_subscriptions', null, null)),
      (previous, next) {
        if (!next.hasValue) return;
        WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
      },
    );

    return Scaffold(
      body: SafeArea(
        top: false,
        child: allSubs.when(
          data: (subs) {
            final pending = subs.where((s) => s.status == 'pending').toList();
            final active = subs.where((s) => s.status == 'active').toList();
            final cancelled = subs.where((s) => s.status == 'cancelled' || s.status == 'expired').toList();

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.spaceMd,
                      AppTheme.spaceMd,
                      AppTheme.spaceMd,
                      AppTheme.spaceSm,
                    ),
                    child: Text('Abonnements', style: AppTheme.h1),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                    child: TabBar(
                      controller: _tabController,
                      tabs: [
                        Tab(text: 'En attente (${pending.length})'),
                        Tab(text: 'Actifs (${active.length})'),
                        Tab(text: 'Archives (${cancelled.length})'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _SubscriptionList(
                    subs: pending,
                    onApprove: _approve,
                    onReject: _reject,
                    emptyText: 'Aucune demande en attente',
                    showActions: true,
                  ),
                  _SubscriptionList(
                    subs: active,
                    onApprove: null,
                    onReject: null,
                    emptyText: 'Aucun abonnement actif',
                    showActions: false,
                  ),
                  _SubscriptionList(
                    subs: cancelled,
                    onApprove: null,
                    onReject: null,
                    emptyText: 'Aucune archive',
                    showActions: false,
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Erreur: $e')),
        ),
      ),
    );
  }
}

class _SubscriptionList extends StatelessWidget {
  const _SubscriptionList({
    required this.subs,
    required this.onApprove,
    required this.onReject,
    required this.emptyText,
    required this.showActions,
  });

  final List<DeliverySubscription> subs;
  final Future<void> Function(DeliverySubscription)? onApprove;
  final Future<void> Function(DeliverySubscription)? onReject;
  final String emptyText;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    if (subs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 48, color: AppTheme.textMutedColor),
            const SizedBox(height: AppTheme.spaceMd),
            Text(emptyText, style: AppTheme.caption),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      itemCount: subs.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spaceSm),
      itemBuilder: (context, index) {
        final sub = subs[index];
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedIconDot(
                    icon: sub.role == 'shipper'
                        ? Icons.local_shipping_rounded
                        : Icons.person_rounded,
                    color: sub.role == 'shipper'
                        ? AppTheme.warningColor
                        : AppTheme.infoColor,
                  ),
                  const SizedBox(width: AppTheme.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.role == 'shipper' ? 'Expéditeur' : 'Client',
                          style: AppTheme.h3.copyWith(fontSize: 14),
                        ),
                        Text(
                          '${sub.price.toStringAsFixed(0)} ${sub.currency}',
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: sub.status),
                ],
              ),
              if (showActions) ...[
                const SizedBox(height: AppTheme.spaceMd),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onReject?.call(sub),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Rejeter'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => onApprove?.call(sub),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Approuver'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'active':
        color = AppTheme.accentColor;
        label = 'Actif';
      case 'pending':
        color = AppTheme.warningColor;
        label = 'En attente';
      case 'cancelled':
        color = AppTheme.errorColor;
        label = 'Rejeté';
      case 'expired':
        color = AppTheme.textMutedColor;
        label = 'Expiré';
      default:
        color = AppTheme.textMutedColor;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
