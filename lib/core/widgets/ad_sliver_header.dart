import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../../data/models/models.dart';

/// Header d'accueil affichant une bannière publicitaire paysage à la place du
/// header dégradé classique, tout en conservant l'AppBar épinglée (le titre
/// « CargoLink » + actions restent visibles quand on scrolle).
///
/// Taper sur la bannière ouvre le lien de la publicité dans un navigateur
/// externe (url_launcher). Utilisé par l'accueil client quand une pub active
/// existe.
class AdSliverHeader extends StatelessWidget {
  const AdSliverHeader({
    super.key,
    required this.ad,
    required this.trailing,
    this.expandedHeight = 200,
  });

  final Ad ad;
  final Widget? trailing;
  final double expandedHeight;

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
      backgroundColor: Colors.blue,
      expandedHeight: expandedHeight,
      automaticallyImplyLeading: true,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: trailing != null ? [trailing!] : null,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        title: const Text(
          'CargoLink',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        background: GestureDetector(
          onTap: () => _openLink(context),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
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
                loadingBuilder: (context, child, progress) =>
                    progress == null
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
              // Léger voile pour la lisibilité du titre replié.
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}