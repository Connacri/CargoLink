import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import 'chat_screen.dart';

/// List of the current user's chat threads with a live unread badge counter and
/// the last-message preview. Tapping a thread opens the [ChatScreen].
class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authServiceProvider).currentUserId;
    final stream =
        ref.watch(conversationsStreamProvider.select((s) => s.value));
    final unreadMap =
        ref.watch(unreadMessageCountsProvider.select((s) => s.value ?? {}));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: userId == null
          ? const Center(child: Text('Connectez-vous pour voir vos messages'))
          : stream == null
              ? const Center(child: CircularProgressIndicator())
              : stream.isEmpty
                  ? _EmptyState()
                  : ListView.separated(
                      itemCount: stream.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final conversation = stream[index];
                        final unread = unreadMap[conversation.id] ?? 0;
                        return _ConversationTile(
                          conversation: conversation,
                          participant:
                              _counterpart(context, conversation, userId),
                          unread: unread,
                          onTap: () => _open(context, conversation),
                        );
                      },
                    ),
    );
  }

  User? _counterpart(BuildContext context, Conversation c, String myId) {
    if (c.shipperUserId == myId) return c.clientUser;
    return c.shipperUser;
  }

  void _open(BuildContext context, Conversation c) {
    final myId = ref.read(authServiceProvider).currentUserId;
    final isShipper = c.shipperUserId == myId;
    final counterpart = isShipper ? c.clientUser : c.shipperUser;

    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => ChatScreen(
            counterpartUserId: counterpart?.id ??
                (isShipper ? c.clientUserId : c.shipperUserId),
            counterpartName: counterpart?.fullName ?? 'Contact',
            counterpartAvatarUrl: counterpart?.profilePictureUrl,
            bookingId: c.bookingId,
          ),
        ))
        .then((_) => ref.invalidate(unreadMessageCountsProvider));
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.participant,
    required this.unread,
    required this.onTap,
  });

  final Conversation conversation;
  final User? participant;
  final int unread;
  final VoidCallback onTap;

  String get _name => participant?.fullName ?? 'Contact';
  String? get _avatar => participant?.profilePictureUrl;

  String get _preview {
    final last = conversation.lastMessage?.trim();
    if (last == null || last.isEmpty) {
      return 'Aucun message';
    }
    // Prefix "Vous : " when the last message was sent by the current user is
    // handled by the parent via flags; here we keep a plain preview.
    return last;
  }

  String get _time {
    final t = conversation.lastMessageAt?.toLocal();
    if (t == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sameDay = DateTime(t.year, t.month, t.day) == today;
    if (sameDay) {
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: participant != null
        ? UserAvatar(
            userId: participant!.id,
            initial: _name,
            imageUrl: _avatar,
            radius: 24,
          )
        : GradientAvatar(initial: _name, imageUrl: _avatar, radius: 24),
      title: Text(
        _name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        _preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: unread > 0
              ? AppTheme.textPrimaryColor
              : AppTheme.textSecondaryColor,
          fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_time, style: AppTheme.caption),
          const SizedBox(height: 4),
          if (unread > 0)
            CircleAvatar(
              radius: 10,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          else
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMutedColor),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: AppTheme.textMutedColor),
          SizedBox(height: AppTheme.spaceMd),
          Text('Aucune conversation', style: AppTheme.h3),
          SizedBox(height: AppTheme.spaceSm),
          Text(
            'Vos échanges avec expéditeurs et clients apparaîtront ici.',
            style: AppTheme.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
