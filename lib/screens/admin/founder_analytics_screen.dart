import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../components/revenue_bar_chart.dart';

enum _AnalyticsPeriod { week, month, quarter, all }

/// Full platform analytics dashboard for the founder: real numbers, revenue
/// charts, profit (collected commissions), breakdown by role / destination /
/// user, and every platform detail aggregated from the existing providers.
class FounderAnalyticsScreen extends ConsumerStatefulWidget {
  const FounderAnalyticsScreen({super.key});

  @override
  ConsumerState<FounderAnalyticsScreen> createState() =>
      _FounderAnalyticsScreenState();
}

class _FounderAnalyticsScreenState extends ConsumerState<FounderAnalyticsScreen> {
  _AnalyticsPeriod _period = _AnalyticsPeriod.month;

  DateTime? get _startDate {
    final now = DateTime.now();
    switch (_period) {
      case _AnalyticsPeriod.week:
        return now.subtract(const Duration(days: 7));
      case _AnalyticsPeriod.month:
        return now.subtract(const Duration(days: 30));
      case _AnalyticsPeriod.quarter:
        return now.subtract(const Duration(days: 90));
      case _AnalyticsPeriod.all:
        return null;
    }
  }

  String get _periodLabel {
    switch (_period) {
      case _AnalyticsPeriod.week:
        return '7 derniers jours';
      case _AnalyticsPeriod.month:
        return '30 derniers jours';
      case _AnalyticsPeriod.quarter:
        return '90 derniers jours';
      case _AnalyticsPeriod.all:
        return 'Toute la période';
    }
  }

  bool _inRange(DateTime dt, DateTime? start) =>
      start == null || !dt.isBefore(start);

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(allUsersProvider).valueOrNull ?? [];
    final shipments = ref.watch(allShipmentsProvider).valueOrNull ?? [];
    final analyticsData = ref.watch(founderAnalyticsDataProvider).valueOrNull;
    final bookings = analyticsData?.bookings ?? [];
    final payments = analyticsData?.payments ?? [];
    final disputes = ref.watch(allDisputesProvider).valueOrNull ?? [];
    final fees = ref.watch(platformFeeSummaryProvider).valueOrNull ?? {};
    final allFees = ref.watch(allPlatformFeesProvider).valueOrNull ?? [];

    final start = _startDate;

    final filteredBookings =
        bookings.where((b) => _inRange(b.createdAt, start)).toList();
    final filteredShipments =
        shipments.where((s) => _inRange(s.createdAt, start)).toList();
    final filteredUsers =
        users.where((u) => _inRange(u.createdAt, start)).toList();
    final paidBookings = filteredBookings
        .where((b) => b.paymentStatus == 'paid' && b.status != 'cancelled')
        .toList();

    final ca = paidBookings.fold<double>(0, (s, b) => s + b.totalPrice);
    final totalWeight = filteredBookings.fold<double>(
        0, (s, b) => s + b.allocatedWeightKg);
    final delivered = filteredBookings.where((b) => b.status == 'delivered').length;
    final cancelled = filteredBookings.where((b) => b.status == 'cancelled').length;
    final successRate = filteredBookings.isEmpty
        ? 0.0
        : (delivered / filteredBookings.length) * 100;

    final collectedFees = (fees['collected'] as num?)?.toDouble() ?? 0;
    final pendingFees = (fees['pending'] as num?)?.toDouble() ?? 0;
    final awaitingFees = (fees['awaiting'] as num?)?.toDouble() ?? 0;

    final avgBasket = paidBookings.isEmpty
        ? 0.0
        : ca / paidBookings.length;

    final paidPayments = payments
        .where((p) => p.status == 'completed')
        .where((p) => _inRange(p.createdAt, start))
        .toList();
    final paymentVolume = paidPayments.fold<double>(0, (s, p) => s + p.amount);

