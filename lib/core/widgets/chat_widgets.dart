// ============================================================================
// SHARED CHAT WIDGETS (inbox badge + open helpers)
// Used by the client home, shipper dashboard and booking screens so the
// messaging entry point stays consistent with a live unread counter.
// ============================================================================

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/index.dart';
import '../../screens/chat/conversations_screen.dart';

/// Opens the inbox ([ConversationsScreen]) and invalidates the unread counts
/// when the screen is popped.
void openChatInbox(BuildContext context, WidgetRef ref) {
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const ConversationsScreen()))
      .then((_) => ref.invalidate(unreadMessageCountsProvider));
}

/// Inbox icon with a badge showing total unread chat messages for the current
/// user. Tapping opens the conversations list.
class ChatInboxBadge extends ConsumerWidget {
  const ChatInboxBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authServiceProvider).currentUserId;
    if (userId == null) {
      return IconButton(
        onPressed: () => openChatInbox(context, ref),
        icon:
            const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
      );
    }

    final total = ref.watch(unreadChatTotalProvider);

    return total.when(
      data: (count) => IconButton(
        onPressed: () => openChatInbox(context, ref),
        icon: Badge.count(
          count: count > 99 ? 99 : count,
          isLabelVisible: count > 0,
          child: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.white,
          ),
        ),
      ),
      loading: () => IconButton(
        onPressed: () => openChatInbox(context, ref),
        icon:
            const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
      ),
      error: (_, __) => IconButton(
        onPressed: () => openChatInbox(context, ref),
        icon:
            const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
      ),
    );
  }
}
