import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'feedback_launcher.dart';

/// Header extensible avec gradient pour CustomScrollView.
class GradientSliverHeader extends StatelessWidget {
  const GradientSliverHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.fontFamily,
    this.icon,
    this.trailing,
    this.gradient = AppTheme.primaryGradient,
    this.expandedHeight = 180,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final String? fontFamily;
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
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      actions: trailing != null ? [trailing!] : null,
      bottom: bottom,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: fontFamily ?? 'Oswald',
          ),
        ),
        background: _HeaderBackground(
          gradient: gradient,
          icon: icon,
          subtitle: subtitle,
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
      decoration: BoxDecoration(
        gradient: gradient,
      ),
      child: Stack(
        children: [
          // Orbe décorative
          Positioned(
            top: -40,
            right: -30,
            child: _Orb(
              size: 140,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),

          Positioned(
            bottom: -50,
            left: -20,
            child: _Orb(
              size: 120,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMd,
              0,
              AppTheme.spaceMd,
              AppTheme.spaceLg,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                reverse: true,
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (icon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(
                          height: AppTheme.spaceSm,
                        ),
                      ],
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Oswald',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.size,
    required this.color,
  });

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

/// Header compact épinglé.
///
/// Utilisé sur les écrans qui ne nécessitent pas un grand header extensible.
class CompactSliverHeader extends StatelessWidget {
  const CompactSliverHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.gradient = AppTheme.primaryGradient,
    this.expandedHeight,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final LinearGradient gradient;
  final double? expandedHeight;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: false,
      snap: false,
      elevation: 0,
      toolbarHeight: (subtitle != null && subtitle!.isNotEmpty) ? 68 : 56,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: true,
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      actions: [
        const FeedbackIconButton(),
        if (trailing != null) trailing!,
      ],
      bottom: bottom,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.none,
        background: Container(
          decoration: BoxDecoration(
            gradient: gradient,
          ),
        ),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Oswald',
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Oswald',
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