    final openDisputes = disputes.where((d) => d.isOpen).length;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allUsersProvider);
            ref.invalidate(allShipmentsProvider);
            ref.invalidate(founderAnalyticsDataProvider);
            ref.invalidate(allDisputesProvider);
            ref.invalidate(platformFeeSummaryProvider);
            ref.invalidate(allPlatformFeesProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const CompactSliverHeader(
                title: 'Analytics',
                subtitle: 'Chiffres détaillés de la plateforme',
                icon: Icons.insert_chart_outlined_rounded,
              ),
              SliverToBoxAdapter(child: _buildPeriodSelector()),
              SliverToBoxAdapter(
                child: _buildKpis(
                  users: filteredUsers.length,
                  totalUsers: users.length,
                  bookings: filteredBookings.length,
                  shipments: filteredShipments.length,
                  ca: ca,
                  weight: totalWeight,
                  fees: collectedFees,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildActivitySummary(
                  delivered: delivered,
                  cancelled: cancelled,
                  successRate: successRate,
                  avgBasket: avgBasket,
                  pendingFees: pendingFees,
                  awaitingFees: awaitingFees,
                  paymentVolume: paymentVolume,
                  openDisputes: openDisputes,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildMonthlyChart(bookings),
              ),
              SliverToBoxAdapter(
                child: _buildRevenueByRole(bookings),
              ),
              SliverToBoxAdapter(
                child: _buildTopDestinations(bookings),
              ),
              SliverToBoxAdapter(
                child: _buildTopClients(bookings, users),
              ),
              SliverToBoxAdapter(
                child: _buildTopShippers(shipments, bookings, users),
              ),
              SliverToBoxAdapter(
                child: _buildShipperFinanceList(bookings, allFees),
              ),
              SliverToBoxAdapter(
                child: _buildStatusBreakdown(bookings),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spaceXxl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_periodLabel, style: AppTheme.caption),
            const SizedBox(height: AppTheme.spaceSm),
            SegmentedButton<_AnalyticsPeriod>(
          segments: const [
            ButtonSegment(
              value: _AnalyticsPeriod.week,
              label: Text('7j'),
              icon: Icon(Icons.today_rounded, size: 18),
            ),
            ButtonSegment(
              value: _AnalyticsPeriod.month,
              label: Text('30j'),
              icon: Icon(Icons.date_range_rounded, size: 18),
            ),
            ButtonSegment(
              value: _AnalyticsPeriod.quarter,
              label: Text('90j'),
              icon: Icon(Icons.calendar_month_rounded, size: 18),
            ),
            ButtonSegment(
              value: _AnalyticsPeriod.all,
              label: Text('Tout'),
              icon: Icon(Icons.all_inclusive_rounded, size: 18),
            ),
          ],
          selected: {_period},
          onSelectionChanged: (selection) =>
              setState(() => _period = selection.first),
          showSelectedIcon: false,
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpis({
    required int users,
    required int totalUsers,
    required int bookings,
    required int shipments,
    required double ca,
    required double weight,
    required double fees,
  }) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 700;
    final cardWidth = isWide ? 150.0 : (width - 60) / 3;
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppTheme.spaceSm + 4,
        runSpacing: AppTheme.spaceSm + 4,
        children: [
          _kpiCard(Icons.attach_money_rounded, 'Chiffre d\'affaires',
              _money(ca), AppTheme.accentColor, cardWidth),
          _kpiCard(Icons.savings_rounded, 'Bénéfice (commissions)',
              _money(fees), AppTheme.accentDark, cardWidth),
          _kpiCard(Icons.receipt_long_rounded, 'Commandes',
              '$bookings', AppTheme.primaryColor, cardWidth),
          _kpiCard(Icons.flight_rounded, 'Vols', '$shipments',
              AppTheme.infoColor, cardWidth),
          _kpiCard(Icons.people_alt_rounded, 'Utilisateurs',
              '$users · $totalUsers', AppTheme.warningColor, cardWidth),
          _kpiCard(Icons.scale_rounded, 'Poids transporté',
              '${weight.toStringAsFixed(0)} kg', AppTheme.primaryDark,
              cardWidth),
        ],
      ),
    );
  }

  Widget _buildActivitySummary({
    required int delivered,
    required int cancelled,
    required double successRate,
    required double avgBasket,
    required double pendingFees,
    required double awaitingFees,
    required double paymentVolume,
    required int openDisputes,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _summaryTile(
                Icons.check_circle_rounded, 'Commandes livrées', '$delivered',
                AppTheme.accentColor),
            const Divider(height: 1, indent: AppTheme.spaceXxl),
            _summaryTile(
                Icons.cancel_rounded, 'Commandes annulées', '$cancelled',
                AppTheme.errorColor),
            const Divider(height: 1, indent: AppTheme.spaceXxl),
            _summaryTile(Icons.trending_up_rounded, 'Taux de livraison',
                '${successRate.toStringAsFixed(1)}%', AppTheme.accentColor),
            const Divider(height: 1, indent: AppTheme.spaceXxl),
            _summaryTile(Icons.shopping_cart_rounded, 'Panier moyen',
                _money(avgBasket), AppTheme.primaryColor),
            const Divider(height: 1, indent: AppTheme.spaceXxl),
            _summaryTile(Icons.account_balance_wallet_rounded,
                'Volume encaissé (paiements)',
                _money(paymentVolume), AppTheme.infoColor),
            const Divider(height: 1, indent: AppTheme.spaceXxl),
            _summaryTile(Icons.payment_rounded,
                'En attente de confirmation', _money(awaitingFees),
                AppTheme.warningColor),
            const Divider(height: 1, indent: AppTheme.spaceXxl),
            _summaryTile(Icons.schedule_rounded,
                'Commissions à encaisser', _money(pendingFees),
                AppTheme.primaryColor),
            const Divider(height: 1, indent: AppTheme.spaceXxl),
            _summaryTile(Icons.gavel_rounded, 'Litiges ouverts',
                '$openDisputes', AppTheme.errorColor),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(List<Booking> allBookings) {
    const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    final byMonth = <String, double>{};
    final now = DateTime.now();
    final currentYear = now.year;
    for (final b in allBookings) {
      if (b.createdAt.year != currentYear) continue;
      if (b.paymentStatus != 'paid' || b.status == 'cancelled') continue;
      final key =
          '$currentYear-${b.createdAt.month.toString().padLeft(2, '0')}';
      byMonth[key] = (byMonth[key] ?? 0) + b.totalPrice;
    }
    final data = <RevenueBar>[
      for (var m = 1; m <= 12; m++)
        RevenueBar(
            label: months[m - 1],
            value: byMonth['$currentYear-${m.toString().padLeft(2, '0')}'] ?? 0),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chiffre d\'affaires par mois ($currentYear)',
                style: AppTheme.h3),
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

  Widget _buildRevenueByRole(List<Booking> allBookings) {
    var clientVolume = 0.0;
    var shipperEarned = 0.0;
    for (final b in allBookings) {
      if (b.paymentStatus != 'paid' || b.status == 'cancelled') continue;
      clientVolume += b.totalPrice;
      final shipment = b.shipment;
      if (shipment != null) {
        shipperEarned += b.totalPrice;
      }
    }
    final total = clientVolume + shipperEarned;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chiffre d\'affaires par rôle', style: AppTheme.h3),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              'Volume commandé par les clients : ${_money(clientVolume)} · '
              'montant reversé aux expéditeurs : ${_money(shipperEarned)}',
              style: AppTheme.caption,
            ),
            const SizedBox(height: AppTheme.spaceMd),
            _proportionalBar(
              segments: [
                if (clientVolume > 0)
                  (clientVolume, AppTheme.accentColor, 'Clients'),
                if (shipperEarned > 0)
                  (shipperEarned, AppTheme.primaryColor, 'Expéditeurs'),
              ],
              total: total,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDestinations(List<Booking> allBookings) {
    final byRoute = <String, double>{};
    final byRouteCount = <String, int>{};
    for (final b in allBookings) {
      if (b.paymentStatus != 'paid' || b.status == 'cancelled') continue;
      final s = b.shipment;
      if (s == null) continue;
      final key = '${s.originCountry} → ${s.destinationCity}';
      byRoute[key] = (byRoute[key] ?? 0) + b.totalPrice;
      byRouteCount[key] = (byRouteCount[key] ?? 0) + 1;
    }
    final entries = byRoute.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(6).toList();
    final maxValue = top.isEmpty ? 1.0 : top.first.value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top destinations', style: AppTheme.h3),
            const SizedBox(height: AppTheme.spaceMd),
            if (top.isEmpty)
              const Text('Aucune donnée', style: AppTheme.bodySecondary)
            else
              for (final e in top)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.body,
                            ),
                          ),
                          Text(
                            '${_money(e.value)} · ${byRouteCount[e.key]}',
                            style: AppTheme.caption,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: e.value / maxValue,
                          minHeight: 6,
                          backgroundColor:
                              AppTheme.surfaceColor.withValues(alpha: 0.6),
                          valueColor: const AlwaysStoppedAnimation(
                              AppTheme.accentColor),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopClients(List<Booking> allBookings, List<User> users) {
    final userById = {for (final u in users) u.id: u};
    final byClient = <String, double>{};
    final byClientCount = <String, int>{};
    for (final b in allBookings) {
      if (b.paymentStatus != 'paid' || b.status == 'cancelled') continue;
      byClient[b.clientId] = (byClient[b.clientId] ?? 0) + b.totalPrice;
      byClientCount[b.clientId] = (byClientCount[b.clientId] ?? 0) + 1;
    }
    final entries = byClient.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();

    return _rankListCard(
      title: 'Top clients',
      subtitle: 'Par chiffre d\'affaires payé',
      icon: Icons.person_rounded,
      rows: top.map((e) {
        final u = userById[e.key];
        return _RankRow(
          name: u?.fullName ?? 'Utilisateur supprimé',
          value: _money(e.value),
          detail: '${byClientCount[e.key] ?? 0} commande(s)',
          avatar: u,
        );
      }).toList(),
    );
  }

  Widget _buildTopShippers(
      List<Shipment> shipments, List<Booking> allBookings, List<User> users) {
    final shipmentByShipper = <String, List<Shipment>>{};
    for (final s in shipments) {
      shipmentByShipper.putIfAbsent(s.shipperId, () => []).add(s);
    }
    final bookingTotalByShipment = <String, double>{};
    for (final b in allBookings) {
      if (b.paymentStatus != 'paid' || b.status == 'cancelled') continue;
      bookingTotalByShipment[b.shipmentId] =
          (bookingTotalByShipment[b.shipmentId] ?? 0) + b.totalPrice;
    }

    final byShipper = <String, double>{};
    for (final entry in shipmentByShipper.entries) {
      var total = 0.0;
      for (final s in entry.value) {
        total += bookingTotalByShipment[s.id] ?? 0;
      }
      byShipper[entry.key] = total;
    }
    final entries = byShipper.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();
    final userById = {for (final u in users) u.id: u};

    return _rankListCard(
      title: 'Top expéditeurs',
      subtitle: 'Par commandes payées sur leurs vols',
      icon: Icons.flight_takeoff_rounded,
      rows: top.map((e) {
        final u = userById[e.key];
        return _RankRow(
          name: u?.fullName ?? 'Expéditeur supprimé',
          value: _money(e.value),
          detail: '${shipmentByShipper[e.key]?.length ?? 0} vol(s)',
          avatar: u,
        );
      }).toList(),
    );
  }

  Widget _buildStatusBreakdown(List<Booking> allBookings) {
    final counts = <String, int>{};
    for (final b in allBookings) {
      counts[b.status] = (counts[b.status] ?? 0) + 1;
    }
    const labels = {
      'pending': ('En attente', AppTheme.warningColor),
      'confirmed': ('Confirmé', AppTheme.infoColor),
      'shipped': ('Expédié', AppTheme.primaryColor),
      'delivered': ('Livré', AppTheme.accentColor),
      'cancelled': ('Annulé', AppTheme.errorColor),
    };
    final total = allBookings.isEmpty ? 1 : allBookings.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Statut des commandes', style: AppTheme.h3),
            const SizedBox(height: AppTheme.spaceMd),
            for (final entry in labels.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                child: Row(
                  children: [
                    AnimatedIconDot(
                        icon: Icons.circle, color: entry.value.$2, size: 10),
                    const SizedBox(width: AppTheme.spaceSm + 2),
                    Expanded(
                      child: Text(entry.value.$1, style: AppTheme.body),
                    ),
                    Text(
                      '${counts[entry.key] ?? 0}'
                      ' (${(((counts[entry.key] ?? 0) / total) * 100).toStringAsFixed(1)}%)',
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _rankListCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<_RankRow> rows,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedIconDot(icon: icon, color: AppTheme.primaryColor),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTheme.h3),
                      Text(subtitle, style: AppTheme.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMd),
            if (rows.isEmpty)
              const Text('Aucune donnée', style: AppTheme.bodySecondary)
            else
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                  child: row,
                ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(IconData icon, String label, String value, Color color,
      double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppTheme.spaceSm + 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          AnimatedIconDot(icon: icon, color: color, size: 20),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(IconData icon, String label, String value, Color color) {
    return ListTile(
      dense: true,
      leading: AnimatedIconDot(icon: icon, color: color, size: 20),
      title: Text(label, style: AppTheme.body),
      trailing: Text(
        value,
        style: AppTheme.body.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _proportionalBar({
    required List<(double, Color, String)> segments,
    required double total,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                for (final s in segments)
                  Expanded(
                    flex: (s.$1 / (total == 0 ? 1 : total) * 10000).round(),
                    child: Container(
                      color: s.$2.withValues(alpha: 0.9),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        for (final s in segments)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: s.$2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(child: Text(s.$3, style: AppTheme.caption)),
                Text(
                  '${((s.$1 / (total == 0 ? 1 : total)) * 100).toStringAsFixed(1)}%',
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _money(double v) {
    final rounded = v.round();
    if (rounded >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1)}M';
    }
    if (rounded >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}k';
    }
    return rounded.toString();
  }

  /// Finance de chaque expéditeur (vue fondateur) : chiffre d'affaires,
  /// commission réglée et commission due — pour vérifier les comptes de
  /// chacun et que le total global est cohérent.
  Widget _buildShipperFinanceList(
      List<Booking> allBookings, List<PlatformFee> allFees) {
    final caByShipper = <String, double>{};
    final nameByShipper = <String, String>{};
    final avatarByShipper = <String, String?>{};
    final userIdByShipper = <String, String?>{};
    for (final b in allBookings) {
      if (b.paymentStatus != 'paid' || b.status == 'cancelled') continue;
      final shipper = b.shipment?.shipper;
      if (shipper == null) continue;
      caByShipper[shipper.id] = (caByShipper[shipper.id] ?? 0) + b.totalPrice;
      nameByShipper[shipper.id] =
          shipper.user?.fullName ?? 'Expéditeur';
      avatarByShipper[shipper.id] = shipper.user?.profilePictureUrl;
      userIdByShipper[shipper.id] = shipper.user?.id;
    }

    final paidByShipper = <String, double>{};
    final dueByShipper = <String, double>{};
    for (final f in allFees) {
      if (f.isPaid) {
        paidByShipper[f.shipperId] =
            (paidByShipper[f.shipperId] ?? 0) + f.amount;
      } else {
        dueByShipper[f.shipperId] = (dueByShipper[f.shipperId] ?? 0) + f.amount;
      }
      if (!nameByShipper.containsKey(f.shipperId)) {
        nameByShipper[f.shipperId] =
            f.shipment?.shipper?.user?.fullName ?? 'Expéditeur';
        avatarByShipper[f.shipperId] =
            f.shipment?.shipper?.user?.profilePictureUrl;
        userIdByShipper[f.shipperId] = f.shipment?.shipper?.user?.id;
      }
    }

    final ids = <String>{
      ...caByShipper.keys,
      ...paidByShipper.keys,
      ...dueByShipper.keys,
    };
    if (ids.isEmpty) return const SizedBox.shrink();

    final rows = ids.toList()
      ..sort((a, b) =>
          (caByShipper[b] ?? 0).compareTo(caByShipper[a] ?? 0));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        0,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Finances des expéditeurs', style: AppTheme.h2),
            const SizedBox(height: AppTheme.spaceXs),
            const Text(
              'CA encaissé, commission réglée et restant due par expéditeur.',
              style: AppTheme.caption,
            ),
            const SizedBox(height: AppTheme.spaceSm),
            for (final id in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                child: Row(
                  children: [
                    if (userIdByShipper[id] != null)
                      UserAvatar(
                        userId: userIdByShipper[id]!,
                        initial: nameByShipper[id],
                        imageUrl: avatarByShipper[id],
                        radius: 14,
                      )
                    else
                      GradientAvatar(
                        initial: nameByShipper[id],
                        imageUrl: avatarByShipper[id],
                        radius: 14,
                      ),
                    const SizedBox(width: AppTheme.spaceSm + 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nameByShipper[id] ?? 'Expéditeur',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.body
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'CA: ${_money(caByShipper[id] ?? 0)} DZD',
                            style: AppTheme.caption,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Payé: ${_money(paidByShipper[id] ?? 0)} DZD',
                          style: AppTheme.caption
                              .copyWith(color: AppTheme.accentColor),
                        ),
                        Text(
                          (dueByShipper[id] ?? 0) > 0
                              ? 'Due: ${_money(dueByShipper[id] ?? 0)} DZD'
                              : 'Pas de dettes',
                          style: AppTheme.caption.copyWith(
                            color: (dueByShipper[id] ?? 0) > 0
                                ? AppTheme.warningColor
                                : AppTheme.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.name,
    required this.value,
    required this.detail,
    this.avatar,
  });

  final String name;
  final String value;
  final String detail;
  final User? avatar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (avatar != null)
          UserAvatar(
            userId: avatar!.id,
            initial: avatar!.fullName,
            imageUrl: avatar!.profilePictureUrl,
            radius: 14,
          )
        else
          const GradientAvatar(initial: '?', radius: 14),
        const SizedBox(width: AppTheme.spaceSm + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(detail, style: AppTheme.caption),
            ],
          ),
        ),
        Text(
          value,
          style: AppTheme.body.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.accentColor,
          ),
        ),
      ],
    );
  }
}
