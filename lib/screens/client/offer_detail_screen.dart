import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/micro_badge.dart';
import '../../core/widgets/offer_ticket_card.dart';
import '../../core/widgets/ui_kit.dart';
import '../../providers/index.dart';

/// Détail complet d'une offre de vol : billet visuel + informations
/// expéditeur. La réservation se fait UNIQUEMENT via le bouton « Réserver ».
class OfferDetailScreen extends ConsumerWidget {
  const OfferDetailScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(platformSettingsProvider).valueOrNull;
    final commissionPercent =
        settings?.commissionPercent ?? AppConstants.platformCommissionPercent;
    final shipmentAsync = ref.watch(shipmentByIdProvider(shipmentId));

    return Scaffold(
        appBar: AppBar(
          title: const Text('Détail du vol'),
          actions: const [FeedbackIconButton()],
        ),
        body: SafeArea(
          top: false,
          child: shipmentAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur : $e')),
            data: (shipment) {
              if (shipment == null) {
                return const Center(
                    child: Text('Offre introuvable ou expirée.'));
              }
              final shipper = shipment.shipper;
              final clientPrice =
                  shipment.pricePerKg * (1 + commissionPercent / 100);

              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(shipmentByIdProvider(shipmentId)),
                child: ListView(
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  children: [
                    Center(
                      child: OfferTicketCard(
                        shipperName:
                            shipper?.user?.fullName ?? 'Expéditeur vérifié',
                        shipperPhone: shipper?.user?.phone,
                        origin: shipment.originCountry,
                        destination:
                            shipment.arrivalAirport ?? shipment.destinationCity,
                        airline: shipment.airline,
                        flightNumber: shipment.flightNumber,
                        departureDate: shipment.departureDate,
                        arrivalDate: shipment.arrivalDate,
                        pricePerKg: clientPrice,
                        availableKg: shipment.remainingWeightKg,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceLg),

                    // ---- Disponibilité ----
                    GlassCard(
                      padding: const EdgeInsets.all(AppTheme.spaceMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                shipment.isActive && !shipment.isFull
                                    ? Icons.check_circle_rounded
                                    : Icons.do_not_disturb_on_rounded,
                                color: shipment.isActive && !shipment.isFull
                                    ? AppTheme.accentColor
                                    : AppTheme.errorColor,
                                size: 20,
                              ),
                              const SizedBox(width: AppTheme.spaceSm),
                              Expanded(
                                child: Text(
                                  shipment.isActive && !shipment.isFull
                                      ? 'Places disponibles — ${shipment.remainingWeightKg.toStringAsFixed(1)} kg restants sur ${shipment.availableWeightKg.toStringAsFixed(0)} kg'
                                      : 'Offre complète ou arrivée passée',
                                  style: AppTheme.label,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceSm),
                          LinearProgressIndicator(
                            value: (shipment.utilizationPercent / 100)
                                .clamp(0.0, 1.0),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                            backgroundColor: AppTheme.surfaceMuted,
                            valueColor: AlwaysStoppedAnimation(
                              shipment.isActive && !shipment.isFull
                                  ? AppTheme.primaryColor
                                  : AppTheme.textMutedColor,
                            ),
                          ),
                          if (shipment.description != null &&
                              shipment.description!.isNotEmpty) ...[
                            const SizedBox(height: AppTheme.spaceMd),
                            const Text('Description', style: AppTheme.h3),
                            const SizedBox(height: 4),
                            Text(shipment.description!,
                                style: AppTheme.bodySecondary),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),

                    // ---- Expéditeur ----
                    if (shipper != null)
                      GlassCard(
                        padding: const EdgeInsets.all(AppTheme.spaceMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Votre expéditeur', style: AppTheme.h3),
                            const SizedBox(height: AppTheme.spaceSm),
                            Row(
                              children: [
                                GradientAvatar(
                                  initial:
                                      shipper.user?.fullName.isNotEmpty == true
                                          ? shipper.user!.fullName[0]
                                          : '?',
                                  imageUrl: shipper.user?.profilePictureUrl,
                                  radius: 22,
                                ),
                                const SizedBox(width: AppTheme.spaceMd),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              shipper.user?.fullName ??
                                                  'Expéditeur',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTheme.label,
                                            ),
                                          ),
                                          if (shipper.isVerified) ...[
                                            const SizedBox(width: 6),
                                            const Icon(Icons.verified_rounded,
                                                size: 16,
                                                color: AppTheme.accentColor),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded,
                                              size: 15, color: Colors.amber),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${shipper.rating.toStringAsFixed(1)}/5'
                                            '${shipper.totalShipments > 0 ? ' • ${shipper.totalShipments} vols' : ''}',
                                            style: AppTheme.caption,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (shipper.isMicroImportateur)
                                  const ShipperTypeBadge(
                                      isMicroImportateur: true),
                              ],
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: AppTheme.spaceXl),

                    // ---- CTA : SEULE voie vers la réservation ----
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: shipment.isActive && !shipment.isFull
                            ? () => Navigator.of(context).pushNamed(
                                  '/booking-wizard',
                                  arguments: shipment.id,
                                )
                            : null,
                        icon: const Icon(Icons.shopping_bag_rounded, size: 20),
                        label: Text(
                          shipment.isActive && !shipment.isFull
                              ? 'Réserver — '
                                  '${clientPrice.toStringAsFixed(0)} '
                                  '${AppConstants.defaultCurrency}/kg'
                              : 'Indisponible',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXl),
                  ],
                ),
              );
            },
          ),
        ));
  }
}
