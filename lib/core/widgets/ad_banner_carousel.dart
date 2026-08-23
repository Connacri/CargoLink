import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/models.dart';
import '../theme/app_theme.dart';

/// Carrousel des bannières publicitaires actives : fait défiler toutes les
/// pubs publiées (une par page, défilement automatique toutes les 4 s,
/// points indicateurs), et ouvre le lien de la pub affichée au toucher.
class AdBannerCarousel extends StatefulWidget {
  const AdBannerCarousel({
    super.key,
    required this.ads,
    this.height = 160,
    this.autoAdvance = const Duration(seconds: 4),
  });

  /// Pubs actives à faire défiler (ordre déjà trié par le service).
  final List<Ad> ads;

  /// Hauteur fixe du bandeau.
  final double height;

  /// Durée d'affichage d'une page avant passage automatique à la suivante.
  final Duration autoAdvance;

  @override
  State<AdBannerCarousel> createState() => _AdBannerCarouselState();
}

class _AdBannerCarouselState extends State<AdBannerCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;

  bool get _autoScroll => widget.ads.length > 1;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant AdBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // La liste des pubs a changé : on repart de la première page proprement.
    if (oldWidget.ads.length != widget.ads.length && mounted) {
      setState(() => _index = 0);
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    }
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (!_autoScroll) return;
    _timer = Timer.periodic(widget.autoAdvance, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.ads.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openLink(Ad ad) async {
    final uri = Uri.tryParse(ad.linkUrl);
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
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
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.ads.length,
            onPageChanged: (i) {
              if (mounted) setState(() => _index = i);
            },
            itemBuilder: (context, i) {
              final ad = widget.ads[i];
              return GestureDetector(
                onTap: () => _openLink(ad),
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
              );
            },
          ),
          if (_autoScroll)
            Positioned(
              left: 0,
              right: 0,
              bottom: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.ads.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 14 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
