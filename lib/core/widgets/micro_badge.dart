import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Badge "Micro-Importateur" affiché sur les cartes d'offre, profils publics,
/// le tableau de bord fondateur et les détails de commande, pour distinguer
/// les expéditeurs disposant d'une carte de micro-importateur.
class MicroImportateurBadge extends StatelessWidget {
  const MicroImportateurBadge({
    super.key,
    this.compact = false,
    this.onTap,
  });

  /// Compact : icône seule (utilisé dans les lignes denses).
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.storefront_rounded,
            size: compact ? 12 : 13,
            color: AppTheme.accentColor,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            const Text(
              'Micro-Importateur',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentColor,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}