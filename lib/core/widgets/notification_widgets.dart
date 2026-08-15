// ============================================================================
// SHARED NOTIFICATION WIDGETS (bell badge + sheet)
// Used by the client home and the shipper dashboard so the "new order" and
// "booking confirmed" notifications surface with an unread counter.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../theme/app_theme.dart';

/// Bell icon with a badge showing the number of unread notifications for the
/// current signed-in user.
class UnreadNotificationBadge extends ConsumerWidget {
  const UnreadNotificationBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.read(authServiceProvider).currentUserId;
    if (userId == null) {
      return const Icon(Icons.notifications_outlined, color: Colors.white);
    }

    final notifs = ref.watch(notificationStreamProvider(userId));

    return notifs.when(
      data: (list) {
        final count = list.where((n) => !n.isRead).length;
        if (count == 0) {
          return const Icon(Icons.notifications_outlined,
              color: Colors.white);
        }
        return Badge.count(
          count: count > 99 ? 99 : count,
          child: const Icon(Icons.notifications_outlined, color: Colors.white),
        );
      },
      loading: () =>
          const Icon(Icons.notifications_outlined, color: Colors.white),
      error: (error, stack) =>
          const Icon(Icons.notifications_outlined, color: Colors.white),
    );
  }
}

/// Bottom-sheet friendly list of announcements + personal notifications, with
/// "mark all as read". Tapping a notification marks it read and, when
/// [onBookingTap] is provided, navigates to the related booking detail.
class NotificationsSheet extends ConsumerWidget {
  const NotificationsSheet({super.key, this.onBookingTap});

  final void Function(String bookingId)? onBookingTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final userId = authService.currentUserId;

    if (userId == null) {
      return const Center(child: Text('Utilisateur non identifié'));
    }

    final notifications = ref.watch(notificationStreamProvider(userId));
    final broadcasts = ref.watch(broadcastsProvider);

    return notifications.when(
      data: (notifs) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(notificationServiceProvider)
                          .markAllAsRead(userId);
                      ref.invalidate(notificationStreamProvider(userId));
                    },
                    child: const Text('Marquer tout comme lu'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _BroadcastFeedSection(broadcasts: broadcasts),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Mes notifications',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (notifs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Aucune notification')),
                    )
                  else
                    for (final notif in notifs)
                      ListTile(
                        title: Text(notif.title),
                        subtitle: Text(notif.message),
                        trailing: !notif.isRead
                            ? const CircleAvatar(
                                radius: 4,
                                backgroundColor: AppTheme.primaryColor,
                              )
                            : null,
                        onTap: () async {
                          await ref
                              .read(notificationServiceProvider)
                              .markAsRead(notif.id);
                          ref.invalidate(notificationStreamProvider(userId));
                          final bookingId = notif.relatedBookingId;
                          if (onBookingTap != null &&
                              bookingId != null &&
                              bookingId.isNotEmpty) {
                            onBookingTap!(bookingId);
                          }
                        },
                      ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Notifications indisponibles — réessayez dans un instant.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Announcements targeted at the current role, shown at the top of the
/// notifications sheet.
class _BroadcastFeedSection extends ConsumerWidget {
  const _BroadcastFeedSection({required this.broadcasts});

  final AsyncValue<List<Broadcast>> broadcasts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return broadcasts.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.campaign_rounded,
                      size: 18, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Annonces',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            for (final broadcast in items.take(5))
              ListTile(
                leading: const Icon(Icons.campaign_rounded,
                    color: AppTheme.primaryColor),
                title: Text(broadcast.title),
                subtitle: Text(
                  broadcast.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: false,
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}