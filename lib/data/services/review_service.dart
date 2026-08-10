import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../../core/config/supabase_config.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

// ============================================================================
// REVIEW SERVICE (Notation étoile client -> expéditeur)
// ============================================================================

class ReviewService {
  SupabaseClient get _supabase => SupabaseConfig.client;
  final _logger = Logger();

  /// Submit a review for a delivered booking. The rating is persisted and the
  /// shipper's aggregate rating is recomputed by a DB trigger.
  Future<Review?> submitReview({
    required String bookingId,
    required String shipmentId,
    required String shipperId,
    required String clientId,
    required int rating,
    String? comment,
  }) async {
    try {
      if (rating < 1 || rating > 5) {
        throw Exception('La note doit être entre 1 et 5 étoiles');
      }
      final response = await _supabase
          .from('reviews')
          .insert({
            'id': const Uuid().v4(),
            'booking_id': bookingId,
            'shipment_id': shipmentId,
            'shipper_id': shipperId,
            'client_id': clientId,
            'rating': rating,
            'comment': (comment == null || comment.trim().isEmpty)
                ? null
                : comment.trim(),
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      _logger.i('Review submitted: $bookingId rating=$rating');
      return Review.fromJson(response);
    } catch (e) {
      _logger.e('Error submitting review: $e');
      rethrow;
    }
  }

  /// Whether the given booking has already been reviewed by the client.
  Future<bool> hasReviewed(String bookingId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('id')
          .eq('booking_id', bookingId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      _logger.e('Error checking review: $e');
      return false;
    }
  }

  /// All reviews for a shipper, newest first.
  Future<List<Review>> getShipperReviews({
    required String shipperId,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('*, users!reviews_client_id_fkey(full_name, profile_picture_url)')
          .eq('shipper_id', shipperId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => Review.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting shipper reviews: $e');
      return [];
    }
  }
}
