import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/revenue_bar_chart.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../referral/referral_screen.dart';
import 'shipper_booking_detail_screen.dart';
import 'shipper_stats_detail_screen.dart';

// ============================================================================
// SHIPPER FINANCE SCREEN — revenus, à recevoir, commission et bénéfice net.
// ============================================================================

class ShipperFinanceScreen extends ConsumerStatefulWidget {
  const ShipperFinanceScreen({super.key});

  @override
  ConsumerState<ShipperFinanceScreen> createState() =>
      _ShipperFinanceScreenState();
}

class _ShipperFinanceScreenState extends ConsumerState<ShipperFinanceScreen> {
  final _scrollController = ScrollController();
  String _lastShipperId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPager());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPager());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _syncPager() {
    final id = ref.read(currentShipperProvider).valueOrNull?.id;
    if (id == null || id == _lastShipperId) return;
    _lastShipperId = id;
    ref.read(shipperBookingsPagerProvider(id).notifier).loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final shipper = ref.watch(currentShipperProvider);

    return shipper.when(
      data: (data) {
        if (data == null) {
          return const Scaffold(
            body: Center(child: Text('Expéditeur introuvable')),
          );
        }
        return _buildFinance(data);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Erreur: $e'))),
    );
  }

  Widget _buildFinance(Shipper shipper) {
    final summary = ref.watch(shipperFinanceSummaryProvider(shipper.id));
    final settings = ref.watch(platformSettingsProvider);
    final currency =
        settings.valueOrNull?.defaultCurrency ?? AppConstants.defaultCurrency;

    final revenue = (summary.valueOrNull?['revenue'] as num?)?.toDouble() ?? 0;
    final profit = (summary.valueOrNull?['profit'] as num?)?.toDouble() ?? 0;

    ref.listen(
      tableChangesProvider(('bookings', null, null)),
      (previous, next) {
        final event = next.valueOrNull;
        if (event == null) return;
        ref.invalidate(shipperFinanceSummaryProvider(shipper.id));
        ref.invalidate(shipperEarningsProvider(shipper.id));
      },
    );

    ref.listen(
      tableChangesProvider(('platform_fees', null, null)),
      (previous, next) {
        final event = next.valueOrNull;
        if (event == null) return;
        ref.invalidate(shipperFinanceSummaryProvider(shipper.id));
        ref.invalidate(shipperPlatformFeesProvider(shipper.id));
      },
    );

    return Scaffold(
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(shipperFinanceSummaryProvider(shipper.id));
            await ref
                .read(shipperBookingsPagerProvider(shipper.id).notifier)
                .refresh();
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CompactSliverHeader(
                title: 'Finance',
                subtitle: shipper.user?.fullName ?? 'Espace expéditeur',
                icon: Icons.account_balance_wallet_rounded,
              ),
              SliverToBoxAdapter(
                  child: _buildProfitHeader(currency, profit, shipper.id)),
              SliverToBoxAdapter(child: _buildStatGrid(shipper.id, currency)),
              SliverToBoxAdapter(
                  child: _buildPlatformFeesSection(shipper.id, currency)),
              SliverToBoxAdapter(
                  child: _buildRevenueChart(shipper.id, currency, revenue)),
              SliverToBoxAdapter(
                  child: _buildReferralEarningsSection(currency)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.spaceMd,
                    AppTheme.spaceLg,
                    AppTheme.spaceMd,
                    AppTheme.spaceSm,
                  ),
                  child: Text('Historique des commandes', style: AppTheme.h2),
                ),
              ),
              _buildBookingsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfitHeader(String currency, double profit, String shipperId) {
    final deferredFee = ((ref.watch(shipperFinanceSummaryProvider(shipperId))
                .valueOrNull?['fees_on_undelivered_bookings']) as num?)
            ?.toDouble() ??
        0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Bénéfice net', style: AppTheme.caption),
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              '${profit.toStringAsFixed(0)} $currency',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXs),
            const Text(
              'Revenus encaissés et à recevoir, moins la commission des '
              'colis déjà livrés.',
              style: AppTheme.bodySecondary,
            ),
            if (deferredFee > 0) ...[
              const SizedBox(height: AppTheme.spaceXs),
              Text(
                '+ ${deferredFee.toStringAsFixed(0)} $currency de commission '
                'seront déduits à la livraison.',
                style: AppTheme.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid(String shipperId, String currency) {
    final summary = ref.watch(shipperFinanceSummaryProvider(shipperId));
    final revenue = (summary.valueOrNull?['revenue'] as num?)?.toDouble() ?? 0;
    final receivable =
        (summary.valueOrNull?['receivable'] as num?)?.toDouble() ?? 0;
    final feesPaid =
        (summary.valueOrNull?['fees_paid'] as num?)?.toDouble() ?? 0;
    final feesAwaiting =
        (summary.valueOrNull?['fees_awaiting'] as num?)?.toDouble() ?? 0;
    final feesPending =
        (summary.valueOrNull?['fees_pending'] as num?)?.toDouble() ?? 0;
    final feesRefunded =
        (summary.valueOrNull?['fees_refunded'] as num?)?.toDouble() ?? 0;
    final feesDue = feesAwaiting + feesPending;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd,
            0,
            AppTheme.spaceMd,
            AppTheme.spaceSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: _FinanceStatCard(
                  label: 'Chiffre d\'affaires',
                  value: '${revenue.toStringAsFixed(0)} $currency',
                  icon: Icons.payments_outlined,
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: _FinanceStatCard(
                  label: 'À recevoir',
                  value: '${receivable.toStringAsFixed(0)} $currency',
                  icon: Icons.schedule_rounded,
                  color: AppTheme.infoColor,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd,
            0,
            AppTheme.spaceMd,
            AppTheme.spaceSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: _FinanceStatCard(
                  label: 'Commission payée',
                  value: '${feesPaid.toStringAsFixed(0)} $currency',
                  icon: Icons.verified_rounded,
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: _FinanceStatCard(
                  label: 'Commission à payer',
                  value: feesDue > 0
                      ? '${feesDue.toStringAsFixed(0)} $currency'
                      : 'Pas de dettes',
                  icon: Icons.hourglass_top_rounded,
                  color: feesDue > 0
                      ? AppTheme.warningColor
                      : AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd,
            0,
            AppTheme.spaceMd,
            AppTheme.spaceSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: _FinanceStatCard(
                  label: 'Commission remboursée',
                  value: '${feesRefunded.toStringAsFixed(0)} $currency',
                  icon: Icons.assignment_return_rounded,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: _FinanceStatCard(
                  label: 'Dûs payés',
                  value: '${feesPaid.toStringAsFixed(0)} $currency',
                  icon: Icons.receipt_long_rounded,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformFeesSection(String shipperId, String currency) {
    final fees = ref.watch(shipperPlatformFeesProvider(shipperId));
    final pendingFees =
        fees.valueOrNull?.where((f) => !f.isPaid).toList() ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        0,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                AnimatedIconDot(
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppTheme.warningColor,
                ),
                SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: Text('Dûs plateforme', style: AppTheme.h3),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXs),
            const Text(
              'Commission due à la plateforme sur vos offres. Le paiement '
              'lance un délai de 7 jours pour régulariser ; passé ce délai, '
              'le dossier peut être transmis à la justice.',
              style: AppTheme.caption,
            ),
            const SizedBox(height: AppTheme.spaceMd),
            fees.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Text(
                    'Aucun dû enregistré pour le moment.',
                    style: AppTheme.caption,
                  );
                }
                return Column(
                  children: [
                    for (final fee in list) _PlatformFeeTile(fee: fee),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.spaceMd),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, __) => const Text(
                'Impossible de charger les dûs.',
                style: AppTheme.caption,
              ),
            ),
            if (pendingFees.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceMd),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      _showPayFeesSheet(context, shipperId, currency),
                  icon: const Icon(Icons.payment_rounded, size: 18),
                  label: const Text('Payer mes dûs'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPayFeesSheet(
      BuildContext context, String shipperId, String currency) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundColor,
      builder: (sheetContext) => _PayFeesSheet(
        shipperId: shipperId,
        currency: currency,
      ),
    );
  }

  Widget _buildRevenueChart(
      String shipperId, String currency, double totalRevenue) {
    const months = [
      'J',
      'F',
      'M',
      'A',
      'M',
      'J',
      'J',
      'A',
      'S',
      'O',
      'N',
      'D',
    ];
    final summary = ref.watch(shipperFinanceSummaryProvider(shipperId));
    final monthly = (summary.valueOrNull?['monthly'] as Map?) ?? const {};
    final now = DateTime.now();
    final data = <RevenueBar>[
      for (var m = 1; m <= 12; m++)
        RevenueBar(
            label: months[m - 1],
            value: (monthly['${now.year}-${m.toString().padLeft(2, '0')}']
                    as num?)
                ?.toDouble() ??
                0),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceXs,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Revenus encaissés par mois', style: AppTheme.h3),
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              'Total: ${totalRevenue.toStringAsFixed(0)} $currency',
              style: AppTheme.caption,
            ),
            const SizedBox(height: AppTheme.spaceMd),
            RevenueBarChart(
              data: data,
              valueFormatter: (v) => v >= 1000
                  ? '${(v / 1000).toStringAsFixed(1)}k'
                  : v.toStringAsFixed(0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralEarningsSection(String currency) {
    final stats = ref.watch(myReferralStatsProvider);
    final isParrain = ref.watch(isCurrentUserParrainProvider).valueOrNull ?? false;

    if (!isParrain) return const SizedBox.shrink();

    ref.listen(
      tableChangesProvider(('referral_earnings', null, null)),
      (previous, next) {
        if (!next.hasValue) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(myReferralStatsProvider);
        });
      },
    );

    return stats.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (s) {
        if (s.totalPaid == 0 && s.totalPending == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd,
            AppTheme.spaceXs,
            AppTheme.spaceMd,
            AppTheme.spaceSm,
          ),
          child: GlassCard(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const AnimatedIconDot(
                      icon: Icons.card_giftcard_rounded,
                      color: AppTheme.accentColor,
                    ),
                    const SizedBox(width: AppTheme.spaceSm),
                    const Expanded(
                      child: Text('Gains parrainage', style: AppTheme.h3),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ReferralScreen()),
                      ),
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Row(
                  children: [
                    Expanded(
                      child: _FinanceStatCard(
                        icon: Icons.check_circle_rounded,
                        label: 'Payés',
                        value:
                            '${s.totalPaid.toStringAsFixed(0)} $currency',
                        color: AppTheme.accentColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSm),
                    Expanded(
                      child: _FinanceStatCard(
                        icon: Icons.hourglass_top_rounded,
                        label: 'En attente',
                        value:
                            '${s.totalPending.toStringAsFixed(0)} $currency',
                        color: AppTheme.warningColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSm),
                    Expanded(
                      child: _FinanceStatCard(
                        icon: Icons.group_rounded,
                        label: 'Filleuls',
                        value: '${s.qualifiedFilleuls}',
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                if (s.totalPending > 0) ...[
                  const SizedBox(height: AppTheme.spaceSm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ReferralScreen()),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Demander le paiement'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingsList() {
    final id = ref.read(currentShipperProvider).valueOrNull?.id ?? '';
    final pager = ref.watch(shipperBookingsPagerProvider(id));
    return PagedSliverList<Booking>(
      paginatedList: pager,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceXxl,
      ),
      emptyState: const _EmptyFinance(
        icon: Icons.receipt_long_outlined,
        message: 'Aucune commande reçue',
      ),
      itemBuilder: (context, booking, index) => StaggeredEntrance(
        delay: Duration(milliseconds: (index % 10) * 40),
        child: _FinanceBookingTile(booking: booking),
      ),
    );
  }
}

class _FinanceStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _FinanceStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            label,
            style: AppTheme.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spaceXs),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FinanceBookingTile extends ConsumerWidget {
  final Booking booking;

  const _FinanceBookingTile({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = BookingStatusExt.fromString(booking.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: GlassCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShipperBookingDetailScreen(bookingId: booking.id),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedIconDot(
                  icon: Icons.inventory_2_outlined,
                  color: status.color,
                ),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: Text(
                    booking.productName,
                    style: AppTheme.h3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                GradientBadge(
                  label: status.displayName,
                  gradient: _paymentGradient(booking.paymentStatus),
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Row(
              children: [
                Expanded(
                  child: _FinanceInfoTile(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Poids',
                    value: '${booking.allocatedWeightKg.toStringAsFixed(1)} kg',
                  ),
                ),
                Expanded(
                  child: _FinanceInfoTile(
                    icon: Icons.payments_outlined,
                    label: 'Total',
                    value:
                        '${booking.totalPrice.toStringAsFixed(0)} ${AppConstants.defaultCurrency}',
                    valueColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                Expanded(
                  child: _FinanceInfoTile(
                    icon: Icons.paid_outlined,
                    label: 'Paiement',
                    value: booking.isPaid ? 'Payé' : 'En attente',
                    valueColor: booking.isPaid
                        ? AppTheme.accentColor
                        : AppTheme.warningColor,
                  ),
                ),
                Expanded(
                  child: _FinanceInfoTile(
                    icon: Icons.event_rounded,
                    label: 'Date',
                    value: _formatFinanceDate(booking.createdAt),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _paymentGradient(String paymentStatus) {
    if (paymentStatus == 'paid') return AppTheme.successGradient;
    if (paymentStatus == 'refunded') return AppTheme.warningGradient;
    return AppTheme.primaryGradient;
  }
}

class _FinanceInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _FinanceInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMutedColor),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTheme.caption, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppTheme.textSecondaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyFinance extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyFinance({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXxl),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppTheme.textMutedColor),
          const SizedBox(height: AppTheme.spaceMd),
          Text(message, style: AppTheme.bodySecondary),
        ],
      ),
    );
  }
}

String _formatFinanceDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

// ============================================================================
// DÛS PLATEFORME
// ============================================================================

class _PlatformFeeTile extends StatelessWidget {
  final PlatformFee fee;

  const _PlatformFeeTile({required this.fee});

  @override
  Widget build(BuildContext context) {
    final overdue = fee.isOverdue;
    final isRefunded = fee.status == 'refunded';
    final statusLabel = switch (fee.status) {
      'paid' => 'Payé',
      'awaiting_confirmation' =>
        overdue ? 'En retard' : 'En attente de confirmation',
      'refunded' => 'Remboursé',
      _ => 'En attente de paiement',
    };

    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spaceSm),
      child: Row(
        children: [
          Icon(
            isRefunded
                ? Icons.assignment_return_rounded
                : fee.isPaid
                    ? Icons.check_circle_rounded
                    : overdue
                        ? Icons.error_outline_rounded
                        : Icons.hourglass_top_rounded,
            size: 20,
            color: isRefunded
                ? AppTheme.textSecondaryColor
                : fee.isPaid
                    ? AppTheme.accentColor
                    : overdue
                        ? AppTheme.errorColor
                        : AppTheme.warningColor,
          ),
          const SizedBox(width: AppTheme.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Chaque dû porte sa propre devise (DZD, EUR, USD, RMB…).
                  '${fee.amount.toStringAsFixed(0)} ${fee.currency}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(statusLabel, style: AppTheme.caption),
                if (fee.dueAt != null)
                  Text(
                    fee.isPaid
                        ? 'Réglée le ${_formatFinanceDate(fee.dueAt!)}'
                        : overdue
                            ? 'Échéance dépassée (${_formatFinanceDate(fee.dueAt!)})'
                            : 'À régler avant le ${_formatFinanceDate(fee.dueAt!)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: overdue
                          ? AppTheme.errorColor
                          : AppTheme.textSecondaryColor,
                    ),
                  ),
              ],
            ),
          ),
          if (fee.escalationStatus == 'justice_filed')
            const Tooltip(
              message: 'Dossier transmis à la justice',
              child: Icon(Icons.gavel_rounded,
                  color: AppTheme.errorColor, size: 20),
            ),
        ],
      ),
    );
  }
}

class _PayFeesSheet extends ConsumerStatefulWidget {
  final String shipperId;
  final String currency;

  const _PayFeesSheet({required this.shipperId, required this.currency});

  @override
  ConsumerState<_PayFeesSheet> createState() => _PayFeesSheetState();
}

class _PayFeesSheetState extends ConsumerState<_PayFeesSheet> {
  String _method = 'baridimob';
  bool _useVisa = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final fees = ref.watch(shipperPlatformFeesProvider(widget.shipperId));
    final pending = fees.valueOrNull?.where((f) => !f.isPaid).toList() ?? [];

    var total = 0.0;
    for (final f in pending) {
      total += f.amount;
    }
    final discounted = _useVisa ? total * 0.7 : total;

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spaceMd,
        right: AppTheme.spaceMd,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceLg,
        top: AppTheme.spaceMd,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Payer mes dûs', style: AppTheme.h2),
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              'Total dû : ${total.toStringAsFixed(0)} ${widget.currency}',
              style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            RadioGroup<String>(
              groupValue: _method,
              onChanged: (v) => setState(() => _method = v ?? 'baridimob'),
              child: const Column(
                children: [
                  RadioListTile<String>(
                    value: 'baridimob',
                    title: Text('Baridimob / virement'),
                    subtitle: Text('Paiement par virement bancaire ou CCP'),
                    secondary: Icon(Icons.account_balance_rounded),
                  ),
                  RadioListTile<String>(
                    value: 'visa',
                    title: Text('Carte Visa (-30%)'),
                    subtitle: Text('Paiement en ligne par carte bancaire'),
                    secondary: Icon(Icons.credit_card_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceXs),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _useVisa,
              onChanged: (v) => setState(() => _useVisa = v ?? false),
              title: const Text(
                'Bénéficier de la remise Visa -30%',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Le montant dû sera réduit de 30%.',
                style: TextStyle(fontSize: 11),
              ),
            ),
            if (_useVisa) ...[
              const SizedBox(height: AppTheme.spaceXs),
              Text(
                'Montant avec remise : ${discounted.toStringAsFixed(0)} '
                '${widget.currency}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spaceLg),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: const Icon(Icons.payment_rounded, size: 18),
              label: Text(
                _busy
                    ? 'Envoi en cours…'
                    : 'Demander le paiement (échéance 7 jours)',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final paymentMethod = _method == 'visa' ? 'visa' : 'baridimob';
      final discount = _useVisa || _method == 'visa' ? 30.0 : 0.0;
      await ref.read(paymentServiceProvider).payPlatformFees(
            widget.shipperId,
            paymentMethod: paymentMethod,
            discountPercent: discount,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Demande envoyée. Le fondateur doit confirmer le paiement.',
            ),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
      ref.invalidate(shipperPlatformFeesProvider(widget.shipperId));
      ref.invalidate(shipperFinanceSummaryProvider(widget.shipperId));
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    }
  }
}
