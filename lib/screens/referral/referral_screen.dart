import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/referral_models.dart';
import '../../data/services/deep_link_service.dart';
import '../../providers/index.dart';

/// Programme de parrainage CargoLink — accessible depuis le profil de TOUS
/// les rôles.
///
/// - Le parrain gagne un % configurable de la commission plateforme sur chaque
///   colis livré et payé par un filleul inscrit avec son code.
/// - Tous les 3 filleuls qualifiés : 3 vidéos témoignages à soumettre,
///   validées par le fondateur, pour débloquer la suite.
class ReferralScreen extends ConsumerStatefulWidget {
  /// Code parrain à pré-remplir dans le champ « Être parrainé » (ex. reçu via
  /// un lien profond `cargolink://referral/<code>`).
  final String? initialCode;

  const ReferralScreen({super.key, this.initialCode});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final _url1Ctrl = TextEditingController();
  final _url2Ctrl = TextEditingController();
  final _url3Ctrl = TextEditingController();
  final _sponsorCodeCtrl = TextEditingController();
  bool _submitting = false;
  bool _requestingPayout = false;
  bool _applyingSponsor = false;

  @override
  void initState() {
    super.initState();
    final code = widget.initialCode;
    if (code != null && code.trim().isNotEmpty) {
      _sponsorCodeCtrl.text = code.trim().toUpperCase();
    }
  }

