// ============================================================================
// PROMO CARD SETTINGS (Fondateur) — personnalise la carte « Guide CabaLink »
//
// Depuis cette forme le fondateur peut :
//   - changer l'image de fond de la carte (bucket Supabase « promos ») ;
//   - ajuster le padding LTRB du contenu (titre/sous-titre/CTA) ;
//   - éditer le titre, le sous-titre et le libellé du bouton ;
//   - voir un aperçu en direct et publier (financièrement gratuit).
// ============================================================================

import 'dart:typed_data';
import 'dart:ui' as ui;
// ignore: avoid_web_libraries_in_flutter — image_picker fournit les octets sur
// toutes les plateformes (mobile et web), comme dans AdsScreen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/CabaLinkPromoCard.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/models.dart';
import '../../data/services/promo_card_service.dart';
import '../../providers/index.dart';

class PromoCardSettingsScreen extends ConsumerStatefulWidget {
  const PromoCardSettingsScreen({super.key});

  @override
  ConsumerState<PromoCardSettingsScreen> createState() =>
      _PromoCardSettingsScreenState();
}

class _PromoCardSettingsScreenState
    extends ConsumerState<PromoCardSettingsScreen> {
  static const int _paddingMin = 0;
  static const int _paddingMax = 400;

  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _ctaController = TextEditingController();
  final _paddingLeftController = TextEditingController();
  final _paddingTopController = TextEditingController();
  final _paddingRightController = TextEditingController();
  final _paddingBottomController = TextEditingController();

  /// Octets de la nouvelle image choisie (null = conserver l'existante).
  Uint8List? _imageBytes;
  String _imageName = '';
  int? _imageWidth;
  int? _imageHeight;

  bool _isSaving = false;
  bool _initialized = false;

  PromoCardConfig? _base;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _ctaController.dispose();
    _paddingLeftController.dispose();
    _paddingTopController.dispose();
    _paddingRightController.dispose();
    _paddingBottomController.dispose();
    super.dispose();
  }

  String get _imageWeightLabel {
    if (_imageBytes == null) return '';
    final ko = _imageBytes!.lengthInBytes / 1024;
    return ko >= 1024
        ? '${(ko / 1024).toStringAsFixed(1)} Mo'
        : '${ko.toStringAsFixed(0)} Ko';
  }

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
    } catch (_) {}
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

