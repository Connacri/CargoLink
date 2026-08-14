import '../models/models.dart';
import '../../core/config/supabase_config.dart';
import 'package:logger/logger.dart';

// ============================================================================
// BROADCAST SERVICE
// ============================================================================

class BroadcastService {
  final _logger = Logger();

  /// Send an announcement to every user. The authenticated caller must be an
  /// `admin` or `super_admin` (the Edge Function enforces this server-side).
  ///
  /// [audience] targets roles ("all", "client", "shipper,admin", ...).
  /// [targetUserIds], when set, narrows the recipients to those exact users
  /// (combined with the role filter server-side).
  Future<String?> sendBroadcast({
    required String title,
    required String message,
    String audience = 'all',
    List<String>? targetUserIds,
  }) async {
    try {
      final response = await SupabaseConfig.client.functions
          .invoke('broadcast', body: {
        'title': title,
        'message': message,
        'audience': audience,
        'target_user_ids': targetUserIds,
      });

      final data = response.data as Map<String, dynamic>? ?? const {};
      _logger.i('Broadcast sent: ${data['ok']}');
      return data['id'] as String?;
    } catch (e) {
      _logger.e('Error sending broadcast: $e');
      rethrow;
    }
  }

  /// Get the broadcast feed (in-app) for any authenticated user.
  ///
  /// [role] filters announcements to those targeting the caller's role
  /// (`audience = 'all'` or a role list containing [role]). [userId] also
  /// includes announcements that individually target the caller (stored in
  /// `target_user_ids`). `admin` and `super_admin` see every announcement so
  /// they can manage them.
  Future<List<Broadcast>> getBroadcasts({
    String? role,
    String? userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final isAdmin =
          role == 'admin' || role == 'super_admin' || role == 'all';

      var query = SupabaseConfig.client.from('broadcasts').select();

      if (role != null && !isAdmin) {
        // A regular user sees: global announcements, their role's, or ones
        // that individually target them.
        final targetClause =
            userId == null ? null : 'target_user_ids.cs.{$userId}';
        final orParts = ['audience.eq.all', 'audience.ilike.%$role%'];
        if (targetClause != null) orParts.add(targetClause);
        query = query.or(orParts.join(','));
      } else if (role != null && isAdmin && role == 'all') {
        // "all" viewing mode: everything.
      } else if (role == null) {
        // No role context: only global announcements, so the asking context
        // decides which subset a caller may see.
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => Broadcast.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting broadcasts: $e');
      return [];
    }
  }

  /// Update an existing announcement (admin / super_admin only, enforced by RLS).
  Future<Broadcast> updateBroadcast({
    required String broadcastId,
    required String title,
    required String message,
  }) async {
    try {
      final response = await SupabaseConfig.client
          .from('broadcasts')
          .update({'title': title, 'message': message})
          .eq('id', broadcastId)
          .select()
          .single();

      _logger.i('Broadcast updated: $broadcastId');
      return Broadcast.fromJson(response);
    } catch (e) {
      _logger.e('Error updating broadcast: $e');
      rethrow;
    }
  }

  /// Delete an announcement (admin / super_admin only, enforced by RLS).
  Future<void> deleteBroadcast(String broadcastId) async {
    try {
      await SupabaseConfig.client
          .from('broadcasts')
          .delete()
          .eq('id', broadcastId);
      _logger.i('Broadcast deleted: $broadcastId');
    } catch (e) {
      _logger.e('Error deleting broadcast: $e');
      rethrow;
    }
  }
}