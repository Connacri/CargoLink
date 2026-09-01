import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../../core/widgets/user_avatar.dart';

/// Full accounting of every transaction: who paid, to whom, when, with all
/// details (product, route, payment method, transaction id).
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(allTransactionsProvider);

    // Temps réel : un nouveau paiement met à jour la liste en direct.
    ref.listen(
      tableChangesProvider(('payments', null, null)),
      (previous, next) {
        if (!next.hasValue) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(allTransactionsProvider);
        });
      },
    );

    return Scaffold(
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(allTransactionsProvider),
          child: transactions.when(
            data: (items) => CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const CompactSliverHeader(
                  title: 'Transactions',
                  subtitle: 'Toutes les opérations financières',
                  icon: Icons.swap_horiz_rounded,
                  expandedHeight: 140,
                ),
                if (items.isEmpty)
                  const SliverToBoxAdapter(
                    child: _EmptyTransactions(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spaceMd,
                      AppTheme.spaceMd,
                      AppTheme.spaceMd,
                      AppTheme.spaceXxl,
                    ),
                    sliver: SliverList.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) => StaggeredEntrance(
                        delay: Duration(milliseconds: (index % 10) * 50),
                        child: _TransactionCard(item: items[index]),
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
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionItem item;

  const _TransactionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final payment = item.payment;
    final status = payment.status;

    final Color statusColor = switch (status) {
      'completed' => AppTheme.accentColor,
      'pending' => AppTheme.warningColor,
      'failed' => AppTheme.errorColor,
      'refunded' => AppTheme.infoColor,
      _ => AppTheme.textSecondaryColor,
    };
    final IconData statusIcon = switch (status) {
      'completed' => Icons.check_circle_rounded,
      'pending' => Icons.hourglass_top_rounded,
      'failed' => Icons.error_rounded,
      'refunded' => Icons.undo_rounded,
      _ => Icons.circle_outlined,
    };
    final String statusLabel = switch (status) {
      'completed' => 'Payé',
      'pending' => 'En attente',
      'failed' => 'Échoué',
      'refunded' => 'Remboursé',
      _ => status,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedIconDot(icon: statusIcon, color: statusColor),
                const SizedBox(width: AppTheme.spaceSm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName ?? 'Transaction',
                        style: AppTheme.h3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.shipmentRoute != null)
                        Text(
                          item.shipmentRoute!,
                          style: AppTheme.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Text(
                  '${payment.amount.toStringAsFixed(0)} ${payment.currency}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMd),
            _PartyRow(
              icon: Icons.person_outline_rounded,
              iconColor: AppTheme.primaryColor,
              label: 'De',
              name: item.clientName ?? 'Client',
              avatar: item.clientAvatar,
              userId: item.clientId,
            ),
            const SizedBox(height: AppTheme.spaceSm),
            _PartyRow(
              icon: Icons.flight_takeoff_outlined,
              iconColor: AppTheme.infoColor,
              label: 'Vers',
              name: item.shipperName ?? 'Expéditeur',
              avatar: item.shipperAvatar,
              userId: item.shipperUserId,
            ),
            const Divider(height: AppTheme.spaceLg),
            Wrap(
              spacing: AppTheme.spaceSm,
              runSpacing: AppTheme.spaceSm,
              children: [
                _DetailChip(
                  icon: Icons.event_rounded,
                  text: _formatDate(payment.createdAt),
                ),
                if (payment.paymentMethod != null)
                  _DetailChip(
                    icon: Icons.payment_rounded,
                    text: payment.paymentMethod!,
                  ),
                GradientBadge(
                  label: statusLabel,
                  gradient: _statusGradient(status),
                  compact: true,
                ),
              ],
            ),
            if (payment.transactionId != null &&
                payment.transactionId!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceSm),
              Text(
                'N° ${payment.transactionId}',
                style: AppTheme.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final date = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) {
      return "Aujourd'hui à ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
    }
    if (diff == 1) return 'Hier';
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _PartyRow extends StatelessWidget {
  const _PartyRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.name,
    this.avatar,
    this.userId,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String name;
  final String? avatar;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (userId != null)
          UserAvatar(
            userId: userId!,
            initial: name,
            imageUrl: avatar,
            radius: 14,
          )
        else
          GradientAvatar(initial: name, imageUrl: avatar, radius: 14),
        const SizedBox(width: AppTheme.spaceSm),
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.caption),
        const SizedBox(width: AppTheme.spaceSm),
        Expanded(
          child: Text(
            name,
            style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.textMutedColor),
          const SizedBox(width: 4),
          Text(text, style: AppTheme.caption),
        ],
      ),
    );
  }
}

LinearGradient _statusGradient(String status) {
  switch (status) {
    case 'completed':
      return AppTheme.successGradient;
    case 'pending':
      return AppTheme.warningGradient;
    case 'failed':
      return AppTheme.errorGradient;
    case 'refunded':
      return AppTheme.primaryGradient;
    default:
      return AppTheme.primaryGradient;
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppTheme.spaceXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz_rounded,
              size: 64, color: AppTheme.textMutedColor),
          SizedBox(height: AppTheme.spaceMd),
          Text('Aucune transaction', style: AppTheme.h3),
        ],
      ),
    );
  }
}
