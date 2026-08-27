import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/referral_models.dart';
import '../../providers/index.dart';

/// Dashboard fondateur du programme de parrainage :
/// - KPIs : nombre de parrains, gains payés / en attente
/// - Wallet détaillé de chaque parrain (filleuls, qualifiés, lots)
/// - Lots de vidéos à valider (approuver / rejeter / suspendre)
/// - Gains à payer (wallet) — marquer payé ou annuler
class ReferralAdminScreen extends ConsumerStatefulWidget {
  const ReferralAdminScreen({super.key});

  @override
  ConsumerState<ReferralAdminScreen> createState() =>
      _ReferralAdminScreenState();
}

class _ReferralAdminScreenState extends ConsumerState<ReferralAdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  List<ParrainOverview>? _parrains;
  List<Map<String, dynamic>>? _batches;
  List<Map<String, dynamic>>? _earnings;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(referralServiceProvider);
      final parrains = await service.getAllParrainsOverview();
      await service.prefetchUsers(
          parrains.map((p) => p.user?.id ?? '').where((s) => s.isNotEmpty).toList());
      final refreshed = await service.getAllParrainsOverview();
      final batches = await service.getPendingBatchesWithUsers();
      final earnings = await service.getEarningsWithDetails();
      if (!mounted) return;
      setState(() {
        _parrains = refreshed;
        _batches = batches;
        _earnings = earnings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _reviewBatch(Map<String, dynamic> batch, String status) async {
    final noteCtrl = TextEditingController(text: batch['review_note'] ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(switch (status) {
          'approved' => 'Valider ce lot ?',
          'rejected' => 'Rejeter ce lot ?',
          _ => 'Suspendre ce parrain ?',
        }),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status != 'approved')
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Motif (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            if (status == 'suspended') ...[
              const SizedBox(height: AppTheme.spaceSm),
              const Text(
                'La vidéo a été retirée ? Le parrainage est interrompu et il '
                'devra recommencer depuis le début.',
                style: AppTheme.caption,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(referralServiceProvider).reviewBatch(
            batchId: batch['id'] as String,
            status: status,
            note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
          );
      await _reload();
      ref.invalidate(myReferralBatchesProvider);
      ref.invalidate(myReferralStatsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  Future<void> _markEarning(Map<String, dynamic> earning, bool paid) async {
    try {
      final service = ref.read(referralServiceProvider);
      if (paid) {
        await service.markEarningPaid(earning['id'] as String);
      } else {
        await service.cancelEarning(earning['id'] as String);
      }
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard parrains'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Parrains & wallets'),
            Tab(text: 'Lots & gains'),
          ],
        ),
        actions: [
          const FeedbackIconButton(),
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Erreur : $_error'));
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildParrainsTab(),
          _buildBatchesEarningsTab(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ONGLET 1 — PARRAINS & WALLETS
  // ---------------------------------------------------------------------------

  Widget _buildParrainsTab() {
    final parrains = _parrains ?? [];
    double totalPaid = 0, totalPending = 0;
    for (final p in parrains) {
      totalPaid += p.totalPaid;
      totalPending += p.totalPending;
    }
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.card_giftcard_rounded,
                label: 'Parrains',
                value: '${parrains.length}',
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: _KpiCard(
                icon: Icons.payments_rounded,
                label: 'Versé (DZD)',
                value: totalPaid.toStringAsFixed(0),
                color: Colors.green,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: _KpiCard(
                icon: Icons.hourglass_top_rounded,
                label: 'À payer (DZD)',
                value: totalPending.toStringAsFixed(0),
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMd),
        if (parrains.isEmpty)
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              child: Column(
                children: [
                  Icon(Icons.card_giftcard_outlined,
                      size: 44, color: Colors.grey.shade400),
                  const SizedBox(height: AppTheme.spaceSm),
                  const Text('Aucun parrain inscrit pour l\'instant.',
                      style: AppTheme.bodySecondary),
                ],
              ),
            ),
          )
        else
          ...parrains.map(_buildParrainCard),
      ],
    );
  }

  Widget _buildParrainCard(ParrainOverview p) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    AppTheme.primaryColor.withValues(alpha: 0.12),
                backgroundImage: p.user?.profilePictureUrl != null
                    ? NetworkImage(p.user!.profilePictureUrl!)
                    : null,
                child: p.user?.profilePictureUrl == null
                    ? Text(
                        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor),
                      )
                    : null,
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.label),
                    Text('${p.email} • ${p.user?.role ?? ''}',
                        style: AppTheme.caption),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLighter,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  p.code,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      fontSize: 12,
                      color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            children: [
              _MiniStat(label: 'Filleuls', value: '${p.filleulsCount}'),
              const SizedBox(width: AppTheme.spaceSm),
              _MiniStat(label: 'Qualifiés', value: '${p.qualifiedFilleuls}'),
              const SizedBox(width: AppTheme.spaceSm),
              _MiniStat(
                  label: 'Payé DZD', value: p.totalPaid.toStringAsFixed(0)),
              const SizedBox(width: AppTheme.spaceSm),
              _MiniStat(
                  label: 'Du DZD', value: p.totalPending.toStringAsFixed(0)),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Row(
            children: [
              Icon(_batchIcon(p.lastBatchStatus),
                  size: 14,
                  color: _batchColor(p.lastBatchStatus)),
              const SizedBox(width: 4),
              Text(
                'Dernier lot : ${_batchLabel(p.lastBatchStatus)}'
                '${p.pendingBatches > 0 ? ' • ${p.pendingBatches} en attente' : ''}',
                style: AppTheme.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ONGLET 2 — LOTS & GAINS
  // ---------------------------------------------------------------------------

  Widget _buildBatchesEarningsTab() {
    final batches = _batches ?? [];
    final pendingBatches =
        batches.where((b) => b['status'] == 'pending').toList();
    final earnings = _earnings ?? [];
    final pendingEarnings =
        earnings.where((e) => e['status'] == 'pending').toList();

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      children: [
        const Text('Vidéos témoignages à valider', style: AppTheme.h3),
        const SizedBox(height: AppTheme.spaceSm),
        if (pendingBatches.isEmpty)
          const GlassCard(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spaceLg),
              child: Text('Aucun lot en attente de validation.',
                  style: AppTheme.bodySecondary),
            ),
          )
        else
          ...pendingBatches.map((b) {
            final user = b['users'] as Map<String, dynamic>?;
            return GlassCard(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user?['full_name'] ?? '—'} • Lot ${b['batch_number']}'
                    ' (${user?['email'] ?? ''})',
                    style: AppTheme.label,
                  ),
                  const SizedBox(height: AppTheme.spaceXs),
                  for (var i = 1; i <= 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.link_rounded,
                              size: 14, color: AppTheme.textMutedColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: SelectableText(
                              '${b['video_url_$i'] ?? '—'}',
                              style: AppTheme.caption,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.open_in_new_rounded,
                                size: 16),
                            onPressed: () => _openUrl(b['video_url_$i'] ?? ''),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppTheme.spaceSm),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _reviewBatch(b, 'approved'),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Valider'),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _reviewBatch(b, 'rejected'),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Rejeter'),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _reviewBatch(b, 'suspended'),
                          icon: const Icon(Icons.pause_circle_rounded,
                              size: 18),
                          label: const Text('Suspendre'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: AppTheme.spaceLg),
        const Text('Gains en attente de paiement', style: AppTheme.h3),
        const SizedBox(height: AppTheme.spaceSm),
        if (pendingEarnings.isEmpty)
          const GlassCard(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spaceLg),
              child: Text('Aucun gain en attente.',
                  style: AppTheme.bodySecondary),
            ),
          )
        else
          ...pendingEarnings.map((e) {
            final user = e['users'] as Map<String, dynamic>?;
            final booking = e['bookings'] as Map<String, dynamic>?;
            return ListTile(
              leading: const Icon(Icons.savings_rounded,
                  color: AppTheme.accentColor),
              title: Text(
                  '${user?['full_name'] ?? '—'} • ${(e['amount'] as num).toStringAsFixed(0)} DZD',
                  style: AppTheme.label),
              subtitle: Text(
                'Colis ${booking?['tracking_number'] ?? '—'} • '
                '${(booking?['total_price'] as num?)?.toStringAsFixed(0) ?? '?'} DZD',
                style: AppTheme.caption,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Marquer payé',
                    onPressed: () => _markEarning(e, true),
                    icon: const Icon(Icons.check_circle_rounded,
                        color: Colors.green),
                  ),
                  IconButton(
                    tooltip: 'Annuler',
                    onPressed: () => _markEarning(e, false),
                    icon: const Icon(Icons.cancel_rounded,
                        color: Colors.red),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  IconData _batchIcon(String? s) => switch (s) {
        'approved' => Icons.check_circle_rounded,
        'pending' => Icons.schedule_rounded,
        'rejected' => Icons.cancel_rounded,
        'suspended' => Icons.block_rounded,
        _ => Icons.help_outline_rounded,
      };

  Color _batchColor(String? s) => switch (s) {
        'approved' => Colors.green,
        'pending' => Colors.orange,
        'rejected' => Colors.red,
        'suspended' => Colors.red.shade900,
        _ => Colors.grey,
      };

  String _batchLabel(String? s) => switch (s) {
        'approved' => 'validé',
        'pending' => 'en attente',
        'rejected' => 'rejeté',
        'suspended' => 'interrompu',
        _ => 'aucun',
      };
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceSm),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(label,
              style: AppTheme.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMuted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13)),
            Text(label, style: AppTheme.caption),
          ],
        ),
      ),
    );
  }
}
