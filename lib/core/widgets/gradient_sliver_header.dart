import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GradientSliverHeader extends StatelessWidget {
  const GradientSliverHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.gradient = AppTheme.primaryGradient,
    this.expandedHeight = 180,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final LinearGradient gradient;
  final double expandedHeight;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final hasBack = Navigator.of(context).canPop();

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      expandedHeight: expandedHeight,
      automaticallyImplyLeading: true,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: trailing != null ? [trailing!] : null,
      bottom: bottom,
      // Applique le gradient au background au lieu de Colors.blue
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: FlexibleSpaceBar(
          collapseMode: CollapseMode.parallax,
          titlePadding: EdgeInsetsDirectional.only(
            start: hasBack ? 72 : AppTheme.spaceMd,
            bottom: AppTheme.spaceMd,
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          background: _HeaderBackground(
            gradient: gradient,
            icon: icon,
            subtitle: subtitle,
          ),
        ),
      ),
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground({
    required this.gradient,
    required this.subtitle,
    required this.icon,
  });

  final LinearGradient gradient;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          // Decorative floating orbs for depth - mieux positionnés
          Positioned(
            top: -60,
            right: -40,
            child: _Orb(size: 160, color: Colors.white.withOpacity(0.1)),
          ),
          Positioned(
            bottom: -80,
            left: -50,
            child: _Orb(size: 140, color: Colors.white.withOpacity(0.08)),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: _Orb(size: 80, color: Colors.white.withOpacity(0.05)),
          ),
          // Contenu principal avec meilleur layout
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMd,
              vertical: AppTheme.spaceLg,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône avec meilleur style
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.24),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                ],
                // Sous-titre avec gestion correcte du texte long
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                      height: 1.4,
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

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
    );
  }
}