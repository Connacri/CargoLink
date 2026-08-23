import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../../data/models/models.dart';

/// Header d'accueil compact : une toolbar fine « CargoLink » épinglée avec
/// les actions, et la bannière publicitaire en bandeau fixe juste en dessous
/// (fini le grand header extensible — on économise l'espace d'affichage).
///
/// Taper sur la bannière ouvre le lien de la publicité dans un navigateur
/// externe (url_launcher). Utilisé par les accueils client et expéditeur
/// quand une pub active existe.
class AdSliverHeader extends StatelessWidget {
  const AdSliverHeader({
    super.key,
    required this.ad,
    required this.trailing,
    this.expandedHeight,
  });

  final Ad ad;
  final Widget? trailing;

  /// Conservé pour compatibilité d'API, ignoré (header compact).
  final double? expandedHeight;

  Future<void> _openLink(BuildContext context) async {
    final uri = Uri.tryParse(ad.linkUrl);
    if (uri == null || !uri.hasScheme) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lien invalide')),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      toolbarHeight: 56,
      backgroundColor: Colors.blue,
      automaticallyImplyLeading: true,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: trailing != null ? [trailing!] : null,
      title: const Text(
        'CargoLink',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      // Bannière publicitaire fixe sous la toolbar (épinglée avec elle).
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: GestureDetector(
          onTap: () => _openLink(context),
          child: SizedBox(
            width: double.infinity,
            height: 140,
            child: Image.network(
              ad.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.campaign_outlined,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                      ),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}