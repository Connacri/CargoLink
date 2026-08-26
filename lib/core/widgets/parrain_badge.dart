import 'package:flutter/material.dart';

/// Petit badge doré « Parrain » à placer en overlay sur un avatar.
/// Affiché uniquement quand [visible] est true (utilisateur parrain actif).
class ParrainBadge extends StatelessWidget {
  final bool visible;
  final double size;

  const ParrainBadge({super.key, this.visible = false, this.size = 16});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B), // Amber 500
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(Icons.star_rounded, size: size * 0.65, color: Colors.white),
    );
  }
}

/// Wrapper autour d'un [Stack] qui place le badge parrain en bas à droite
/// d'un avatar. [child] est l'avatar, [showBadge] contrôle l'affichage.
class ParrainBadgeOverlay extends StatelessWidget {
  final Widget child;
  final bool showBadge;
  final double badgeOffset;

  const ParrainBadgeOverlay({
    super.key,
    required this.child,
    this.showBadge = false,
    this.badgeOffset = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBadge) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -badgeOffset,
          bottom: -badgeOffset,
          child: ParrainBadge(visible: true),
        ),
      ],
    );
  }
}
