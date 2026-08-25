import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/image_viewer.dart';
import '../../data/services/feedback_service.dart';
import '../../providers/index.dart';

/// Founder feedback inbox — every role can send feedback (screenshot + text),
/// the founder reads it here.
class FeedbackInboxScreen extends ConsumerStatefulWidget {
  const FeedbackInboxScreen({super.key});

  @override
  ConsumerState<FeedbackInboxScreen> createState() =>
      _FeedbackInboxScreenState();
}

class _FeedbackInboxScreenState extends ConsumerState<FeedbackInboxScreen> {
  @override
  Widget build(BuildContext context) {
    final feedbackAsync = ref.watch(feedbackListProvider);

    return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Feedback utilisateurs'),
          backgroundColor: AppTheme.backgroundColor,
        ),
        body: SafeArea(
          top: false,
          child: feedbackAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.accentColor),
            ),
            error: (e, _) => Center(
              child: Text('Erreur : $e',
                  style: const TextStyle(color: AppTheme.textSecondaryColor)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucun feedback pour le moment.',
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppTheme.spaceSm),
                itemBuilder: (context, index) =>
                    _FeedbackCard(item: items[index]),
              );
            },
          ),
        ));
  }
}

class _FeedbackCard extends ConsumerWidget {
  const _FeedbackCard({required this.item});

  final FeedbackItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: item.isRead ? AppTheme.surfaceMuted : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: item.isRead
              ? AppTheme.dividerColor
              : AppTheme.accentColor.withValues(alpha: .4),
        ),
      ),
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.accentColor.withValues(alpha: .15),
                child: const Icon(Icons.person_rounded,
                    color: AppTheme.accentColor, size: 20),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.senderName ?? 'Utilisateur',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Rôle : ${item.role}',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!item.isRead)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Nouveau',
                    style: TextStyle(
                        color: AppTheme.backgroundColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            item.message,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          if (item.screenshotUrl != null) ...[
            const SizedBox(height: AppTheme.spaceSm),
            GestureDetector(
              onTap: () => showFullScreenImage(
                context,
                imageUrl: item.screenshotUrl!,
                title: 'Capture du feedback',
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: Image.network(
                  item.screenshotUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: AppTheme.surfaceMuted,
                    child: const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: AppTheme.textSecondaryColor),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spaceSm),
          Row(
            children: [
              Text(
                _formatDate(item.createdAt),
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (!item.isRead)
                TextButton.icon(
                  onPressed: () async {
                    await ref.read(feedbackServiceProvider).markRead(item.id);
                    ref.invalidate(feedbackListProvider);
                    ref.invalidate(unreadFeedbackCountProvider);
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('Marquer lu'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} à $hh:$mm';
  }
}
