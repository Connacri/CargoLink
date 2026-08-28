// ============================================================================
// CHOIX D'ABONNEMENT — feuille partagée (client & expéditeur)
// ============================================================================
//
// Affiche les packs d'abonnement actifs configurés par le fondateur (source
// unique). Quand l'utilisateur clique sur un pack, une demande d'abonnement
// (status 'pending') est créée ; le fondateur l'approuve après réception du
// paiement.
//
// Si [currentSubscription] est fourni, l'utilisateur peut changer/upgrade son
// abonnement en sélectionnant un nouveau pack.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/delivery_models.dart';

class SubscriptionPackSheet extends ConsumerStatefulWidget {
  const SubscriptionPackSheet({
    super.key,
    required this.userId,
    required this.role,
    this.currentSubscription,
  });

  final String userId;
  final String role;
  final DeliverySubscription? currentSubscription;

  @override
  ConsumerState<SubscriptionPackSheet> createState() =>
      _SubscriptionPackSheetState();
}

class _SubscriptionPackSheetState extends ConsumerState<SubscriptionPackSheet> {
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    // Normalize role: default to 'client' or 'shipper'
    final raw = widget.role.toLowerCase().trim();
    if (raw == 'client') {
      _selectedRole = 'client';
    } else {
      _selectedRole = 'shipper';
    }
  }

  bool get _isAdminOrFounder {
    final raw = widget.role.toLowerCase().trim();
    return raw == 'admin' || raw == 'super_admin';
  }

  @override
  Widget build(BuildContext context) {
    final packsAsync = ref.watch(subscriptionPacksProvider(_selectedRole));

    final hasActive = widget.currentSubscription != null &&
        widget.currentSubscription!.status == 'active' &&
        widget.currentSubscription!.isActive;
    final hasPending = widget.currentSubscription != null &&
        widget.currentSubscription!.status == 'pending';

    return DraggableScrollableSheet(
      initialChildSize: hasActive || hasPending ? 0.85 : 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondaryColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.card_membership_rounded,
                        color: Colors.amber.shade700, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasActive
                          ? 'Changer d\'abonnement'
                          : hasPending
                              ? 'Changer de pack en attente'
                              : 'Choisissez votre abonnement',
                      style: AppTheme.h3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                hasActive
                    ? 'Votre abonnement actuel est actif. Vous pouvez '
                        'sélectionner un nouveau pack — le fondateur '
                        'devra le valider.'
                    : hasPending
                        ? 'Vous avez une demande en attente. Vous pouvez '
                            'en créer une nouvelle avec un autre pack.'
                        : 'Sélectionnez un pack. Le fondateur validera votre demande '
                            'après réception du paiement — vous recevrez le badge '
                            '« abonné » une fois approuvé.',
                style: AppTheme.caption,
              ),
              if (_isAdminOrFounder) ...[
                const SizedBox(height: 14),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'shipper',
                      label: Text('Expéditeur'),
                      icon: Icon(Icons.local_shipping_rounded),
                    ),
                    ButtonSegment(
                      value: 'client',
                      label: Text('Client'),
                      icon: Icon(Icons.person_rounded),
                    ),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (set) {
                    setState(() => _selectedRole = set.first);
                  },
                ),
              ],
              const SizedBox(height: 16),
              // ── Current subscription info ──
              if (hasActive || hasPending) ...[
                _CurrentSubscriptionCard(
                  subscription: widget.currentSubscription!,
                  role: _selectedRole,
                ),
                const SizedBox(height: 16),
              ],
              // ── Available packs ──
              packsAsync.when(
                data: (packs) {
                  if (packs.isEmpty) {
                    return _EmptyPackMessage(role: _selectedRole);
                  }
                  return Column(
                    children: [
                      for (final pack in packs)
                        _PackTile(
                          key: ValueKey(pack.id),
                          name: pack.name,
                          durationDays: pack.durationDays,
                          price: pack.price,
                          currency: pack.currency,
                          roleIcon: _selectedRole == 'shipper'
                              ? Icons.local_shipping_rounded
                              : Icons.person_rounded,
                          onTap: () => _purchase(
                            pack.durationDays,
                            pack.price,
                            packName: pack.name,
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => _ErrorCard(
                  message: 'Impossible de charger les packs : $err',
                  onRetry: () =>
                      ref.invalidate(subscriptionPacksProvider(_selectedRole)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _purchase(
    int durationDays,
    double price, {
    String? packName,
  }) async {
    try {
      await ref.read(deliveryServiceProvider).purchaseSubscription(
            userId: widget.userId,
            role: _selectedRole,
            price: price,
            durationDays: durationDays,
            packName: packName,
          );
      ref.invalidate(deliverySubscriptionProvider(
          (userId: widget.userId, role: _selectedRole)));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Demande envoyée — validation par le fondateur en attente',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }
}

/// Carte d'un pack (nom, durée, prix) cliquable.
class _PackTile extends StatelessWidget {
  const _PackTile({
    super.key,
    required this.name,
    required this.durationDays,
    required this.price,
    required this.currency,
    required this.roleIcon,
    required this.onTap,
  });

  final String name;
  final int durationDays;
  final double price;
  final String currency;
  final IconData roleIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade600, Colors.orange.shade500],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.shadowMd,
            ),
            child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(roleIcon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            color: Colors.white70, size: 15),
                        const SizedBox(width: 4),
                        Text(
                          '$durationDays jours',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12.5),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.payments_rounded,
                            color: Colors.white70, size: 15),
                        const SizedBox(width: 4),
                        Text(
                          '${price.toStringAsFixed(0)} $currency',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// Carte d'information sur l'abonnement en cours.
class _CurrentSubscriptionCard extends StatelessWidget {
  const _CurrentSubscriptionCard({
    required this.subscription,
    required this.role,
  });

  final DeliverySubscription subscription;
  final String role;

  @override
  Widget build(BuildContext context) {
    final isActive = subscription.status == 'active' && subscription.isActive;
    final isPending = subscription.status == 'pending';
    final daysLeft = subscription.daysRemaining;
    final expiryDate = subscription.expiresAt;

    final statusColor = isActive
        ? Colors.green
        : isPending
            ? Colors.amber
            : Colors.red;
    final statusText = isActive
        ? 'Actif'
        : isPending
            ? 'En attente'
            : 'Expiré';
    final statusIcon = isActive
        ? Icons.verified_rounded
        : isPending
            ? Icons.hourglass_top_rounded
            : Icons.cancel_rounded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subscription.packName ??
                      'Pack ${role == 'shipper' ? 'Expéditeur' : 'Client'}',
                  style: AppTheme.h3.copyWith(fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 4),
              Text(
                isActive
                    ? '$daysLeft jour${daysLeft > 1 ? 's' : ''} restant${daysLeft > 1 ? 's' : ''}'
                    : isPending
                        ? 'Durée : ${subscription.durationDays} jours'
                        : 'Expiré',
                style: AppTheme.caption.copyWith(fontSize: 12),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.event_rounded, size: 14, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 4),
              Text(
                'Exp. ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
                style: AppTheme.caption.copyWith(fontSize: 12),
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 6),
            Text(
              '${subscription.price.toStringAsFixed(0)} ${subscription.currency}',
              style: AppTheme.caption.copyWith(
                  fontSize: 11, color: AppTheme.textSecondaryColor),
            ),
          ],
        ],
      ),
    );
  }
}

/// Repli si aucun pack n'est configuré : prix/durée depuis les réglages.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.red.shade400, size: 28),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.caption.copyWith(color: Colors.red.shade700),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

/// Message affiché quand aucun pack actif n'est configuré pour ce rôle.
class _EmptyPackMessage extends StatelessWidget {
  final String role;
  const _EmptyPackMessage({required this.role});

  @override
  Widget build(BuildContext context) {
    final roleLabel = role == 'client' ? 'clients' : 'expéditeurs';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.card_membership_rounded,
              color: AppTheme.textMutedColor, size: 32),
          const SizedBox(height: 10),
          Text(
            'Aucun pack actif pour les $roleLabel',
            textAlign: TextAlign.center,
            style: AppTheme.h3.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Le fondateur doit activer ou créer un pack d\'abonnement dans « Abonnements ».',
            textAlign: TextAlign.center,
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }
}
