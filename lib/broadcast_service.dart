import 'models.dart';
import 'supabase_config.dart';
import 'package:logger/logger.dart';

// ============================================================================
// BROADCAST SERVICE
// ============================================================================

class BroadcastService {
  final _logger = Logger();

  /// Send an announcement to every user. The authenticated caller must be an
  /// `admin` or `super_admin` (the Edge Function enforces this server-side).
  Future<String?> sendBroadcast({
    required String title,
    required String message,
    String audience = 'all',
  }) async {
    try {
      final response = await SupabaseConfig.client.functions
          .invoke('broadcast', body: {
        'title': title,
        'message': message,
        'audience': audience,
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
  Future<List<Broadcast>> getBroadcasts({int limit = 50, int offset = 0}) async {
    try {
      final response = await SupabaseConfig.client
          .from('broadcasts')
          .select()
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
}