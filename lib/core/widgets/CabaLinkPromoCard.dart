import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../providers/index.dart';

/// Carte promotionnelle « Guide CabaLink » affichée sur l'écran de connexion.
///
/// Le contenu (image de fond, titre, sous-titre, CTA et padding LTRB) est
/// piloté par la configuration du slot « guide » de la table `promo_cards`
/// (modifiable par le fondateur). En cas d'absence de la ligne ou d'erreur
/// réseau, on retombe sur la [PromoCardConfig.fallback] codée en dur.
class CabaLinkPromoCard extends ConsumerWidget {
  const CabaLinkPromoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(promoCardProvider).valueOrNull ??
        PromoCardConfig.fallback;
    return PromoCardView(config: config);
  }
}

/// Rendu de la carte à partir d'une configuration. Réutilisé par l'écran
/// fondateur pour l'aperçu en direct et par la carte publique (login).
class PromoCardView extends StatelessWidget {
  const PromoCardView({super.key, required this.config, this.background});

  final PromoCardConfig config;

  /// Fond personnalisé (aperçu fondateur) : si fourni (ex. image locale), il
  /// remplace l'image réseau/asset du bucket « promos ».
  final Widget? background;

  /// Affiche l'image réseau du bucket « promos », ou l'asset par défaut.
  Widget _buildBackground(PromoCardConfig config) {
    const fallbackAsset = Image(
      image: AssetImage('assets/images/aa.png'),
      fit: BoxFit.cover,
    );
    final url = config.imageUrl;
    if (url == null || url.trim().isEmpty) return fallbackAsset;
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallbackAsset,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : Container(color: const Color(0xFF2A3270)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/Guide_cabaLink_PromoBanner',
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        height: 175,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned.fill(
                child: background ??
                    _buildBackground(config),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.45),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.65),
                      ],
                    ),
                  ),
                ),
              ),

              // Décor en arrière-plan
              Positioned(
                left: -20,
                bottom: -30,
                child: Transform.rotate(
                  angle: -0.18,
                  child: Container(
                    width: 145,
                    height: 145,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),

              // Contenu (padding LTRB configurable par le fondateur)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  config.paddingLeft.toDouble(),
                  config.paddingTop.toDouble(),
                  config.paddingRight.toDouble(),
                  config.paddingBottom.toDouble(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      config.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            config.ctaLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            size: 19,
                            color: Color(0xFF3153B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}