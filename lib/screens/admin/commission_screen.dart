import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';

/// Platform commissions overview: what has been collected vs outstanding debt.
class CommissionScreen extends ConsumerWidget {
  const CommissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(platformFeeSummaryProvider);
    final settings = ref.watch(platformSettingsProvider);
    final rate = settings.valueOrNull?.commissionPercent ??
        AppConstants.platformCommissionPercent;
    final currency =
        settings.valueOrNull?.defaultCurrency ?? AppConstants.defaultCurrency;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(platformFeeSummaryProvider);
            ref.invalidate(platformSettingsProvider);
          },
          child: summary.when(
            data: (stats) {
              final collected = (stats?['collected'] as num?)?.toDouble() ?? 0;
              final pending = (stats?['pending'] as num?)?.toDouble() ?? 0;
              final total = (stats?['total'] as num?)?.toDouble() ?? 0;

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  GradientSliverHeader(
                    title: 'Commissions',
                    subtitle:
                        'Commission plateforme ($rate%) · encaissées et dues',
                    icon: Icons.percent_rounded,
                    expandedHeight: 140,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceMd),
                      child: GlassCard(
                        padding: const EdgeInsets.all(AppTheme.spaceLg),
                        child: Column(
                          children: [
                            Text(
                              'Commission totale ($rate%)',
                              style: AppTheme.caption,
                            ),
                            const SizedBox(height: AppTheme.spaceXs),
                            Text(
                              '${total.toStringAsFixed(0)} $currency',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceMd,
                      ),
                      child: _CommissionRow(
                        icon: Icons.check_circle_rounded,
                        color: AppTheme.accentColor,
                        label: 'Encaissé (payé)',
                        value: '${collected.toStringAsFixed(0)} $currency',
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
                      child: _CommissionRow(
                        icon: Icons.pending_actions_rounded,
                        color: AppTheme.warningColor,
                        label: 'Dettes (non payées)',
                        value: '${pending.toStringAsFixed(0)} $currency',
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
          ),
        ),
      ),
    );
  }
}

class _CommissionRow extends StatelessWidget {
  const _CommissionRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        child: Row(
          children: [
            AnimatedIconDot(icon: icon, color: color),
            const SizedBox(width: AppTheme.spaceSm + 4),
            Expanded(
              child: Text(label, style: AppTheme.bodySecondary),
            ),
            Text(
              value,
              style: AppTheme.body.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