  @override
  void dispose() {
    _url1Ctrl.dispose();
    _url2Ctrl.dispose();
    _url3Ctrl.dispose();
    _sponsorCodeCtrl.dispose();
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

  String _shareText(String code) {
    final link = DeepLinkService.referralLink(code);
    return 'Rejoins CargoLink avec mon code parrain $code ! '
        'Ouvre ce lien pour t\'inscrire directement :\n$link\n'
        'Télécharge l\'app si tu ne l\'as pas : $_playStoreUrl\n'
        '🌍✈️ Envoie des colis partout dans le monde !';
  }

  Future<void> _share(String code) async {
    await Share.share(_shareText(code), subject: 'Rejoins CargoLink !');
  }

  Future<void> _requestPayout(double amount) async {
    if (amount <= 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Demander le paiement'),
        content: Text(
          'Envoyer une demande de paiement de ${amount.toStringAsFixed(0)} DZD '
          'au fondateur ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Demander'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _requestingPayout = true);
    try {
      final userId = ref.read(authServiceProvider).currentUserId!;
      await ref.read(referralServiceProvider).requestPayout(
            parrainId: userId,
            amount: amount,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande de paiement envoyée au fondateur ✓'),
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
      if (mounted) setState(() => _requestingPayout = false);
    }
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

  /// Applique un code parrain saisi (ou reçu par lien) pour devenir filleul.
  Future<void> _applySponsorCode() async {
    final code = _sponsorCodeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saisissez un code parrain')),
      );
      return;
    }
    final userId = ref.read(authServiceProvider).currentUserId;
    if (userId == null) return;

    setState(() => _applyingSponsor = true);
    try {
      final ok = await ref
          .read(referralServiceProvider)
          .applyReferralCode(filleulId: userId, code: code);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous êtes maintenant parrainé ✓'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        _sponsorCodeCtrl.clear();
        ref.invalidate(myReferralStatsProvider);
        ref.invalidate(myReferralFilleulsProvider);
        ref.invalidate(myReferralBatchesProvider);
        ref.invalidate(isCurrentUserParrainProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Code invalide, déjà rattaché à un parrain, ou votre propre code.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _applyingSponsor = false);
    }
  }

  /// Carte « Être parrainé » : champ manuel pour saisir un code parrain.
  Widget _buildSponsorCard() {
    final userId = ref.watch(authServiceProvider).currentUserId;
    final filled = _sponsorCodeCtrl.text.trim().isNotEmpty;
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
                  color: AppTheme.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.group_add_rounded,
                    color: AppTheme.accentColor, size: 22),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              const Expanded(
                child: Text('Être parrainé', style: AppTheme.h3),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          const Text(
            'Vous avez le code d\'un ami ou d\'un expéditeur ? Saisissez-le ici '
            'pour devenir son filleul et bénéficier de son parrainage.',
            style: AppTheme.bodySecondary,
          ),
          const SizedBox(height: AppTheme.spaceMd),
          TextField(
            controller: _sponsorCodeCtrl,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _applySponsorCode(),
            decoration: InputDecoration(
              labelText: filled ? 'Code parrain' : 'Code de parrainage',
              hintText: 'Ex : AB2CD3EF',
              prefixIcon: const Icon(Icons.card_giftcard_rounded),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _applyingSponsor ? null : _applySponsorCode,
              icon: _applyingSponsor
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.verified_rounded, size: 18),
              label: Text(
                  _applyingSponsor ? 'Application…' : 'Valider le code parrain'),
            ),
          ),
          if (filled && userId != null) ...[
            const SizedBox(height: AppTheme.spaceXs),
            const Text(
              'Le code s\'appliquera à votre compte dès validation.',
              style: AppTheme.caption,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final programActive = ref.watch(referralProgramActiveProvider);
    final stats = ref.watch(myReferralStatsProvider);
    final filleuls = ref.watch(myReferralFilleulsProvider);
    final batches = ref.watch(myReferralBatchesProvider);
    final settings = ref.watch(platformSettingsProvider);

    final commissionPct = settings.valueOrNull?.referralCommissionPercent ?? 50;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programme de parrainage'),
        actions: const [FeedbackIconButton()],
      ),
      body: SafeArea(
        top: false,
        child: programActive.when(
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
                  _buildSponsorCard(),
                  const SizedBox(height: AppTheme.spaceMd),
                  _buildHowItWorks(commissionPct),
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
                        if (s.totalPending > 0)
                          _buildPayoutButton(s.totalPending),
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
      ),
    );
  }

  Widget _buildHowItWorks(double commissionPct) {
    final steps = [
      (
        Icons.share_rounded,
        'Partagez votre code',
        'Envoyez votre code parrain à vos proches — par message, réseaux '
            'sociaux ou en personne. Chaque personne qui s\'inscrit avec votre '
            'code devient votre filleul.',
      ),
      (
        Icons.shopping_bag_rounded,
        'Votre filleul commande',
        'Il passe sa première commande de colis sur CargoLink et choisit un '
            'expéditeur vérifié. Vous n\'avez rien d\'autre à faire.',
      ),
      (
        Icons.savings_rounded,
        'Vous gagnez $commissionPct% de commission',
        'Dès que le colis est livré et payé, $commissionPct% de la commission '
            'plateforme est automatiquement versé sur votre wallet parrain.',
      ),
      (
        Icons.payments_rounded,
        'Retirez votre argent',
        'Cumulez les gains et demandez le paiement directement depuis cette '
            'page. Virement sur votre compte en quelques clics.',
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
                child:
                    Text('Gagnez de l\'argent simplement', style: AppTheme.h3),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          const Text(
            'Invitez des amis, ils commandent, vous êtes payé. C\'est tout.',
            style: AppTheme.bodySecondary,
          ),
          const SizedBox(height: AppTheme.spaceMd),
          ...steps.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(s.$1, size: 16, color: AppTheme.primaryColor),
                    ),
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
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
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            'Appuyez pour copier',
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
                  label: const Text('Copier'),
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
            label: 'Perçus',
            value: s.totalPaid.toStringAsFixed(0),
          ),
        ),
        const SizedBox(width: AppTheme.spaceSm),
        Expanded(
          child: _StatBox(
            icon: Icons.hourglass_top_rounded,
            label: 'Attente',
            value: s.totalPending.toStringAsFixed(0),
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutButton(double pendingAmount) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: AppTheme.accentColor, size: 20),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gains en attente', style: AppTheme.label),
                    Text(
                      '${pendingAmount.toStringAsFixed(0)} DZD',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _requestingPayout
                  ? null
                  : () => _requestPayout(pendingAmount),
              icon: _requestingPayout
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label:
                  Text(_requestingPayout ? 'Envoi…' : 'Demander le paiement'),
            ),
          ),
        ],
      ),
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
                style: AppTheme.caption.copyWith(color: AppTheme.accentColor)),
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
              label: Text(
                  _submitting ? 'Envoi…' : 'Demander le parrainage suivant'),
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
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTheme.spaceMd),
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
                          backgroundColor: AppTheme.surfaceMuted,
                          child: Text('${b.batchNumber}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                        title:
                            Text('Lot ${b.batchNumber}', style: AppTheme.body),
                        trailing: _batchChip(b.status),
                        subtitle:
                            b.reviewNote != null && b.reviewNote!.isNotEmpty
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
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
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
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          Text(label,
              style: AppTheme.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
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
