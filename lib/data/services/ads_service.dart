import '../models/models.dart';
import '../../core/config/supabase_config.dart';
import 'package:logger/logger.dart';

// ============================================================================
// ADS SERVICE (bannières publicitaires sur l'accueil client)
// ============================================================================

class AdsService {
  final _logger = Logger();

  /// Public listing for the client home: only active ads, newest first.
  Future<List<Ad>> getActiveAds({int limit = 10}) async {
    try {
      final response = await SupabaseConfig.client
          .from('ads')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((item) => Ad.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting active ads: $e');
      return [];
    }
  }

  /// Admin / founder listing: every ad (active or not), newest first.
  Future<List<Ad>> getAllAds({int limit = 100, int offset = 0}) async {
    try {
      final response = await SupabaseConfig.client
          .from('ads')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (response as List)
          .map((item) => Ad.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting all ads: $e');
      return [];
    }
  }

  /// Create an ad (admin / super_admin only, enforced by RLS).
  Future<Ad> createAd({
    required String imageUrl,
    required String linkUrl,
  }) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      final response = await SupabaseConfig.client
          .from('ads')
          .insert({
            'image_url': imageUrl,
            'link_url': linkUrl,
            'created_by': userId,
          })
          .select()
          .single();

      _logger.i('Ad created: ${response['id']}');
      return Ad.fromJson(response);
    } catch (e) {
      _logger.e('Error creating ad: $e');
      rethrow;
    }
  }

  /// Toggle an ad's active flag (admin / super_admin only, enforced by RLS).
  Future<void> setAdActive(String adId, bool active) async {
    try {
      await SupabaseConfig.client
          .from('ads')
          .update({'is_active': active})
          .eq('id', adId);
      _logger.i('Ad $adId active=$active');
    } catch (e) {
      _logger.e('Error updating ad: $e');
      rethrow;
    }
  }

  /// Delete an ad (admin / super_admin only, enforced by RLS).
  Future<void> deleteAd(String adId) async {
    try {
      await SupabaseConfig.client.from('ads').delete().eq('id', adId);
      _logger.i('Ad deleted: $adId');
    } catch (e) {
      _logger.e('Error deleting ad: $e');
      rethrow;
    }
  }
}