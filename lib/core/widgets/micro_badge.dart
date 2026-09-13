import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Badge public d'état de vérification de l'expéditeur : « Vérifié » (verts)
/// pour les profils validés, sinon « Non vérifié » (orange) pour tous les
/// autres statuts (unverified, pending, rejected). Donne aux clients un
/// repère de confiance sans dévoiler le statut interne exact.
class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key, required this.isVerified});

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final color =
        isVerified ? AppTheme.accentColor : AppTheme.warningColor;
    final icon = isVerified ? Icons.verified_rounded : Icons.gpp_bad_outlined;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            isVerified ? 'Vérifié' : 'Non vérifié',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

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

/// Badge du type d'expéditeur visible par les clients : « Voyageur ordinaire »
/// ou « Micro-Importateur ». Affiché sur les cartes d'offre, les profils
/// publics et toutes les listes où l'expéditeur apparaît.
class ShipperTypeBadge extends StatelessWidget {
  const ShipperTypeBadge({
    super.key,
    required this.isMicroImportateur,
    this.compact = false,
  });

  final bool isMicroImportateur;

  /// Compact : icône seule (utilisé dans les lignes denses).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (isMicroImportateur) return MicroImportateurBadge(compact: compact);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.work_outline_rounded,
            size: compact ? 12 : 13,
            color: AppTheme.infoColor,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            const Text(
              'Voyageur ordinaire',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.infoColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}