import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/profile_navigation.dart';
import '../../core/widgets/gradient_sliver_header.dart';

/// Écran finance / compta détaillé pour un type d'expéditeur donné
/// (voyageurs ordinaires ou micro-importateurs), côté Fondateur.
///
/// Agrége les finances des expéditeurs du type : CA encaissé, commissions
/// réglées et dues, effectifs, commandes en attente, top route — puis liste
/// chaque expéditeur du type avec ses propres chiffres (cliquable → profil).
class ShipperTypeFinanceScreen extends ConsumerWidget {
  final String shipperType;
  final String title;

  const ShipperTypeFinanceScreen({
    super.key,
    required this.shipperType,
    required this.title,
  });

  bool get _isMicro => shipperType == 'micro_importateur';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shippers =
        ref.watch(allShippersProvider).valueOrNull ?? const <Shipper>[];
    final bookings =
        ref.watch(allBookingsProvider).valueOrNull ?? const <Booking>[];
    final fees =
        ref.watch(allPlatformFeesProvider).valueOrNull ?? const <PlatformFee>[];

    final group =
        shippers.where((s) => s.shipperType == shipperType).toList(growable: false);
    final ids = group.map((s) => s.id).toSet();

    var ca = 0.0;
    var paid = 0.0;
    var due = 0.0;
    var pendingCount = 0;
    final activeIds = <String>{};
    final routeCounts = <String, int>{};
    // Per-shipper aggregates
    final shipperCa = <String, double>{};
    final shipperPaid = <String, double>{};
    final shipperDue = <String, double>{};
    final shipperBookings = <String, int>{};

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    for (final b in bookings) {
      final sid = b.shipment?.shipper?.id;
      if (sid == null || !ids.contains(sid)) continue;
      shipperBookings[sid] = (shipperBookings[sid] ?? 0) + 1;
      if (b.createdAt.isAfter(thirtyDaysAgo)) activeIds.add(sid);
      if (b.status == 'pending') pendingCount++;
      if (b.paymentStatus == 'paid' && b.status != 'cancelled') {
        ca += b.totalPrice;
        shipperCa[sid] = (shipperCa[sid] ?? 0) + b.totalPrice;
      }
      final origin = b.shipment?.originCountry;
      final dest = b.shipment?.destinationCity;
      if (origin != null && dest != null) {
        final route = '$origin → $dest';
        routeCounts[route] = (routeCounts[route] ?? 0) + 1;
      }
    }

    for (final f in fees) {
      if (!ids.contains(f.shipperId)) continue;
      if (f.isPaid) {
        paid += f.amount;
        shipperPaid[f.shipperId] = (shipperPaid[f.shipperId] ?? 0) + f.amount;
      } else {
        due += f.amount;
        shipperDue[f.shipperId] = (shipperDue[f.shipperId] ?? 0) + f.amount;
      }
    }

    final topRoute = routeCounts.isNotEmpty
        ? (routeCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first.key
        : null;
    final avgRevenue = group.isNotEmpty ? ca / group.length : 0.0;

    final sorted = [...group]..sort((a, b) {
        final aCa = shipperCa[a.id] ?? 0.0;
        final bCa = shipperCa[b.id] ?? 0.0;
        return bCa.compareTo(aCa);
      });

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          CompactSliverHeader(
            title: title,
            subtitle: '${group.length} expéditeur(s)  •  finance détaillée',
            icon: _isMicro
                ? Icons.storefront_rounded
                : Icons.work_outline_rounded,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryCard(context, 'Synthèse', [
                    ('CA encaissé', '${ca.toStringAsFixed(0)} DZD',
                        AppTheme.primaryColor),
                    ('Commissions réglées', '${paid.toStringAsFixed(0)} DZD',
                        AppTheme.accentColor),
                    ('Commissions dues', '${due.toStringAsFixed(0)} DZD',
                        due > 0 ? AppTheme.warningColor : AppTheme.accentColor),
                    ('CA / expéditeur', '${avgRevenue.toStringAsFixed(0)} DZD',
                        AppTheme.infoColor),
                    ('Actifs (30 j)',
                        '${activeIds.length}/${group.length}',
                        AppTheme.infoColor),
                    ('Commande(s) en attente', '$pendingCount',
                        pendingCount > 0
                            ? AppTheme.warningColor
                            : AppTheme.accentColor),
                  ]),
                  if (topRoute != null) ...[
                    const SizedBox(height: AppTheme.spaceSm),
                    Row(
                      children: [
                        const Icon(Icons.route, size: 14,
                            color: AppTheme.primaryColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('Top route : $topRoute',
                              style: AppTheme.caption,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppTheme.spaceLg),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Expéditeurs',
                            style: AppTheme.h2),
                      ),
                      Text('${group.length}',
                          style: AppTheme.body
                              .copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  if (sorted.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Aucun expéditeur de ce type')),
                    )
                  else
                    ...sorted.map(
                      (s) => _ShipperFinanceRow(
                        shipper: s,
                        ca: shipperCa[s.id] ?? 0,
                        paid: shipperPaid[s.id] ?? 0,
                        due: shipperDue[s.id] ?? 0,
                        bookingsCount: shipperBookings[s.id] ?? 0,
                        active: activeIds.contains(s.id),
                        onTap: () => openShipperProfile(context, ref, s.id),
                      ),
                    ),
                  const SizedBox(height: AppTheme.spaceXxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
      BuildContext context, String title, List<(String, String, Color)> stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.h3),
          const SizedBox(height: AppTheme.spaceSm),
          Wrap(
            spacing: AppTheme.spaceSm,
            runSpacing: AppTheme.spaceSm,
            children: stats
                .map((s) => Container(
                      width:
                          (MediaQuery.of(context).size.width - 60) / 2,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: s.$3.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.$2,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: s.$3,
                            ),
                          ),
                          Text(s.$1, style: AppTheme.caption),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ShipperFinanceRow extends StatelessWidget {
  final Shipper shipper;
  final double ca;
  final double paid;
  final double due;
  final int bookingsCount;
  final bool active;
  final VoidCallback onTap;

  const _ShipperFinanceRow({
    required this.shipper,
    required this.ca,
    required this.paid,
    required this.due,
    required this.bookingsCount,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = shipper.user?.fullName ?? 'Expéditeur';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: Material(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                  color: AppTheme.textMutedColor.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTheme.body
                            .copyWith(fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (shipper.isVerified) ...[
                      const Icon(Icons.verified_rounded,
                          size: 16, color: AppTheme.infoColor),
                      const SizedBox(width: 4),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: active
                            ? AppTheme.accentColor.withValues(alpha: 0.15)
                            : AppTheme.textMutedColor.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        active ? 'Actif 30j' : 'Inactif',
                        style: AppTheme.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: active
                              ? AppTheme.accentColor
                              : AppTheme.textMutedColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Wrap(
                  spacing: AppTheme.spaceSm,
                  runSpacing: AppTheme.spaceSm,
                  children: [
                    _miniStat('CA', '${ca.toStringAsFixed(0)} DZD',
                        AppTheme.primaryColor),
                    _miniStat('Comm. réglées', '${paid.toStringAsFixed(0)} DZD',
                        AppTheme.accentColor),
                    _miniStat('Comm. dues',
                        '${due.toStringAsFixed(0)} DZD',
                        due > 0
                            ? AppTheme.warningColor
                            : AppTheme.accentColor),
                    _miniStat('Commandes', '$bookingsCount',
                        AppTheme.infoColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: color),
          ),
          Text(label, style: AppTheme.caption),
        ],
      ),
    );
  }
}
