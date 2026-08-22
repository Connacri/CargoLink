import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';

/// Régie publicitaire (fondateur / super_admin) : création de pubs façon
/// Facebook Ads (image paysage + titre + lien + audience) et validation des
/// publicités soumises par les expéditeurs.
///
/// Une pub admin est active immédiatement ; une pub expéditeur suit le
/// circuit pending -> awaiting_payment -> active (voir [AdsService]).
class AdsScreen extends ConsumerStatefulWidget {
  const AdsScreen({super.key});

  @override
  ConsumerState<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends ConsumerState<AdsScreen> {
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  Uint8List? _imageBytes;
  String _imageName = '';
  String _audience = 'all';
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 1024,
      imageQuality: 88,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (bytes.length > AppConstants.maxFileSize) {
      _snack('Image trop volumineuse (max 5 Mo)', AppTheme.errorColor);
      return;
    }
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageName = picked.name;
    });
  }

  Future<void> _save() async {
    final link = _linkController.text.trim();
    if (_imageBytes == null) {
      _snack('Choisissez d\'abord une image (format paysage)',
          AppTheme.errorColor);
      return;
    }
    if (link.isEmpty) {
      _snack('Le lien de destination est requis', AppTheme.errorColor);
      return;
    }
    final uri = Uri.tryParse(link);
    if (uri == null || !uri.hasScheme) {
      _snack('Lien invalide (ex: https://monsite.com)', AppTheme.errorColor);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final storageService = ref.read(storageServiceProvider);
      final imageUrl = await storageService.uploadImageBytes(
        bytes: _imageBytes!,
        path: 'ads/${DateTime.now().millisecondsSinceEpoch}',
        fileName: _imageName.isEmpty
            ? 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg'
            : _imageName,
        bucket: 'ads',
      );
      await ref.read(adsServiceProvider).createAd(
            imageUrl: imageUrl,
            linkUrl: link,
            audience: _audience,
            title: _titleController.text,
            activateImmediately: true,
          );
      _titleController.clear();
      _linkController.clear();
      setState(() {
        _imageBytes = null;
        _imageName = '';
        _audience = 'all';
      });
      ref.invalidate(allAdsProvider);
      ref.invalidate(activeAdsProvider);
      ref.invalidate(shipperActiveAdsProvider);
      _snack('Publicité publiée', AppTheme.accentColor);
    } catch (e) {
      _snack('Échec: $e', AppTheme.errorColor);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _approve(Ad ad) async {
    try {
      await ref.read(adsServiceProvider).approveAd(ad.id);
      _invalidateAll();
      _snack('Pub approuvée — en attente du paiement', AppTheme.accentColor);
    } catch (e) {
      if (mounted) _snack('Échec: $e', AppTheme.errorColor);
    }
  }

  Future<void> _reject(Ad ad) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser la publicité'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration:
              const InputDecoration(labelText: 'Motif du refus'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    try {
      await ref.read(adsServiceProvider).rejectAd(ad.id, reason);
      _invalidateAll();
      _snack('Publicité refusée', AppTheme.accentColor);
    } catch (e) {
      if (mounted) _snack('Échec: $e', AppTheme.errorColor);
    }
  }

  Future<void> _confirmPayment(Ad ad) async {
    try {
      await ref.read(adsServiceProvider).confirmPayment(ad.id);
      _invalidateAll();
      _snack('Paiement confirmé — pub en ligne', AppTheme.accentColor);
    } catch (e) {
      if (mounted) _snack('Échec: $e', AppTheme.errorColor);
    }
  }

  Future<void> _toggle(Ad ad) async {
    try {
      await ref.read(adsServiceProvider).setAdActive(ad.id, !ad.isActive);
      _invalidateAll();
    } catch (e) {
      if (mounted) _snack('Échec: $e', AppTheme.errorColor);
    }
  }

  Future<void> _delete(Ad ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la publicité'),
        content: const Text('Voulez-vous vraiment supprimer cette publicité ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adsServiceProvider).deleteAd(ad.id);
      _invalidateAll();
      _snack('Publicité supprimée', AppTheme.accentColor);
    } catch (e) {
      if (mounted) _snack('Échec: $e', AppTheme.errorColor);
    }
  }

  void _invalidateAll() {
    ref.invalidate(allAdsProvider);
    ref.invalidate(activeAdsProvider);
    ref.invalidate(shipperActiveAdsProvider);
  }

  void _snack(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ads = ref.watch(allAdsProvider);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async => _invalidateAll(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const GradientSliverHeader(
                title: 'Publicités',
                subtitle: 'Bannières sponsorisées des accueil',
                icon: Icons.campaign_outlined,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  child: _buildComposer(),
                ),
              ),
              ...ads.when(
                data: (items) => _buildListSlivers(items),
                loading: () => [
                  SliverPadding(
                    padding: const EdgeInsets.all(AppTheme.spaceMd),
                    sliver: SliverList.builder(
                      itemCount: 3,
                      itemBuilder: (_, i) => const ShimmerCard(lines: 2),
                    ),
                  ),
                ],
                error: (e, s) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'Erreur de chargement: $e',
                        style: AppTheme.bodySecondary,
                      ),
                    ),
                  ),
                ],
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

  Widget _buildComposer() {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      radius: AppTheme.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              AnimatedIconDot(
                icon: Icons.add_business_rounded,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: AppTheme.spaceSm + 4),
              Expanded(
                child: Text(
                  'Créer une publicité',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm + 4),
          // Aperçu live : exactement la bannière vue par les utilisateurs.
          _BannerPreview(
            imageBytes: _imageBytes,
            title: _titleController.text.isEmpty
                ? null
                : _titleController.text,
          ),
          const SizedBox(height: AppTheme.spaceSm + 4),
          InkWell(
            onTap: _isSaving ? null : _pickImage,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.primaryColor, width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _imageBytes == null
                        ? Icons.add_photo_alternate_outlined
                        : Icons.swap_horiz_rounded,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: AppTheme.spaceXs),
                  Text(
                    _imageBytes == null
                        ? 'Ajouter l\'image (paysage, max 5 Mo)'
                        : 'Changer l\'image',
                    style: AppTheme.body.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm + 4),
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 60,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Titre de la publicité (optionnel)',
              hintText: 'Ex : Soldes d\'été chez TechDZ',
              prefixIcon: Icon(Icons.campaign_outlined),
              counterText: '',
            ),
          ),
          TextField(
            controller: _linkController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Lien de destination',
              hintText: 'https://...',
              prefixIcon: Icon(Icons.link_rounded),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm + 4),
          const Text('Audience', style: AppTheme.caption),
          const SizedBox(height: AppTheme.spaceXs),
          Wrap(
            spacing: AppTheme.spaceXs,
            runSpacing: AppTheme.spaceXs,
            children: Ad.audienceLabels.entries
                .map((entry) => ChoiceChip(
                      label: Text(entry.value),
                      selected: _audience == entry.key,
                      onSelected: (_) =>
                          setState(() => _audience = entry.key),
                      selectedColor:
                          AppTheme.primaryColor.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: _audience == entry.key
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.publish_rounded),
            label: Text(_isSaving ? 'Publication…' : 'Publier maintenant'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildListSlivers(List<Ad> items) {
    final pending = items.where((a) => a.isPending).length;
    final headers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMd, 0, AppTheme.spaceMd, AppTheme.spaceSm),
          child: Text(
            items.isEmpty
                ? 'Publicités'
                : pending > 0
                    ? 'Toutes les publicités ($pending en attente)'
                    : 'Toutes les publicités',
            style: AppTheme.h3,
          ),
        ),
      ),
    ];
    if (items.isEmpty) {
      return [
        ...headers,
        const SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyAds(),
        ),
      ];
    }
    return [
      ...headers,
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd, 0, AppTheme.spaceMd, AppTheme.spaceXxl),
        sliver: SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, index) => StaggeredEntrance(
            delay: Duration(milliseconds: (index % 10) * 40),
            child: _AdCard(
              ad: items[index],
              onApprove: () => _approve(items[index]),
              onReject: () => _reject(items[index]),
              onConfirmPayment: () => _confirmPayment(items[index]),
              onToggle: () => _toggle(items[index]),
              onDelete: () => _delete(items[index]),
            ),
          ),
        ),
      ),
    ];
  }
}

