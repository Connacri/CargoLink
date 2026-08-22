import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';

/// « Mes publicités » (expéditeur) : l'expéditeur crée une pub sponsorisée
/// (image paysage + titre + lien + audience). Elle est d'abord validée par un
/// admin/super_admin, puis l'expéditeur paie les frais de publication et
/// l'admin confirme : la pub apparaît alors en haut de l'accueil choisi.
class ShipperAdsScreen extends ConsumerStatefulWidget {
  const ShipperAdsScreen({super.key});

  @override
  ConsumerState<ShipperAdsScreen> createState() => _ShipperAdsScreenState();
}

class _ShipperAdsScreenState extends ConsumerState<ShipperAdsScreen> {
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  Uint8List? _imageBytes;
  String _imageName = '';
  String _audience = 'all';
  bool _isSaving = false;
  int? _imageWidth;
  int? _imageHeight;

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  /// Libellé lisible du poids du fichier (Ko / Mo).
  String get _imageWeightLabel {
    if (_imageBytes == null) return '';
    final ko = _imageBytes!.lengthInBytes / 1024;
    return ko >= 1024
        ? '${(ko / 1024).toStringAsFixed(1)} Mo'
        : '${ko.toStringAsFixed(0)} Ko';
  }

  /// Décode l'image pour récupérer ses dimensions (largeur × hauteur).
  Future<void> _decodeImageDimensions(Uint8List bytes) async {
    int? width;
    int? height;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      width = frame.image.width;
      height = frame.image.height;
      frame.image.dispose();
      codec.dispose();
    } catch (_) {
      // Image illisible : on laisse les dimensions à null.
    }
    if (!mounted) return;
    setState(() {
      _imageWidth = width;
      _imageHeight = height;
    });
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
    await _decodeImageDimensions(bytes);
  }

  Future<void> _submit() async {
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
          );
      _titleController.clear();
      _linkController.clear();
      setState(() {
        _imageBytes = null;
        _imageName = '';
        _audience = 'all';
        _imageWidth = null;
        _imageHeight = null;
      });
      ref.invalidate(myAdsProvider);
      ref.invalidate(allAdsProvider);
      _snack(
        'Publicité envoyée — validation par un admin en cours',
        AppTheme.accentColor,
      );
    } catch (e) {
      _snack('Échec: $e', AppTheme.errorColor);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// L'expéditeur déclare avoir payé les frais (l'admin vérifie ensuite).
  Future<void> _declarePayment(Ad ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déclaration de paiement'),
        content: Text(
          'Avez-vous payé les frais de publication de '
          '${ad.priceDzd.toStringAsFixed(0)} ${AppConstants.defaultCurrency} ? '
          'Un admin vérifiera puis mettra votre publicité en ligne.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, j\'ai payé'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adsServiceProvider).declarePayment(ad.id);
      ref.invalidate(myAdsProvider);
      ref.invalidate(allAdsProvider);
      _snack('Paiement déclaré — confirmation admin en attente',
          AppTheme.accentColor);
    } catch (e) {
      if (mounted) _snack('Échec: $e', AppTheme.errorColor);
    }
  }

  Future<void> _deleteDraft(Ad ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la publicité'),
        content:
            const Text('Voulez-vous vraiment supprimer cette publicité ?'),
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
      ref.invalidate(myAdsProvider);
      ref.invalidate(allAdsProvider);
    } catch (e) {
      if (mounted) _snack('Échec: $e', AppTheme.errorColor);
    }
  }

  void _snack(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ads = ref.watch(myAdsProvider);
    final shipper = ref.watch(currentShipperProvider).valueOrNull;
    final isMicroImportateur = shipper?.isMicroImportateur ?? false;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(myAdsProvider),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const GradientSliverHeader(
                title: 'Mes publicités',
                subtitle:
                    'Sponsorisez votre activité sur CargoLink',
                icon: Icons.campaign_outlined,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd,
                      AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceSm),
                  child: GlassCard(
                    child: Row(
                      children: [
                        const AnimatedIconDot(
                          icon: Icons.info_outline_rounded,
                          color: AppTheme.warningColor,
                        ),
                        const SizedBox(width: AppTheme.spaceSm),
                        Expanded(
                          child: Text(
                            'Frais de publication : '
                            '${AppConstants.adPublicationFeeDzd.toStringAsFixed(0)} '
                            '${AppConstants.defaultCurrency}. Votre pub est '
                            'validée par un admin avant mise en ligne.',
                            style: AppTheme.caption,
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
                      horizontal: AppTheme.spaceMd),
                  child: isMicroImportateur
                      ? _buildComposer()
                      : const _MicroOnlyNotice(),
                ),
              ),
              ...ads.when(
                data: (items) => _buildListSlivers(items),
                loading: () => [
                  SliverPadding(
                    padding: const EdgeInsets.all(AppTheme.spaceMd),
                    sliver: SliverList.builder(
                      itemCount: 2,
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
          InkWell(
            onTap: _isSaving ? null : _pickImage,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: _imageBytes == null
                        ? AppTheme.textMutedColor
                        : AppTheme.accentColor,
                    width: 1.5,
                  ),
                  color: AppTheme.surfaceColor,
                ),
                clipBehavior: Clip.antiAlias,
                child: _imageBytes == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 32, color: AppTheme.textMutedColor),
                          SizedBox(height: AppTheme.spaceXs),
                          Text(
                            'Image de la pub (format paysage)',
                            style: AppTheme.caption,
                          ),
                          SizedBox(height: AppTheme.spaceXs),
                          Text(
                            '16:9 recommandé, max 5 Mo',
                            style: AppTheme.caption,
                          ),
                        ],
                      )
                     : Image.memory(_imageBytes!, fit: BoxFit.cover),
              ),
            ),
          ),
          if (_imageBytes != null) ...[
            const SizedBox(height: AppTheme.spaceXs),
            Row(
              children: [
                const Icon(Icons.aspect_ratio_rounded,
                    size: 14, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 4),
                Text(
                  _imageWidth != null && _imageHeight != null
                      ? '$_imageWidth × $_imageHeight px'
                      : 'Dimensions inconnues',
                  style: AppTheme.caption,
                ),
                const SizedBox(width: AppTheme.spaceSm),
                const Icon(Icons.sd_storage_outlined,
                    size: 14, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 4),
                Text(_imageWeightLabel, style: AppTheme.caption),
                const SizedBox(width: AppTheme.spaceSm),
                Flexible(
                  child: Text(
                    _imageName,
                    style: AppTheme.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              _imageBytes!.lengthInBytes > 2 * 1024 * 1024
                  ? 'Image un peu lourde : en dessous de 2 Mo, elle se charge '
                      'plus vite pour les clients.'
                  : 'Format 16:9 recommandé — la bannière sera recadrée '
                      'en paysage.',
              style: AppTheme.caption.copyWith(
                color: AppTheme.textMutedColor,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spaceSm + 4),
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Titre (optionnel)',
              hintText: 'Ex : Livraison rapide Algérie → France',
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
          const Text('Afficher ma pub à', style: AppTheme.caption),
          const SizedBox(height: AppTheme.spaceXs),
          Wrap(
            spacing: AppTheme.spaceXs,
            runSpacing: AppTheme.spaceXs,
            children: Ad.audienceLabels.entries
                .map((entry) => ChoiceChip(
                      label: Text(entry.value),
                      selected: _audience == entry.key,
                      onSelected: (_) => setState(() => _audience = entry.key),
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
            onPressed: _isSaving ? null : _submit,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_isSaving
                ? 'Envoi…'
                : 'Envoyer pour validation (${AppConstants.adPublicationFeeDzd.toStringAsFixed(0)} '
                    '${AppConstants.defaultCurrency})'),
          ),
        ],
      ),
    );
  }

  /// Liste groupée : pubs en ligne d'abord, puis en attente (validation ou
  /// paiement), puis refusées — l'expéditeur voit tout ce qu'il a publié.
  List<Widget> _buildListSlivers(List<Ad> items) {
    if (items.isEmpty) return const [];
    final live = items.where((a) => a.isLive).toList(growable: false);
    // En attente = validation en cours (pending) OU paiement à déclarer /
    // paiement déclaré (awaiting_payment).
    final waiting =
        items.where((a) => !a.isLive && !a.isRejected).toList(growable: false);
    final rejected = items.where((a) => a.isRejected).toList(growable: false);

    List<Widget> section(String title, List<Ad> ads, LinearGradient gradient) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd,
                AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceSm),
            child: Row(
              children: [
                Text(title, style: AppTheme.h3),
                const SizedBox(width: AppTheme.spaceSm),
                GradientBadge(label: '${ads.length}', gradient: gradient),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
          sliver: SliverList.builder(
            itemCount: ads.length,
            itemBuilder: (context, index) => StaggeredEntrance(
              delay: Duration(milliseconds: (index % 10) * 40),
              child: _MyAdCard(
                ad: ads[index],
                onDeclarePayment: () => _declarePayment(ads[index]),
                onDelete: () => _deleteDraft(ads[index]),
              ),
            ),
          ),
        ),
      ];
    }

    return [
      if (live.isNotEmpty)
        ...section('En ligne', live, AppTheme.successGradient),
      if (waiting.isNotEmpty)
        ...section('En attente', waiting, AppTheme.infoGradient),
      if (rejected.isNotEmpty)
        ...section('Refusées', rejected, AppTheme.errorGradient),
      const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spaceXxl)),
    ];
  }
}

