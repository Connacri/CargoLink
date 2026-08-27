import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../theme/app_theme.dart';

/// Pastille de statut d'acceptation de la commande (visible côté client),
/// mise à jour en temps réel (la tuile se reconstruit via le provider realtime).
///
/// - avant acceptation expéditeur : « Commandé en attente d'acceptation »
/// - acceptée (kanSeeTracking)     : « Commande acceptée — attente de collecte »
/// - refusée avec motif            : « Refusée : <motif> »
class BookingAcceptanceChip extends StatelessWidget {
  final Booking booking;

  const BookingAcceptanceChip({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final refused = booking.refusalReason != null &&
        booking.refusalReason!.trim().isNotEmpty;
    final Color color;
    final IconData icon;
    final String label;

    if (refused) {
      color = AppTheme.errorColor;
      icon = Icons.cancel_rounded;
      label = 'Refusée : ${booking.refusalReason!.trim()}';
    } else if (booking.canSeeTracking) {
      color = AppTheme.accentColor;
      icon = Icons.verified_rounded;
      label = 'Commande acceptée — attente de collecte';
    } else {
      color = AppTheme.warningColor;
      icon = Icons.schedule_rounded;
      label = booking.status == 'cancelled'
          ? 'Commande annulée'
          : 'Commande en attente d\'acceptation';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceSm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
