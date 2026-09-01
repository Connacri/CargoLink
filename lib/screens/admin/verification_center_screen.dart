// ============================================================================
// VERIFICATION CENTER (Fondateur) — pending shipper KYC with full-screen photos
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/utils/profile_navigation.dart';
import '../../core/widgets/ui_kit.dart';

// ============================================================================
// PAGINATED PROVIDER (local to this screen)
// ============================================================================

final verificationCenterPagerProvider = StateNotifierProvider<
    PaginatedListNotifier<Shipper>, PaginatedList<Shipper>>((ref) {
  return createPaginatedNotifier(
    (limit, offset) => ref
        .read(shipperServiceProvider)
        .getPendingShippers(limit: limit, offset: offset),
    pageSize: 10,
  );
});

/// Full-screen verification center where the founder reviews KYC documents
/// (passport + live photo) at full size before validating or rejecting.
class VerificationCenterScreen extends ConsumerWidget {
  const VerificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pager = ref.watch(verificationCenterPagerProvider);

    // Temps réel : un nouveau dossier KYC rafraîchit la liste en direct.
    ref.listen(
      tableChangesProvider(('shippers', null, null)),
      (previous, next) {
        if (!next.hasValue) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(verificationCenterPagerProvider.notifier).refresh();
          ref.invalidate(pendingShippersCountProvider);
        });
      },
    );

    return Scaffold(
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(verificationCenterPagerProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CompactSliverHeader(
                title: 'Vérification des expéditeurs',
                subtitle: 'Dossiers en attente — photos en grand écran',
                icon: Icons.fact_check_outlined,
                trailing: IconButton(
                  tooltip: 'Recharger',
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => ref
                      .read(verificationCenterPagerProvider.notifier)
                      .refresh(),
                ),
              ),
              PagedSliverList<Shipper>(
                paginatedList: pager,
                padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd,
                    AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceXxl),
                emptyState: const _EmptyVerifications(),
                itemBuilder: (context, shipper, index) => StaggeredEntrance(
                  delay: Duration(milliseconds: (index % 10) * 40),
                  child: _VerificationCard(shipper: shipper),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyVerifications extends StatelessWidget {
  const _EmptyVerifications();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_user_outlined,
            size: 56, color: AppTheme.textMutedColor),
        SizedBox(height: AppTheme.spaceMd),
        Text('Aucun dossier en attente', style: AppTheme.h3),
        SizedBox(height: AppTheme.spaceXs),
        Text('Les nouveaux dossiers KYC apparaîtront ici.',
            style: AppTheme.caption),
      ],
    );
  }
}

class _VerificationCard extends ConsumerWidget {
  final Shipper shipper;

  const _VerificationCard({required this.shipper});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminId = ref.read(authServiceProvider).currentUserId ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GradientAvatar(
                  initial: shipper.user?.fullName ?? '?',
                  imageUrl: shipper.user?.profilePictureUrl,
                  radius: 20,
                  onTap: shipper.user != null
                      ? () => openUserProfile(context, ref, shipper.user!.id)
                      : null,
                ),
                const SizedBox(width: AppTheme.spaceSm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shipper.user?.fullName ?? 'Utilisateur',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Passport: ${shipper.passportNumber}',
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm + 4),
            if (shipper.passportPhotoUrl.isNotEmpty ||
                shipper.livePhotoUrl.isNotEmpty ||
                (shipper.microCardPhotoUrl?.isNotEmpty ?? false)) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (shipper.passportPhotoUrl.isNotEmpty)
                    _photoTile(context, 'Passeport', shipper.passportPhotoUrl),
                  if (shipper.livePhotoUrl.isNotEmpty) ...[
                    if (shipper.passportPhotoUrl.isNotEmpty)
                      const SizedBox(width: AppTheme.spaceSm),
                    _photoTile(context, 'Selfie', shipper.livePhotoUrl),
                  ],
                  if (shipper.microCardPhotoUrl?.isNotEmpty ?? false) ...[
                    const SizedBox(width: AppTheme.spaceSm),
                    _photoTile(
                        context, 'Carte micro', shipper.microCardPhotoUrl!),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Touchez une photo pour l\'agrandir',
                style: AppTheme.caption.copyWith(fontSize: 11),
              ),
            ],
            const SizedBox(height: AppTheme.spaceSm + 4),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _verify(context, ref, adminId),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Vérifier'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(context, ref, adminId),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rejeter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.red,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Small square (1:1) tappable preview that opens the full-screen zoom
  /// viewer. Must be placed inside a [Row].
  Widget _photoTile(BuildContext context, String label, String url) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spaceXs),
          GestureDetector(
            onTap: () =>
                showFullScreenImage(context, imageUrl: url, title: label),
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.surfaceMuted,
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: AppTheme.textMutedColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verify(
      BuildContext context, WidgetRef ref, String adminId) async {
    try {
      await ref.read(shipperServiceProvider).verifyShipper(
            shipperId: shipper.id,
            adminId: adminId,
          );
      ref.read(verificationCenterPagerProvider.notifier).refresh();
      ref.invalidate(pendingShippersCountProvider);
      ref.invalidate(currentShipperProvider);
      ref.invalidate(shipperByIdProvider(shipper.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expéditeur vérifié'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) showAppErrorDialog(context, message: 'Erreur: $e');
    }
  }

  Future<void> _reject(
      BuildContext context, WidgetRef ref, String adminId) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter le dossier'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Motif du rejet'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, reasonController.text.trim()),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await ref.read(shipperServiceProvider).rejectShipper(
            shipperId: shipper.id,
            adminId: adminId,
            rejectionReason: reason,
          );
      ref.read(verificationCenterPagerProvider.notifier).refresh();
      ref.invalidate(pendingShippersCountProvider);
    } catch (e) {
      if (context.mounted) showAppErrorDialog(context, message: 'Erreur: $e');
    }
  }
}
