// ============================================================================
// BADGE / BANDEAU D'ABONNEMENT
// ============================================================================
//
// Affiché en haut des onglets utilisateur (client & expéditeur) :
//  - abonnement actif (approuvé) : badge « abonné » + type du pack + jours
//    restants ;
//  - demande en attente : bandeau « validation par le fondateur » ;
//  - pas d'abonnement : appel à l'action « S'abonner » (choix d'un pack).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/delivery_models.dart';
import 'subscription_pack_sheet.dart';

class SubscriptionBanner extends ConsumerWidget {
  const SubscriptionBanner({
    super.key,
    required this.userId,
    required this.role,
  });

  final String userId;
  final String role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(
        deliverySubscriptionProvider((userId: userId, role: role)));

    return subAsync.when(
      data: (sub) {
        if (sub == null) {
          return _GradientCard(
            colors: [Colors.amber.shade600, Colors.orange.shade500],
            icon: Icons.card_membership_rounded,
            title: 'Pas d\'abonnement actif',
            subtitle:
                'S\'abonner pour répondre aux demandes de livraison',
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 16),
            onTap: () => _subscribe(context, ref),
          );
        }
        if (sub.status == 'pending') {
          return _GradientCard(
            colors: [Colors.amber.shade100, Colors.orange.shade100],
            icon: Icons.hourglass_top_rounded,
            iconColor: Colors.amber.shade700,
            title: 'Validation en attente',
            subtitle: 'Le fondateur approuvera votre abonnement après '
                'réception du paiement.',
            titleColor: Colors.amber.shade800,
            subtitleColor: Colors.amber.shade700,
            trailing: const Icon(Icons.swap_horiz_rounded,
                color: Colors.amber, size: 18),
            onTap: () => _subscribe(context, ref, currentSubscription: sub),
          );
        }
        if (sub.isActive) {
          final pack = sub.packName?.isNotEmpty == true
              ? sub.packName!
              : 'Abonnement';
          final days = sub.daysRemaining;
          return _GradientCard(
            colors: [
              const Color(0xFF16A34A).withValues(alpha: 0.14),
              const Color(0xFF16A34A).withValues(alpha: 0.08),
            ],
            icon: Icons.verified_rounded,
            iconColor: const Color(0xFF16A34A),
            title: 'Abonné · $pack',
            subtitle: '$days jour${days > 1 ? 's' : ''} restant'
                '${days > 1 ? 's' : ''} — renouveler avant expiration',
            titleColor: const Color(0xFF15803D),
            subtitleColor: const Color(0xFF16A34A),
            trailing: const Icon(Icons.swap_horiz_rounded,
                color: Color(0xFF16A34A), size: 18),
            onTap: () => _subscribe(context, ref, currentSubscription: sub),
          );
        }
        // Expiré / annulé
        return _GradientCard(
          colors: [Colors.red.shade50, Colors.orange.shade50],
          icon: Icons.event_busy_rounded,
          iconColor: AppTheme.errorColor,
          title: 'Abonnement expiré',
          subtitle: 'Renouvelez pour continuer à répondre aux demandes',
          trailing: const Icon(Icons.arrow_forward_ios_rounded,
              color: AppTheme.errorColor, size: 16),
          onTap: () => _subscribe(context, ref),
          titleColor: AppTheme.errorColor,
          subtitleColor: AppTheme.errorColor.withValues(alpha: 0.8),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _subscribe(BuildContext context, WidgetRef ref,
      {DeliverySubscription? currentSubscription}) {
    ref.invalidate(subscriptionPacksProvider(role));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubscriptionPackSheet(
        userId: userId,
        role: role,
        currentSubscription: currentSubscription,
      ),
    );
  }
}

class _GradientCard extends StatelessWidget {
  const _GradientCard({
    required this.colors,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor = Colors.white,
    this.titleColor = Colors.white,
    this.subtitleColor = Colors.white70,
    this.trailing,
    this.onTap,
  });

  final List<Color> colors;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceSm,
        AppTheme.spaceMd,
        AppTheme.spaceXs,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.shadowMd,
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 26),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppTheme.spaceSm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
