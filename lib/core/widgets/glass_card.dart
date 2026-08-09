import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A frosted-glass style card with a subtle gradient border.
///
/// Used on top of gradient/colored backgrounds for premium depth.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spaceMd),
    this.onTap,
    this.radius = AppTheme.radiusMd,
    this.color = Colors.white,
    this.borderOpacity = 0.06,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color color;
  final double borderOpacity;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);

    // The transparent Material sits above the decorative background so that
    // ListTile/InkWell ink splashes stay visible (never hidden behind the
    // DecoratedBox color).
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.92),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(borderOpacity)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                child: content,
              ),
      ),
    );
  }
}

/// A small gradient pill used for status labels / badges.
class GradientBadge extends StatelessWidget {
  const GradientBadge({
    super.key,
    required this.label,
    required this.gradient,
    this.icon,
    this.compact = false,
  });

  final String label;
  final LinearGradient gradient;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.last.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// A circular avatar with a brand gradient ring.
class GradientAvatar extends StatelessWidget {
  const GradientAvatar({
    super.key,
    this.initial,
    this.imageUrl,
    this.radius = 24,
    this.onTap,
  });

  final String? initial;
  final String? imageUrl;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: AppTheme.shadowSm,
      ),
      child: imageUrl != null
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                width: radius * 2,
                height: radius * 2,
                errorBuilder: (_, __, ___) => _Fallback(radius: radius, initial: initial),
              ),
            )
          : _Fallback(radius: radius, initial: initial),
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.radius, required this.initial});

  final double radius;
  final String? initial;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        (initial ?? '?').isNotEmpty
            ? (initial ?? '?')[0].toUpperCase()
            : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.85,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
