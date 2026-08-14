import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../../core/config/supabase_config.dart';
import 'package:logger/logger.dart';

// ============================================================================
// CHAT SERVICE (Messages expéditeur ↔ client)
// ============================================================================

/// Backing service for the in-app messaging between a shipper and a client.
///
/// A conversation is owned by two participants (`shipper_user_id` and
/// `client_user_id`, both Supabase `users.id`) and may optionally be tied to a
/// `bookings.id` so both sides get booking context. Messages are stored with a
/// `read_at` timestamp; the RLS policies only expose each side's own threads.
class ChatService {
  SupabaseClient get _supabase => SupabaseConfig.client;
  final _logger = Logger();

  /// Number of messages to fetch per page when back-filling a thread.
  static const pageSize = 30;

  /// Embed the shipper's and client's `users` profile rows (aliased) on top of
  /// the plain conversation columns.
  static const _embedProfiles = '*, '
      'shipper:users!conversations_shipper_user_id_fkey('
      'id, email, phone, full_name, profile_picture_url, role, is_active, '
      'created_at, updated_at), '
      'client:users!conversations_client_user_id_fkey('
      'id, email, phone, full_name, profile_picture_url, role, is_active, '
      'created_at, updated_at)';

  /// Resolve an existing conversation between two participants (optionally for
  /// a booking) or create one. Returns the thread plus the resolved
  /// counterpart so screens can render names without an extra lookup.
  Future<Conversation?> getOrCreateConversation({
    required String shipperUserId,
    required String clientUserId,
    String? bookingId,
  }) async {
    try {
      var query = _supabase.from('conversations').select(_embedProfiles).or(
            'and(shipper_user_id.eq.$shipperUserId,client_user_id.eq.$clientUserId),'
            'and(shipper_user_id.eq.$clientUserId,client_user_id.eq.$shipperUserId)',
          );

      if (bookingId != null && bookingId.isNotEmpty) {
        query = query.eq('booking_id', bookingId);
      }

      final existing = await query.maybeSingle();

      if (existing != null) {
        return _parseConversation(existing);
      }

      final created = await _supabase
          .from('conversations')
          .insert({
            'id': const Uuid().v4(),
            'booking_id':
                (bookingId == null || bookingId.isEmpty) ? null : bookingId,
            'shipper_user_id': shipperUserId,
            'client_user_id': clientUserId,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select(_embedProfiles)
          .single();

      _logger.i('Conversation created: ${created['id']}');
      return _parseConversation(created);
    } catch (e) {
      _logger.e('Error getting or creating conversation: $e');
      rethrow;
    }
  }

  Conversation _parseConversation(Map<String, dynamic> json) {
    return Conversation.fromJson({
      ...json,
      'shippers':
          json['shipper'] is Map<String, dynamic> ? json['shipper'] : null,
      'clients': json['client'] is Map<String, dynamic> ? json['client'] : null,
    });
  }

  /// Recent conversations for a user (newest message first) with resolved
  /// counterpart names/avatars so the list screen renders directly.
  Future<List<Conversation>> getMyConversations(String userId,
      {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('conversations')
          .select(_embedProfiles)
          .or('shipper_user_id.eq.$userId,client_user_id.eq.$userId')
          .order('updated_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((item) => _parseConversation(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting conversations for $userId: $e');
      return [];
    }
  }

  /// Latest messages of a conversation, ascending (oldest → newest) for direct
  /// rendering in the thread.
  Future<List<ChatMessage>> getMessages(String conversationId,
      {int limit = ChatService.pageSize}) async {
    try {
      // RLS mirrors the row set; ordering desc then reversing lets us
      // back-fill the most recent page without offset drift on a live feed.
      final response = await _supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      _logger.e('Error getting messages for $conversationId: $e');
      return [];
    }
  }

  /// Send a message and sync the conversation preview in one round trip.
  Future<ChatMessage?> sendMessage({
    required String conversationId,
    required String senderId,
    required String body,
  }) async {
    try {
      final trimmed = body.trim();
      if (trimmed.isEmpty) return null;

      final now = DateTime.now();
      final message = await _supabase
          .from('messages')
          .insert({
            'id': const Uuid().v4(),
            'conversation_id': conversationId,
            'sender_id': senderId,
            'body': trimmed,
            'created_at': now.toIso8601String(),
          })
          .select()
          .single();

      await _supabase.from('conversations').update({
        'last_message': trimmed,
        'last_message_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).eq('id', conversationId);

      return ChatMessage.fromJson(message);
    } catch (e) {
      _logger.e('Error sending message: $e');
      rethrow;
    }
  }

  /// Mark every incoming (not self) message as read and return how many were
  /// just marked, so callers can invalidate unread badges.
  Future<int> markConversationRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .update({
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .isFilter('read_at', null)
          .select();
      return (response as List).length;
    } catch (e) {
      _logger.e('Error marking conversation read: $e');
      return 0;
    }
  }

  /// Number of unread incoming messages per conversation for the current user.
  Future<Map<String, int>> getUnreadCounts(
      String userId, List<String> conversationIds) async {
    if (conversationIds.isEmpty) return {};
    try {
      final response = await _supabase
          .from('messages')
          .select('conversation_id')
          .inFilter('conversation_id', conversationIds)
          .neq('sender_id', userId)
          .isFilter('read_at', null);
      final counts = <String, int>{};
      for (final row in response as List) {
        final id = (row as Map<String, dynamic>)['conversation_id'] as String;
        counts[id] = (counts[id] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      _logger.e('Error computing unread counts: $e');
      return {};
    }
  }

  /// Live stream of a conversation's messages, ordered chronologically.
  Stream<List<ChatMessage>> listenToMessages(String conversationId) {
    try {
      return _supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('conversation_id', conversationId)
          .order('created_at')
          .map((data) => (data as List)
              .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
              .toList());
    } catch (e) {
      _logger.e('Error listening to messages: $e');
      return Stream.value([]);
    }
  }

  /// Live stream of the user's conversations (for list updates + badges).
  /// RLS already limits the row set to conversations the user participates in;
  /// the extra local filter keeps the widget from rebuilding on other threads.
  Stream<List<Conversation>> listenToMyConversations(String userId) {
    try {
      return _supabase
          .from('conversations')
          .stream(primaryKey: ['id'])
          .order('updated_at')
          .map((data) => (data as List)
              .where((row) =>
                  (row as Map<String, dynamic>)['shipper_user_id'] == userId ||
                  row['client_user_id'] == userId)
              .map(
                  (item) => Conversation.fromJson(item as Map<String, dynamic>))
              .toList());
    } catch (e) {
      _logger.e('Error listening to conversations: $e');
      return Stream.value([]);
    }
  }

  /// Create an in-app notification for the recipient when a chat message is
  /// sent. Best-effort: never blocks sending the message.
  Future<void> notifyMessage({
    required String recipientUserId,
    required String counterpartName,
    required String body,
    String? bookingId,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'id': const Uuid().v4(),
        'user_id': recipientUserId,
        'type': 'chat_message',
        'title': 'Nouveau message · $counterpartName',
        'message': body.length > 140 ? '${body.substring(0, 140)}…' : body,
        'related_booking_id':
            (bookingId == null || bookingId.isEmpty) ? null : bookingId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.e('Error notifying message recipient: $e');
    }
  }
}
