import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/revenue_bar_chart.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
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
      },
    );

    return Scaffold(
      body: RefreshIndicator(
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
            GradientSliverHeader(
              title: 'Finance',
              subtitle: shipper.user?.fullName ?? 'Espace expéditeur',
              icon: Icons.account_balance_wallet_rounded,
            ),
            SliverToBoxAdapter(child: _buildProfitHeader(currency, profit)),
            SliverToBoxAdapter(child: _buildStatGrid(shipper.id, currency)),
            SliverToBoxAdapter(
                child: _buildRevenueChart(shipper.id, currency, revenue)),
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
    );
  }

  Widget _buildProfitHeader(String currency, double profit) {
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
              'Revenus encaissés moins la commission déjà réglée.',
              style: AppTheme.bodySecondary,
            ),
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
                  value: '${feesDue.toStringAsFixed(0)} $currency',
                  icon: Icons.hourglass_top_rounded,
                  color: AppTheme.warningColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart(String shipperId, String currency,
      double totalRevenue) {
    const months = [
      'J', 'F', 'M', 'A', 'M', 'J',
      'J', 'A', 'S', 'O', 'N', 'D',
    ];
    final summary = ref.watch(shipperFinanceSummaryProvider(shipperId));
    final monthly = (summary.valueOrNull?['monthly'] as Map?) ?? const {};
    final data = <RevenueBar>[
      for (var m = 1; m <= 12; m++)
        RevenueBar(label: months[m - 1], value: (monthly[m] as num?)?.toDouble() ?? 0),
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
                    value:
                        '${booking.allocatedWeightKg.toStringAsFixed(1)} kg',
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
              Text(label, style: AppTheme.caption, overflow: TextOverflow.ellipsis),
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