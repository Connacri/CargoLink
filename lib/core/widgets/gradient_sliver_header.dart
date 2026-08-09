import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A large gradient header used as the top of a CustomScrollView.
///
/// Wraps [SliverAppBar] with the brand gradient and an optional icon/subtitle
/// block. Use inside a `CustomScrollView` (true lazy layout, no nested
/// scrolling). Square bottom edge on purpose so it scrolls flush with the
/// content below (no white "bevel" artifacts from rounded corners).
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
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      expandedHeight: expandedHeight,
      automaticallyImplyLeading: true,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: trailing != null ? [trailing!] : null,
      flexibleSpace: FlexibleSpaceBar(
        background: _HeaderBackground(
          gradient: gradient,
          title: title,
          subtitle: subtitle,
          icon: icon,
        ),
      ),
      bottom: bottom,
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground({
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final LinearGradient gradient;
  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
      ),
      child: Stack(
        children: [
          // Decorative floating orbs for depth
          Positioned(
            top: -40,
            right: -30,
            child: _Orb(size: 140, color: Colors.white.withOpacity(0.08)),
          ),
          Positioned(
            bottom: -50,
            left: -20,
            child: _Orb(size: 120, color: Colors.white.withOpacity(0.06)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMd,
              kToolbarHeight + AppTheme.spaceSm,
              AppTheme.spaceMd,
              AppTheme.spaceLg,
            ),
            // Bottom-anchored and never overflows: long titles/subtitles
            // (or small custom expandedHeights) are clipped instead of
            // throwing a RenderFlex overflow.
            child: SingleChildScrollView(
              reverse: true,
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                  ],
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
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
      ),
    );
  }
}
