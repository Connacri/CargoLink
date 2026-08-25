import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/referral_models.dart';
import '../../providers/index.dart';

/// Programme de parrainage CargoLink — accessible depuis le profil de TOUS
/// les rôles.
///
/// - Le parrain gagne 50% de la commission plateforme sur chaque colis livré
///   et payé par un filleul inscrit avec son code.
/// - Tous les 3 filleuls qualifiés : 3 vidéos témoignages à soumettre,
///   validées par le fondateur, pour débloquer la suite.
class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final _url1Ctrl = TextEditingController();
  final _url2Ctrl = TextEditingController();
  final _url3Ctrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _url1Ctrl.dispose();
    _url2Ctrl.dispose();
    _url3Ctrl.dispose();
    super.dispose();
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copié ✓')),
    );
  }

  String get _playStoreUrl =>
      'https://play.google.com/store/apps/details?id=com.cargolink.dz.cargolink';

  String _shareText(String code) =>
      'Rejoins CargoLink avec mon code parrain $code ! '
      'Télécharge l\'app : $_playStoreUrl\n'
      'Et envoie des colis partout dans le monde avec des voyageurs vérifiés 🌍✈️';

  Future<void> _share(String code) async {
    await Share.share(_shareText(code), subject: 'Rejoins CargoLink !');
  }

  Future<void> _submitBatch() async {
    final urls = [
      _url1Ctrl.text.trim(),
      _url2Ctrl.text.trim(),
      _url3Ctrl.text.trim(),
    ];
    if (urls.any((u) => u.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Les 3 liens de vidéos sont obligatoires')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final userId = ref.read(authServiceProvider).currentUserId!;
      await ref.read(referralServiceProvider).submitBatch(
            parrainId: userId,
            videoUrls: urls,
          );
      ref.invalidate(myReferralStatsProvider);
      ref.invalidate(myReferralBatchesProvider);
      _url1Ctrl.clear();
      _url2Ctrl.clear();
      _url3Ctrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Lot soumis ✓ — en attente de validation du fondateur'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final programActive = ref.watch(referralProgramActiveProvider);
    final stats = ref.watch(myReferralStatsProvider);
    final filleuls = ref.watch(myReferralFilleulsProvider);
    final batches = ref.watch(myReferralBatchesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Programme de parrainage')),
      body: programActive.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Erreur de chargement')),
        data: (active) {
          if (!active) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pause_circle_outline_rounded,
                        size: 56, color: Colors.grey.shade500),
                    const SizedBox(height: AppTheme.spaceMd),
                    const Text(
                      'Le programme de parrainage est fermé pour le moment.',
                      textAlign: TextAlign.center,
                      style: AppTheme.h3,
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    const Text(
                      'Il sera relancé prochainement — les parrains inscrits '
                      'conserveront leur code.',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodySecondary,
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myReferralStatsProvider);
              ref.invalidate(myReferralFilleulsProvider);
              ref.invalidate(myReferralBatchesProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              children: [
                _buildHowItWorks(),
                const SizedBox(height: AppTheme.spaceMd),
                stats.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => GlassCard(
                    child: Text('Erreur : $e', style: AppTheme.bodySecondary),
                  ),
                  data: (s) => Column(
                    children: [
                      _buildMyCode(s),
                      const SizedBox(height: AppTheme.spaceMd),
                      _buildStatsRow(s),
                      const SizedBox(height: AppTheme.spaceMd),
                      _buildNextBatchSection(s),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMd),
                _buildFilleuls(filleuls),
                const SizedBox(height: AppTheme.spaceMd),
                _buildBatches(batches),
                const SizedBox(height: AppTheme.spaceXxl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHowItWorks() {
    const steps = [
      (
        Icons.person_add_rounded,
        '1. Partagez votre code',
        'Envoyez votre code ou lien d\'invitation à vos proches via WhatsApp, '
            'Telegram ou Facebook.'
      ),
      (
        Icons.shopping_bag_rounded,
        '2. Ils commandent',
        'Votre filleul s\'inscrit avec votre code et passe sa première commande '
            'auprès d\'un expéditeur vérifié.'
      ),
      (
        Icons.local_shipping_rounded,
        '3. Il reçoit et paie son colis',
        'Dès que le colis est livré et payé, vous gagnez automatiquement.'
      ),
      (
        Icons.savings_rounded,
        '4. Vous gagnez 50% de la commission',
        'La plateforme prélève une commission sur chaque commande : vous '
            'en touchez la moitié, versée dans votre wallet parrain.'
      ),
    ];
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.card_giftcard_rounded,
                    color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              const Expanded(
                child: Text('Comment ça marche ?', style: AppTheme.h3),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          ...steps.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(s.$1,
                        size: 20, color: AppTheme.primaryColor),
                    const SizedBox(width: AppTheme.spaceSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.$2, style: AppTheme.label),
                          const SizedBox(height: 2),
                          Text(s.$3, style: AppTheme.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildMyCode(ReferralStats s) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      child: Column(
        children: [
          const Text('MON CODE PARRAIN', style: AppTheme.caption),
          const SizedBox(height: AppTheme.spaceSm),
          GestureDetector(
            onTap: () => _copyCode(s.code),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLg, vertical: AppTheme.spaceSm),
              decoration: BoxDecoration(
                color: AppTheme.primaryLighter,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                s.code,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            'Appuyez sur le code pour le copier',
            style: AppTheme.caption.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _share(s.code),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Partager'),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _copyCode(s.code),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copier le lien'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ReferralStats s) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            icon: Icons.group_rounded,
            label: 'Filleuls',
            value: '${s.filleulsCount}',
          ),
        ),
        const SizedBox(width: AppTheme.spaceSm),
        Expanded(
          child: _StatBox(
            icon: Icons.verified_rounded,
            label: 'Qualifiés',
            value: '${s.qualifiedFilleuls}',
          ),
        ),
        const SizedBox(width: AppTheme.spaceSm),
        Expanded(
          child: _StatBox(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Gains payés',
            value: s.totalPaid.toStringAsFixed(0),
          ),
        ),
        const SizedBox(width: AppTheme.spaceSm),
        Expanded(
          child: _StatBox(
            icon: Icons.hourglass_top_rounded,
            label: 'En attente',
            value: s.totalPending.toStringAsFixed(0),
          ),
        ),
      ],
    );
  }

  Widget _buildNextBatchSection(ReferralStats s) {
    final statusText = switch (s.lastBatchStatus) {
      'pending' => 'Lot ${max(1, s.nextBatchNumber)} en attente de validation',
      'rejected' => 'Lot précédent rejeté — corrigez et resoumettez',
      'suspended' =>
        'Parrainage interrompu (vidéos retirées) — recommencez depuis le début',
      _ => null,
    };
    final progress = s.qualifiedFilleuls - ((s.nextBatchNumber - 1) * 3);

    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.movie_creation_rounded,
                  color: AppTheme.accentColor, size: 22),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: Text(
                  'Demande du parrainage suivant (lot ${s.nextBatchNumber})',
                  style: AppTheme.label,
                ),
              ),
            ],
          ),
          if (statusText != null) ...[
            const SizedBox(height: AppTheme.spaceXs),
            Text(statusText,
                style: AppTheme.caption
                    .copyWith(color: AppTheme.accentColor)),
          ],
          const SizedBox(height: AppTheme.spaceSm),
          LinearProgressIndicator(
            value: (progress.clamp(0, 3)) / 3,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: AppTheme.surfaceMuted,
            valueColor: const AlwaysStoppedAnimation(AppTheme.accentColor),
          ),
          const SizedBox(height: 6),
          Text(
            '${progress.clamp(0, 3)}/3 filleuls qualifiés pour ce lot',
            style: AppTheme.caption,
          ),
          const SizedBox(height: AppTheme.spaceSm),
          const Text(
            'Publiez 3 vidéos témoignages sur Telegram ou WhatsApp : mentionnez '
            '@CargoLink, taguez 5 amis avec le lien de téléchargement et '
            'affichez le logo CargoLink. Le fondateur peut vérifier aléatoirement '
            'que les vidéos restent partagées — sinon le parrainage est interrompu.',
            style: AppTheme.caption,
          ),
          const SizedBox(height: AppTheme.spaceMd),
          _UrlField(controller: _url1Ctrl, hint: 'Lien vidéo témoignage n°1'),
          const SizedBox(height: AppTheme.spaceSm),
          _UrlField(controller: _url2Ctrl, hint: 'Lien vidéo témoignage n°2'),
          const SizedBox(height: AppTheme.spaceSm),
          _UrlField(controller: _url3Ctrl, hint: 'Lien vidéo témoignage n°3'),
          const SizedBox(height: AppTheme.spaceMd),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  (_submitting || !s.canSubmitBatch) ? null : _submitBatch,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_submitting ? 'Envoi…' : 'Demander le parrainage suivant'),
            ),
          ),
          if (!s.canSubmitBatch && s.lastBatchStatus != 'pending') ...[
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              'Débloqué après ${s.nextBatchNumber * 3} filleuls avec colis '
              'livré et payé (${s.qualifiedFilleuls} actuellement).',
              style: AppTheme.caption,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilleuls(AsyncValue<List<ReferralFilleul>> async) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mes filleuls', style: AppTheme.h3),
          const SizedBox(height: AppTheme.spaceSm),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Erreur : $e', style: AppTheme.caption),
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMd),
                  child: Column(
                    children: [
                      Icon(Icons.group_add_rounded,
                          size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: AppTheme.spaceSm),
                      const Text(
                        'Aucun filleul pour l\'instant — partagez votre code !',
                        style: AppTheme.bodySecondary,
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: list
                    .map((f) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor:
                                AppTheme.primaryColor.withValues(alpha: 0.12),
                            child: Text(
                              f.name.isNotEmpty ? f.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor),
                            ),
                          ),
                          title: Text(f.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.body),
                          subtitle: Text(
                            f.completedBookings > 0
                                ? '${f.completedBookings} colis livré(s) & payé(s)'
                                : 'Inscrit — aucune commande terminée',
                            style: AppTheme.caption,
                          ),
                          trailing: f.earned > 0
                              ? Text(
                                  '+${f.earned.toStringAsFixed(0)} DZD',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.green),
                                )
                              : null,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBatches(AsyncValue<List<ReferralBatch>> async) {
    return async.maybeWhen(
      data: (list) => list.isEmpty
          ? const SizedBox.shrink()
          : GlassCard(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Historique des lots', style: AppTheme.h3),
                  const SizedBox(height: AppTheme.spaceSm),
                  ...list.map((b) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppTheme.surfaceMuted,
                          child: Text('${b.batchNumber}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                        title: Text('Lot ${b.batchNumber}',
                            style: AppTheme.body),
                        trailing: _batchChip(b.status),
                        subtitle: b.reviewNote != null &&
                                b.reviewNote!.isNotEmpty
                            ? Text(b.reviewNote!, style: AppTheme.caption)
                            : null,
                      )),
                ],
              ),
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _batchChip(String status) {
    final (color, label) = switch (status) {
      'approved' => (Colors.green, 'Validé'),
      'pending' => (Colors.orange, 'En attente'),
      'rejected' => (Colors.red, 'Rejeté'),
      'suspended' => (Colors.red.shade900, 'Interrompu'),
      _ => (Colors.grey, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceSm),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14)),
          Text(label, style: AppTheme.caption),
        ],
      ),
    );
  }
}

class _UrlField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _UrlField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.url,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: const Icon(Icons.link_rounded, size: 20),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}