void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageName = '';
      _imageWidth = null;
      _imageHeight = null;
    });
  }

  int? _parsePadding(TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    if (v == null) return null;
    return v.clamp(_paddingMin, _paddingMax);
  }

  PromoCardConfig _buildDraft(PromoCardConfig fallback) {
    return PromoCardConfig(
      slot: fallback.slot,
      title: _titleController.text.trim().isEmpty
          ? fallback.title
          : _titleController.text.trim(),
      subtitle: _subtitleController.text.trim().isEmpty
          ? fallback.subtitle
          : _subtitleController.text.trim(),
      ctaLabel: _ctaController.text.trim().isEmpty
          ? fallback.ctaLabel
          : _ctaController.text.trim(),
      imageUrl: fallback.imageUrl,
      paddingLeft: _parsePadding(_paddingLeftController) ?? fallback.paddingLeft,
      paddingTop: _parsePadding(_paddingTopController) ?? fallback.paddingTop,
      paddingRight:
          _parsePadding(_paddingRightController) ?? fallback.paddingRight,
      paddingBottom:
          _parsePadding(_paddingBottomController) ?? fallback.paddingBottom,
      isActive: fallback.isActive,
    );
  }

  Future<void> _save() async {
    final base = _base ?? PromoCardConfig.fallback;

    // Validation des champs de texte vides (sinon on retombe sur les valeurs
    // par défaut) et des paddings (bornés 0 à 400 px).
    if (_titleController.text.trim().isEmpty ||
        _subtitleController.text.trim().isEmpty ||
        _ctaController.text.trim().isEmpty) {
      _snack('Tous les textes sont requis', AppTheme.errorColor);
      return;
    }
    for (final c in [
      _paddingLeftController,
      _paddingTopController,
      _paddingRightController,
      _paddingBottomController,
    ]) {
      if (int.tryParse(c.text.trim()) == null) {
        _snack('Chaque padding doit être un nombre entier de pixels',
            AppTheme.errorColor);
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final storageService = ref.read(storageServiceProvider);
      var imageUrl = base.imageUrl;

      // Nouvelle image choisie → téléversée dans le bucket « promos ».
      if (_imageBytes != null) {
        imageUrl = await storageService.uploadImageBytes(
          bytes: _imageBytes!,
          path: 'promo_cards',
          fileName: _imageName.isEmpty
              ? 'guide_${DateTime.now().millisecondsSinceEpoch}.jpg'
              : _imageName,
          bucket: PromoCardService.bucketName,
        );
      }

      final config = _buildDraft(base).copyWith(imageUrl: imageUrl?.trim());
      await ref.read(promoCardServiceProvider).savePromoCard(config);
      ref.invalidate(promoCardProvider);
      if (mounted) {
        // Le nouvel aperçu (image réseau) doit refléter le changement : on
        // nettoie la sélection locale.
        setState(() {
          _imageBytes = null;
          _imageName = '';
          _imageWidth = null;
          _imageHeight = null;
          _base = config;
        });
        _snack('Carte promotionnelle mise à jour', AppTheme.accentColor);
      }
    } catch (e) {
      if (mounted) _snack('Échec: $e', AppTheme.errorColor);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  void _syncFromConfig(PromoCardConfig config) {
    _titleController.text = config.title;
    _subtitleController.text = config.subtitle;
    _ctaController.text = config.ctaLabel;
    _paddingLeftController.text = '${config.paddingLeft}';
    _paddingTopController.text = '${config.paddingTop}';
    _paddingRightController.text = '${config.paddingRight}';
    _paddingBottomController.text = '${config.paddingBottom}';
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(promoCardProvider);
    final config = configAsync.valueOrNull ?? PromoCardConfig.fallback;

    if (!_initialized && configAsync.hasValue) {
      _initialized = true;
      _base = config;
      _syncFromConfig(config);
    }

    // Aperçu en direct : le contenu reflète les champs ; si une nouvelle image
    // est choisie, PromoCardSettingsPreview remplace le fond par ses octets.
    // Le `_base` sert de référence : sa restauration (imageUrl à null) se
    // reflète immédiatement dans l'aperçu.
    final previewConfig = _buildDraft(_base ?? config);

    return configAsync.when(
      data: (_) => _buildScreen(previewConfig, showLoading: false),
      loading: () => _base == null
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _buildScreen(previewConfig, showLoading: false),
      error: (e, s) => Scaffold(
        body: SafeArea(
          top: false,
          child: CustomScrollView(
            slivers: [
              const GradientSliverHeader(
                title: 'Carte Guide CabaLink',
                subtitle: 'Personnalisez la carte de l\'écran de connexion',
                icon: Icons.stars_rounded,
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceMd),
                    child: Text(
                      'Erreur de chargement : $e',
                      style: AppTheme.bodySecondary,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(PromoCardConfig previewConfig,
      {required bool showLoading}) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            GradientSliverHeader(
              title: 'Carte Guide CabaLink',
              subtitle: 'Personnalisez la carte de l\'écran de connexion '
                  '(image de fond, textes et marges)',
              icon: Icons.stars_rounded,
              trailing: showLoading
                  ? null
                  : FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMd,
                  AppTheme.spaceMd,
                  AppTheme.spaceMd,
                  AppTheme.spaceXxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeader(
                      icon: Icons.visibility_rounded,
                      title: 'Aperçu en direct',
                    ),
                    // Rendu réel de la carte. Si une nouvelle image vient d'être
                    // choisie (octets locaux), elle est superposée au fond.
                    PromoCardSettingsPreview(
                      config: previewConfig,
                      localImageBytes: _imageBytes,
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    _sectionHeader(
                      icon: Icons.image_outlined,
                      title: 'Image de fond',
                    ),
                    _buildImagePicker(),
                    const SizedBox(height: AppTheme.spaceLg),
                    _sectionHeader(
                      icon: Icons.text_fields_rounded,
                      title: 'Textes',
                    ),
                    TextField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 60,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Titre',
                        hintText: 'Ex : Guide CabaLink',
                        prefixIcon: Icon(Icons.title_rounded),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    TextField(
                      controller: _subtitleController,
                      maxLines: 2,
                      maxLength: 140,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Sous-titre',
                        prefixIcon: Icon(Icons.notes_rounded),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    TextField(
                      controller: _ctaController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 40,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Bouton (texte)',
                        hintText: 'Ex : Lire le guide',
                        prefixIcon: Icon(Icons.touch_app_rounded),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceLg),
                    _sectionHeader(
                      icon: Icons.space_bar_rounded,
                      title: 'Padding du contenu (px)',
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _paddingField(
                            _paddingLeftController,
                            'Gauche',
                            Icons.format_align_left_rounded,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceSm),
                        Expanded(
                          child: _paddingField(
                            _paddingTopController,
                            'Haut',
                            Icons.vertical_align_top_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    Row(
                      children: [
                        Expanded(
                          child: _paddingField(
                            _paddingRightController,
                            'Droite',
                            Icons.format_align_right_rounded,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceSm),
                        Expanded(
                          child: _paddingField(
                            _paddingBottomController,
                            'Bas',
                            Icons.vertical_align_bottom_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    const Text(
                      'De 0 à 400 px. Le padding décale le texte sur l\'image '
                      '(ex. 175 à gauche garde le bloc hors du visuel).',
                      style: AppTheme.caption,
                    ),
                    const SizedBox(height: AppTheme.spaceLg),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_outlined),
                      label:
                          Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
                    ),
                    const SizedBox(height: AppTheme.spaceXs),
                    const Text(
                      'L\'image est hébergée dans le bucket public « promos ». '
                      'La carte se met à jour pour tous les utilisateurs.',
                      style: AppTheme.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final hasImage = _base?.imageUrl != null &&
            _base!.imageUrl!.trim().isNotEmpty ||
        _imageBytes != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                      ? 'Changer l\'image (paysage, max 5 Mo)'
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
        const SizedBox(height: 6),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_size_select_large,
                size: 14, color: AppTheme.textMutedColor),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                'Taille idéale : grandes bannière 2:1 (~800×400) — affichée '
                'sur l\'écran de connexion.',
                textAlign: TextAlign.center,
                style: AppTheme.caption,
              ),
            ),
          ],
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
        ],
        if (hasImage) ...[
          const SizedBox(height: AppTheme.spaceXs),
          TextButton.icon(
            onPressed: _isSaving
                ? null
                : () {
                    _removeImage();
                    if (_base?.imageUrl != null &&
                        _base!.imageUrl!.trim().isNotEmpty) {
                      setState(
                          () => _base = _base!.copyWith(imageUrl: null));
                    }
                    _snack('Retour à l\'image par défaut — enregistrez pour '
                        'publier', AppTheme.infoColor);
                  },
            icon: const Icon(Icons.restore_rounded, size: 18),
            label: const Text('Revenir à l\'image par défaut'),
          ),
        ],
      ],
    );
  }

  Widget _paddingField(
      TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 3,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixText: 'px',
        counterText: '',
      ),
    );
  }

  Widget _sectionHeader({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: AppTheme.spaceSm),
          Text(title, style: AppTheme.h3),
        ],
      ),
    );
  }
}

/// Aperçu de la carte dans l'écran fondateur. Affiche la carte réelle (config
/// Supabase) et remplace son fond par une nouvelle image locale si présente.
class PromoCardSettingsPreview extends StatelessWidget {
  const PromoCardSettingsPreview({
    super.key,
    required this.config,
    this.localImageBytes,
  });

  final PromoCardConfig config;
  final Uint8List? localImageBytes;

  @override
  Widget build(BuildContext context) {
    return PromoCardView(
      config: config,
      background: localImageBytes == null
          ? null
          : ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.memory(localImageBytes!, fit: BoxFit.cover),
            ),
    );
  }
}