import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'animations.dart';
import 'glass_card.dart';

/// Carte « Portefeuille » commune aux écrans d'accueil : gros montant
/// principal (profit net ou solde), pastille secondaire (dus / en attente),
/// et un appui n'importe où sur la carte pour ouvrir les détails.
class WalletCard extends StatelessWidget {
  final String title;
  final String mainLabel;
  final String mainValue;
  final String? badgeLabel;
  final bool badgePositive;
  final VoidCallback? onTap;

  const WalletCard({
    super.key,
    required this.title,
    required this.mainLabel,
    required this.mainValue,
    this.badgeLabel,
    this.badgePositive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceSm,
        AppTheme.spaceMd,
        0,
      ),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AnimatedIconDot(
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(child: Text(title, style: AppTheme.h3)),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textMutedColor,
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Text(mainLabel, style: AppTheme.caption),
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              mainValue,
              style: AppTheme.h1.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 30,
                height: 1.1,
              ),
            ),
            if (badgeLabel != null) ...[
              const SizedBox(height: AppTheme.spaceSm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (badgePositive
                          ? AppTheme.accentColor
                          : AppTheme.warningColor)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: (badgePositive
                            ? AppTheme.accentColor
                            : AppTheme.warningColor)
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      badgePositive
                          ? Icons.check_circle_outline_rounded
                          : Icons.schedule_rounded,
                      size: 14,
                      color: badgePositive
                          ? AppTheme.accentColor
                          : AppTheme.warningColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: badgePositive
                            ? AppTheme.accentColor
                            : AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