/// Notice affichée aux expéditeurs non micro-importateurs : la publication
/// de publicités est réservée aux comptes micro-importateurs.
class _MicroOnlyNotice extends StatelessWidget {
  const _MicroOnlyNotice();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: Column(
        children: [
          AnimatedIconDot(
            icon: Icons.storefront_outlined,
            color: AppTheme.primaryColor,
          ),
          SizedBox(height: AppTheme.spaceSm),
          Text(
            'Réservé aux micro-importateurs',
            style: AppTheme.h3,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.spaceXs),
          Text(
            'La publicité sponsorisée est offerte aux comptes '
            'micro-importateurs (commerçants). Depuis « Choisir votre rôle », '
            'passez en micro-importateur avec votre carte de commerce : après '
            'validation par un admin, vous pourrez soumettre vos publicités.',
            style: AppTheme.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MyAdCard extends StatelessWidget {
  const _MyAdCard({
    required this.ad,
    required this.onDeclarePayment,
    required this.onDelete,
  });

  final Ad ad;
  final VoidCallback onDeclarePayment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    LinearGradient gradient;
    String label;
    String? hint;

    if (ad.isLive) {
      gradient = AppTheme.successGradient;
      label = 'En ligne';
    } else if (ad.isPending) {
      gradient = AppTheme.warningGradient;
      label = 'Validation en cours';
      hint = 'Un admin examine votre publicité.';
    } else if (ad.isAwaitingPayment) {
      gradient = AppTheme.infoGradient;
      if (ad.paymentDeclaredAt != null) {
        label = 'Paiement déclaré';
        hint = 'En attente de la confirmation du paiement par un admin.';
      } else {
        label = 'Acceptée — paiement requis';
        hint =
            'Payez ${ad.priceDzd.toStringAsFixed(0)} ${AppConstants.defaultCurrency} '
            'puis déclarez votre paiement.';
      }
    } else {
      gradient = AppTheme.errorGradient;
      label = 'Refusée';
      hint = ad.rejectionReason ?? 'Contactez un administrateur.';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
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
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm + 4),
            Row(
              children: [
                GradientBadge(
                  label: ad.audienceLabel,
                  gradient: AppTheme.darkGradient,
                  compact: true,
                ),
                const SizedBox(width: AppTheme.spaceXs),
                GradientBadge(label: label, gradient: gradient, compact: true),
              ],
            ),
            if (hint != null) ...[
              const SizedBox(height: AppTheme.spaceXs),
              Text(hint, style: AppTheme.caption),
            ],
            if (ad.isAwaitingPayment && ad.paymentDeclaredAt == null) ...[
              const SizedBox(height: AppTheme.spaceSm),
              FilledButton.icon(
                onPressed: onDeclarePayment,
                icon: const Icon(Icons.payments_rounded, size: 18),
                label: const Text('J\'ai effectué le paiement'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  minimumSize: const Size(48, 44),
                ),
              ),
            ],
            if (!ad.isLive && ad.status != Ad.statusAwaitingPayment) ...[
              const SizedBox(height: AppTheme.spaceSm),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppTheme.errorColor),
                  onPressed: onDelete,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
