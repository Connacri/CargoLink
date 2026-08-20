import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../../core/widgets/micro_badge.dart';

/// Public profile of a shipper, shown when tapping their avatar on an offer.
class ShipperPublicProfileScreen extends ConsumerWidget {
  final String shipperId;

  const ShipperPublicProfileScreen({super.key, required this.shipperId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipper = ref.watch(shipperByIdProvider(shipperId));

    return shipper.when(
      data: (data) {
        if (data == null) {
          return const Scaffold(
            body: Center(child: Text('Expéditeur introuvable')),
          );
        }
        return _ShipperProfileBody(shipper: data);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Erreur: $e'))),
    );
  }
}

class _ShipperProfileBody extends ConsumerWidget {
  final Shipper shipper;

  const _ShipperProfileBody({required this.shipper});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(shipperReviewsProvider(shipper.id));
    final shipments = ref.watch(
      shipperShipmentsProvider(
        (shipperId: shipper.id, limit: 20, offset: 0),
      ),
    );
    final user = shipper.user;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            GradientSliverHeader(
              title: user?.fullName ?? 'Expéditeur',
              subtitle: '${user?.email ?? ''}  •  ★ ${shipper.ratingDisplay}',
              icon: Icons.verified_user,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMd,
                  AppTheme.spaceMd,
                  AppTheme.spaceMd,
                  0,
                ),
                child: GlassCard(
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GradientAvatar(
                            initial: user?.fullName,
                            imageUrl: user?.profilePictureUrl,
                            radius: 32,
                          ),
                          const SizedBox(width: AppTheme.spaceMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user?.fullName ?? 'Expéditeur',
                                        style: AppTheme.h3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (shipper.isVerified) ...[
                                      const SizedBox(width: 6),
                                      const VerifiedBadge(),
                                    ],
                                    if (shipper.isMicroImportateur) ...[
                                      const SizedBox(width: 6),
                                      const MicroImportateurBadge(),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    StarRating(rating: shipper.rating),
                                    const SizedBox(width: 6),
                                    Text(
                                      shipper.ratingDisplay,
                                      style: AppTheme.caption,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (shipper.totalShipments > 0) ...[
                        const SizedBox(height: AppTheme.spaceMd),
                        _MetaRow(
                          icon: Icons.flight_takeoff_outlined,
                          label: '${shipper.totalShipments} offres publiées',
                        ),
                      ],
                      if (shipper.isMicroImportateur) ...[
                        const SizedBox(height: AppTheme.spaceXs),
                        const _MetaRow(
                          icon: Icons.storefront_rounded,
                          label:
                              'Micro-importateur : carte de commerce vérifiée',
                        ),
                      ],
                      ..._contactTiles(user),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.spaceMd,
                  AppTheme.spaceLg,
                  AppTheme.spaceMd,
                  AppTheme.spaceSm,
                ),
                child: Text('Offres actives', style: AppTheme.h2),
              ),
            ),
            shipments.when(
              data: (items) {
                final active = items.where((s) => s.isActive).toList();
                if (active.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spaceMd),
                      child: Text(
                        'Aucune offre active en ce moment.',
                        style: AppTheme.bodySecondary,
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceMd,
                    0,
                    AppTheme.spaceMd,
                    AppTheme.spaceLg,
                  ),
                  sliver: SliverList.builder(
                    itemCount: active.length,
                    itemBuilder: (context, index) => _PublicShipmentCard(
                      shipment: active[index],
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spaceMd),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, s) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.spaceMd,
                  AppTheme.spaceSm,
                  AppTheme.spaceMd,
                  AppTheme.spaceSm,
                ),
                child: Text('Avis des clients', style: AppTheme.h2),
              ),
            ),
            reviews.when(
              data: (items) {
                if (items.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spaceMd),
                      child: Text(
                        'Aucun avis pour le moment.',
                        style: AppTheme.bodySecondary,
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceMd,
                    0,
                    AppTheme.spaceMd,
                    AppTheme.spaceXxl,
                  ),
                  sliver: SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) => _ReviewCard(
                      review: items[index],
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spaceMd),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, s) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _contactTiles(User? user) {
    if (user == null) return const [];
    final tiles = <Widget>[];
    void add(String label, String? value, IconData icon) {
      if (value != null && value.isNotEmpty) {
        tiles.add(_MetaRow(icon: icon, label: '$label: $value'));
      }
    }

    add('WhatsApp', user.whatsapp, Icons.chat_rounded);
    add('Télégram', user.telegram, Icons.send_rounded);
    add('Facebook', user.facebook, Icons.facebook_rounded);
    add('Instagram', user.instagram, Icons.camera_alt_outlined);
    add('TikTok', user.tiktok, Icons.music_note_rounded);
    return tiles;
  }
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 13, color: AppTheme.primaryColor),
          SizedBox(width: 3),
          Text(
            'Vérifié',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spaceXs),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.textMutedColor),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: AppTheme.caption)),
        ],
      ),
    );
  }
}

class _PublicShipmentCard extends StatelessWidget {
  final Shipment shipment;

  const _PublicShipmentCard({required this.shipment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${shipment.originCountry} → ${shipment.destinationCity}',
                    style: AppTheme.h3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                GradientBadge(
                  label:
                      '${shipment.pricePerKg.toStringAsFixed(0)} ${AppConstants.defaultCurrency}/kg',
                  gradient: AppTheme.primaryGradient,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            if (shipment.flightNumber != null) ...[
              Row(
                children: [
                  const Icon(
                    Icons.confirmation_number_rounded,
                    size: 15,
                    color: AppTheme.textMutedColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      shipment.airline != null
                          ? '${shipment.airline} · Vol ${shipment.flightNumber}'
                          : 'Vol ${shipment.flightNumber}',
                      style: AppTheme.caption,
                    ),
                  ),
                ],
              ),
            ],
            Row(
              children: [
                const Icon(
                  Icons.monitor_weight_outlined,
                  size: 15,
                  color: AppTheme.textMutedColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '${shipment.remainingWeightKg.toStringAsFixed(1)} kg restants',
                  style: AppTheme.caption,
                ),
                const Spacer(),
                const Icon(
                  Icons.event_rounded,
                  size: 15,
                  color: AppTheme.textMutedColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Arrivée ${shipment.arrivalDate.day}/${shipment.arrivalDate.month}',
                  style: AppTheme.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StarRating(rating: review.rating.toDouble(), size: 16),
                const Spacer(),
                Text(
                  '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                  style: AppTheme.caption,
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceSm),
              Text(review.comment!, style: AppTheme.bodySecondary),
            ],
          ],
        ),
      ),
    );
  }
}