/// Rendu identique à la bannière réelle (image paysage cliquable).
class _BannerPreview extends StatelessWidget {
  const _BannerPreview({this.imageBytes, this.title});

  final Uint8List? imageBytes;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          color: AppTheme.surfaceColor,
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageBytes != null)
              Image.memory(imageBytes!, fit: BoxFit.cover)
            else
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined,
                      size: 36, color: AppTheme.textMutedColor),
                  SizedBox(height: AppTheme.spaceXs),
                  Text(
                    'Aperçu de votre bannière',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            if (title != null)
              Positioned(
                left: 12,
                bottom: 10,
                right: 12,
                child: Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(blurRadius: 6, color: Colors.black54),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAds extends StatelessWidget {
  const _EmptyAds();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.campaign_outlined, size: 56, color: AppTheme.textMutedColor),
        SizedBox(height: AppTheme.spaceMd),
        Text('Aucune publicité pour le moment', style: AppTheme.h3),
        SizedBox(height: AppTheme.spaceSm),
        Text(
          'Créez une bannière ou validez celles des expéditeurs.',
          style: AppTheme.bodySecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Badge de statut d'une pub.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.ad});

  final Ad ad;

  @override
  Widget build(BuildContext context) {
    LinearGradient gradient;
    String label;
    if (ad.isLive) {
      gradient = AppTheme.successGradient;
      label = 'En ligne';
    } else if (ad.isPending) {
      gradient = AppTheme.warningGradient;
      label = 'À valider';
    } else if (ad.isAwaitingPayment) {
      gradient = AppTheme.infoGradient;
      label = ad.paymentDeclaredAt == null
          ? 'Paiement requis'
          : 'Paiement déclaré';
    } else {
      gradient = AppTheme.errorGradient;
      label = 'Refusée';
    }
    return GradientBadge(label: label, gradient: gradient, compact: true);
  }
}

class _AdCard extends StatelessWidget {
  const _AdCard({
    required this.ad,
    required this.onApprove,
    required this.onReject,
    required this.onConfirmPayment,
    required this.onToggle,
    required this.onDelete,
  });

  final Ad ad;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onConfirmPayment;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final showReviewActions =
        ad.isPending || (ad.isAwaitingPayment && ad.paymentDeclaredAt != null);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => showFullScreenImage(
                context,
                imageUrl: ad.imageUrl,
                title: ad.title ?? 'Publicité',
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    ad.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.surfaceColor,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined,
                          color: AppTheme.textMutedColor),
                    ),
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : Container(
                                color: AppTheme.surfaceColor,
                                alignment: Alignment.center,
                                child:
                                    const CircularProgressIndicator(
                                        strokeWidth: 2),
                              ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm + 4),
            if (ad.title != null && ad.title!.isNotEmpty) ...[
              Text(
                ad.title!,
                style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
            ],
            Row(
              children: [
                GradientBadge(
                  label: 'Audience : ${ad.audienceLabel}',
                  gradient: AppTheme.darkGradient,
                  compact: true,
                ),
                const SizedBox(width: AppTheme.spaceXs),
                _StatusBadge(ad: ad),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXs),
            InkWell(
              onTap: () async {
                final uri = Uri.tryParse(ad.linkUrl);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                ad.linkUrl,
                style: const TextStyle(
                  color: AppTheme.accentColor,
                  decoration: TextDecoration.underline,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (ad.priceDzd > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Frais : ${ad.priceDzd.toStringAsFixed(0)} '
                  '${AppConstants.defaultCurrency}'
                  '${ad.paymentDeclaredAt != null ? ' • payés par l\'expéditeur' : ''}',
                  style: AppTheme.caption,
                ),
              ),
            if (ad.rejectionReason != null &&
                ad.rejectionReason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Motif : ${ad.rejectionReason}',
                  style: AppTheme.caption.copyWith(color: AppTheme.red),
                ),
              ),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                if (showReviewActions) ...[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          ad.isPending ? onApprove : onConfirmPayment,
                      icon: Icon(
                        ad.isPending
                            ? Icons.check_rounded
                            : Icons.payments_rounded,
                        size: 18,
                      ),
                      label: FittedBox(
                        child: Text(
                            ad.isPending ? 'Approuver' : 'Confirmer paiement'),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        minimumSize: const Size(48, 44),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Refuser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.red,
                        minimumSize: const Size(48, 44),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: ad.status == Ad.statusActive ||
                              ad.status == Ad.statusAwaitingPayment
                          ? onToggle
                          : null,
                      icon: Icon(
                        ad.isActive
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                      ),
                      label: Text(ad.isActive ? 'Masquer' : 'Afficher'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 44),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSm),
                  IconButton(
                    tooltip: 'Supprimer',
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: AppTheme.errorColor),
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
