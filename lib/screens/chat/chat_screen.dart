import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';

/// Full-screen messaging thread between a shipper and a client.
///
/// A conversation is resolved (or created) on the first frame from one side's
/// user id and the counterpart's user id; if a booking is passed it becomes
/// the conversation context. Messages stream in live over Supabase Realtime so
/// both parties always see the latest state.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    Key? key,
    required this.counterpartUserId,
    required this.counterpartName,
    this.counterpartAvatarUrl,
    this.bookingId,
  }) : super(key: key);

  /// Supabase `users.id` of the person the current user is talking to.
  final String counterpartUserId;
  final String counterpartName;
  final String? counterpartAvatarUrl;
  final String? bookingId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  bool _loading = true;
  String? _error;
  Conversation? _conversation;
  List<ChatMessage> _history = [];
  StreamSubscription<List<ChatMessage>>? _subscription;

  String? get _myUserId => ref.read(authServiceProvider).currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final myId = _myUserId;
    if (myId == null) {
      setState(() {
        _loading = false;
        _error = 'Vous devez être connecté pour discuter';
      });
      return;
    }

    // The current user always messages the counterpart; the shipper is whoever
    // is on the shipper side. When I open a booking thread I know my role from
    // my profile, so resolve roles here.
    final isShipper =
        ref.read(currentUserProvider).valueOrNull?.role == 'shipper';

    try {
      final conversation =
          await ref.read(chatServiceProvider).getOrCreateConversation(
                shipperUserId: isShipper ? myId : widget.counterpartUserId,
                clientUserId: isShipper ? widget.counterpartUserId : myId,
                bookingId: widget.bookingId,
              );

      if (!mounted || conversation == null) return;

      final history =
          await ref.read(chatServiceProvider).getMessages(conversation.id);

      if (!mounted) return;

      setState(() {
        _conversation = conversation;
        _history = history;
        _loading = false;
      });

      // Mark incoming messages as delivered then read + subscribe to live
      // updates, so the sender sees the WhatsApp-style tick progression.
      await ref
          .read(chatServiceProvider)
          .markConversationDelivered(
              conversationId: conversation.id, userId: myId);
      await ref
          .read(chatServiceProvider)
          .markConversationRead(conversationId: conversation.id, userId: myId);
      ref.invalidate(unreadMessageCountsProvider);

      _subscription = ref
          .read(chatServiceProvider)
          .listenToMessages(conversation.id)
          .listen((messages) {
        if (!mounted) return;
        final hadLast = _history.isNotEmpty;
        setState(() => _history = _mergeMessages(_history, messages));
        _maybeScrollToBottom(force: !hadLast);
        ref.read(chatServiceProvider).markConversationDelivered(
            conversationId: conversation.id, userId: myId);
        ref.read(chatServiceProvider).markConversationRead(
            conversationId: conversation.id, userId: myId);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger la conversation: $e';
      });
    }
  }

  /// Merge never-removing messages (dedupe by id, keep order).
  List<ChatMessage> _mergeMessages(
      List<ChatMessage> current, List<ChatMessage> incoming) {
    final seen = <String>{};
    final merged = <ChatMessage>[];
    for (final m in incoming) {
      if (seen.add(m.id)) merged.add(m);
    }
    for (final m in current) {
      if (seen.add(m.id)) merged.add(m);
    }
    merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return merged;
  }

  void _maybeScrollToBottom({bool force = false}) {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (force) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } else {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final body = _controller.text;
    final conversationId = _conversation?.id;
    final myId = _myUserId;
    if (body.trim().isEmpty || conversationId == null || myId == null) return;
    if (_sending) return;

    setState(() => _sending = true);
    try {
      final sent = await ref.read(chatServiceProvider).sendMessage(
            conversationId: conversationId,
            senderId: myId,
            body: body,
          );

      if (sent != null) {
        _controller.clear();
        setState(() {
          _history = [..._history, sent]
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        });
        _maybeScrollToBottom(force: true);
      }

      // Heads-up for the receiver via an in-app notification + FCM push.
      final senderName =
          ref.read(currentUserProvider).valueOrNull?.fullName ?? 'Contact';
      await ref.read(chatServiceProvider).notifyMessage(
            recipientUserId: widget.counterpartUserId,
            senderName: senderName,
            body: body,
            bookingId: widget.bookingId,
            conversationId: conversationId,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de l\'envoi: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            GradientAvatar(
              initial: widget.counterpartName,
              imageUrl: widget.counterpartAvatarUrl,
              radius: 18,
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.counterpartName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppTheme.textMutedColor),
              const SizedBox(height: AppTheme.spaceMd),
              Text(_error!, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined,
                size: 56, color: AppTheme.textMutedColor),
            const SizedBox(height: AppTheme.spaceMd),
            const Text('Aucun message pour le moment', style: AppTheme.h3),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              'Envoyez le premier message à ${widget.counterpartName}',
              style: AppTheme.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final myId = _myUserId;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final message = _history[index];
        return _MessageBubble(
          message: message,
          isMine: message.senderId == myId,
        );
      },
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd, AppTheme.spaceSm,
            AppTheme.spaceSm, AppTheme.spaceSm),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          boxShadow: AppTheme.shadowSm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Écrire un message…',
                  isDense: true,
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: AppTheme.spaceSm),
            SizedBox(
              height: 48,
              child: IconButton.filled(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                tooltip: 'Envoyer',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
  });

  final ChatMessage message;
  final bool isMine;

  String get _time {
    final t = message.createdAt.toLocal();
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// WhatsApp-style tick for my own messages:
  /// single check = sent, double check = delivered, blue double check = read.
  Widget? _buildStatus() {
    if (!isMine) return null;
    if (message.isRead) {
      return const Icon(
        Icons.done_all_rounded,
        size: 13,
        color: AppTheme.infoColor,
      );
    }
    if (message.isDelivered) {
      return const Icon(
        Icons.done_all_rounded,
        size: 13,
        color: Colors.white70,
      );
    }
    return const Icon(
      Icons.done_rounded,
      size: 13,
      color: Colors.white54,
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _buildStatus();
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMd,
          vertical: 10,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isMine ? AppTheme.primaryColor : AppTheme.surfaceMuted,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppTheme.radiusMd),
            topRight: const Radius.circular(AppTheme.radiusMd),
            bottomLeft: Radius.circular(isMine ? AppTheme.radiusMd : 4),
            bottomRight: Radius.circular(isMine ? 4 : AppTheme.radiusMd),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.body,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                color: isMine ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMine
                        ? Colors.white.withOpacity(0.8)
                        : AppTheme.textMutedColor,
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(width: 4),
                  status,
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
