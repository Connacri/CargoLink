import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// Gestion des bannières publicitaires de l'accueil client (fondateur /
/// super_admin) : ajouter une pub (image paysage + lien), activer/désactiver,
/// supprimer.
class AdsScreen extends ConsumerStatefulWidget {
  const AdsScreen({super.key});

  @override
  ConsumerState<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends ConsumerState<AdsScreen> {
  final _linkController = TextEditingController();
  Uint8List? _imageBytes;
  String _imageName = '';
  bool _isSaving = false;

  @override
  void dispose() {
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
      _snack('Lien invalide (ex: https://monsite.com)',
          AppTheme.errorColor);
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
          );
      _linkController.clear();
      setState(() {
        _imageBytes = null;
        _imageName = '';
      });
      ref.invalidate(allAdsProvider);
      ref.invalidate(activeAdsProvider);
      _snack('Publicité créée', AppTheme.accentColor);
    } catch (e) {
      _snack('Échec: $e', AppTheme.errorColor);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggle(Ad ad) async {
    try {
      await ref.read(adsServiceProvider).setAdActive(ad.id, !ad.isActive);
      ref.invalidate(allAdsProvider);
      ref.invalidate(activeAdsProvider);
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
      ref.invalidate(allAdsProvider);
      ref.invalidate(activeAdsProvider);
      _snack('Publicité supprimée', AppTheme.accentColor);
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
    final ads = ref.watch(allAdsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(allAdsProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const GradientSliverHeader(
              title: 'Publicités',
              subtitle: 'Bannières affichées sur l\'accueil client',
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
                  'Ajouter une publicité',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm + 4),
          InkWell(
            onTap: _isSaving ? null : _pickImage,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              height: 120,
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
                          'Choisir une image (format paysage)',
                          style: AppTheme.caption,
                        ),
                        SizedBox(height: AppTheme.spaceXs),
                        Text(
                          '16:9 recommandé, max 5 Mo',
                          style: AppTheme.caption,
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          _imageBytes!,
                          fit: BoxFit.cover,
                        ),
                        const Positioned(
                          right: 8,
                          bottom: 8,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.edit_rounded,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm + 4),
          TextField(
            controller: _linkController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Lien de destination',
              hintText: 'https://...',
              prefixIcon: Icon(Icons.link_rounded),
            ),
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
            label: Text(_isSaving ? 'Publication…' : 'Publier la publicité'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildListSlivers(List<Ad> items) {
    if (items.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyAds(),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd, 0, AppTheme.spaceMd, AppTheme.spaceSm),
        sliver: SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, index) => StaggeredEntrance(
            delay: Duration(milliseconds: (index % 10) * 40),
            child: _AdCard(
              ad: items[index],
              onToggle: () => _toggle(items[index]),
              onDelete: () => _delete(items[index]),
            ),
          ),
        ),
      ),
    ];
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
          'Ajoutez une bannière pour qu\'elle s\'affiche sur l\'accueil.',
          style: AppTheme.bodySecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AdCard extends StatelessWidget {
  const _AdCard({
    required this.ad,
    required this.onToggle,
    required this.onDelete,
  });

  final Ad ad;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Image.network(
                ad.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: AppTheme.surfaceColor,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppTheme.textMutedColor),
                ),
                loadingBuilder: (context, child, progress) =>
                    progress == null
                        ? child
                        : Container(
                            height: 120,
                            color: AppTheme.surfaceColor,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(
                                strokeWidth: 2),
                          ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm + 4),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final uri = Uri.tryParse(ad.linkUrl);
                      if (uri != null) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
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
                ),
                const SizedBox(width: AppTheme.spaceSm),
                GradientBadge(
                  label: ad.isActive ? 'Active' : 'Inactive',
                  gradient:
                      ad.isActive ? AppTheme.successGradient : AppTheme.darkGradient,
                  compact: true,
                ),
                IconButton(
                  tooltip: ad.isActive ? 'Désactiver' : 'Activer',
                  icon: Icon(
                    ad.isActive
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: onToggle,
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppTheme.errorColor),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}