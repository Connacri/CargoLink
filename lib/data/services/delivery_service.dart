// ============================================================================
// DELIVERY SERVICE (Demande de Livraison)
// ============================================================================

import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:uuid/uuid.dart';
import '../models/delivery_models.dart';
import '../../core/config/supabase_config.dart';

class DeliveryService {
  SupabaseClient get _supabase => SupabaseConfig.client;
  final _logger = Logger();

  // ============================================================================
  // DELIVERY REQUESTS
  // ============================================================================

  /// Create a new delivery request (client only).
  Future<DeliveryRequest?> createRequest({
    required String clientId,
    required String productName,
    String? productDescription,
    List<String>? productPhotosUrl,
    required String originCountry,
    required String destinationCity,
    required double requestedWeightKg,
    required DateTime deadline,
  }) async {
    try {
      _logger.i('Creating delivery request: $productName');

      final response = await _supabase
          .from('delivery_requests')
          .insert({
            'id': const Uuid().v4(),
            'client_id': clientId,
            'product_name': productName,
            'product_description': productDescription,
            'product_photos_url': productPhotosUrl ?? [],
            'origin_country': originCountry,
            'destination_city': destinationCity,
            'requested_weight_kg': requestedWeightKg,
            'deadline': deadline.toIso8601String(),
            'status': 'open',
          })
          .select()
          .single();

      _logger.i('Delivery request created');
      return DeliveryRequest.fromJson(response);
    } catch (e) {
      _logger.e('Error creating delivery request: $e');
      rethrow;
    }
  }

  /// List open delivery requests (shipper view), optionally filtered.
  Future<List<DeliveryRequest>> getOpenRequests({
    String? destinationCity,
    String? originCountry,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('delivery_requests')
          .select()
          .eq('status', 'open')
          .gt('deadline', DateTime.now().toIso8601String());

      if (destinationCity != null && destinationCity.isNotEmpty) {
        query = query.ilike('destination_city', '%$destinationCity%');
      }
      if (originCountry != null && originCountry.isNotEmpty) {
        query = query.ilike('origin_country', '%$originCountry%');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => DeliveryRequest.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting open delivery requests: $e');
      return [];
    }
  }

  /// Get client's own delivery requests.
  Future<List<DeliveryRequest>> getMyRequests(
    String clientId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('delivery_requests')
          .select()
          .eq('client_id', clientId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => DeliveryRequest.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting my delivery requests: $e');
      return [];
    }
  }

  /// Get a single delivery request by ID.
  Future<DeliveryRequest?> getRequestById(String requestId) async {
    try {
      final response = await _supabase
          .from('delivery_requests')
          .select()
          .eq('id', requestId)
          .single();

      return DeliveryRequest.fromJson(response);
    } catch (e) {
      _logger.e('Error getting delivery request: $e');
      return null;
    }
  }

  /// Cancel a delivery request (client only).
  Future<void> cancelRequest(String requestId) async {
    try {
      await _supabase
          .from('delivery_requests')
          .update({'status': 'cancelled'})
          .eq('id', requestId);
      _logger.i('Delivery request cancelled');
    } catch (e) {
      _logger.e('Error cancelling delivery request: $e');
      rethrow;
    }
  }

  /// Update request status (used internally after payment/delivery/etc.).
  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      await _supabase
          .from('delivery_requests')
          .update({'status': status})
          .eq('id', requestId);
      _logger.i('Delivery request status updated to $status');
    } catch (e) {
      _logger.e('Error updating delivery request status: $e');
      rethrow;
    }
  }

  // ============================================================================
  // DELIVERY RESPONSES
  // ============================================================================

  /// Submit a proposal for a delivery request (shipper only).
  Future<DeliveryResponse?> submitResponse({
    required String requestId,
    required String shipperId,
    required double proposedPrice,
    required DateTime proposedDate,
    String? message,
  }) async {
    try {
      _logger.i('Submitting delivery response for request: $requestId');

      final response = await _supabase
          .from('delivery_responses')
          .insert({
            'id': const Uuid().v4(),
            'request_id': requestId,
            'shipper_id': shipperId,
            'proposed_price': proposedPrice,
            'proposed_date': proposedDate.toIso8601String(),
            'message': message,
            'status': 'pending',
          })
          .select()
          .single();

      _logger.i('Delivery response submitted');
      return DeliveryResponse.fromJson(response);
    } catch (e) {
      _logger.e('Error submitting delivery response: $e');
      rethrow;
    }
  }

  /// Get responses for a specific delivery request (client view).
  Future<List<DeliveryResponse>> getResponsesForRequest(String requestId) async {
    try {
      final response = await _supabase
          .from('delivery_responses')
          .select('*, shippers(*, users!shippers_user_id_fkey(full_name, profile_picture_url, phone))')
          .eq('request_id', requestId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => DeliveryResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting responses for request: $e');
      return [];
    }
  }

  /// Get shipper's own responses.
  Future<List<DeliveryResponse>> getMyResponses(
    String shipperId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('delivery_responses')
          .select('*, delivery_requests(*)')
          .eq('shipper_id', shipperId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => DeliveryResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting my delivery responses: $e');
      return [];
    }
  }

  /// Accept a delivery response (client only) — sets request to 'accepted',
  /// the accepted response to 'accepted', and rejects all other pending responses.
  Future<void> acceptResponse({
    required String requestId,
    required String responseId,
  }) async {
    try {
      _logger.i('Accepting response $responseId for request $requestId');

      // Accept the chosen response
      await _supabase
          .from('delivery_responses')
          .update({'status': 'accepted'})
          .eq('id', responseId);

      // Reject all other pending responses for this request
      await _supabase
          .from('delivery_responses')
          .update({'status': 'rejected'})
          .eq('request_id', requestId)
          .eq('status', 'pending')
          .neq('id', responseId);

      // Update request status
      await _supabase
          .from('delivery_requests')
          .update({'status': 'accepted'})
          .eq('id', requestId);

      _logger.i('Response accepted, other responses rejected');
    } catch (e) {
      _logger.e('Error accepting response: $e');
      rethrow;
    }
  }

  // ============================================================================
  // DELIVERY GUARANTEES (Face-to-face verification)
  // ============================================================================

  /// Create or update the guarantee record for a delivery request.
  Future<DeliveryGuarantee?> confirmFaceToFace({
    required String requestId,
    String? clientPassportUrl,
    String? clientSelfieUrl,
    String? shipperPassportUrl,
    String? shipperSelfieUrl,
    bool faceToFaceConfirmed = false,
  }) async {
    try {
      _logger.i('Confirming face-to-face for request: $requestId');

      // Upsert: create if not exists, update if exists
      final existing = await _supabase
          .from('delivery_guarantees')
          .select()
          .eq('request_id', requestId)
          .maybeSingle();

      final data = <String, dynamic>{
        'client_passport_url': clientPassportUrl,
        'client_selfie_url': clientSelfieUrl,
        'shipper_passport_url': shipperPassportUrl,
        'shipper_selfie_url': shipperSelfieUrl,
        'face_to_face_confirmed': faceToFaceConfirmed,
      };

      if (faceToFaceConfirmed) {
        data['confirmed_at'] = DateTime.now().toIso8601String();
      }

      Map<String, dynamic> response;
      if (existing != null) {
        response = await _supabase
            .from('delivery_guarantees')
            .update(data)
            .eq('request_id', requestId)
            .select()
            .single();
      } else {
        data['id'] = const Uuid().v4();
        data['request_id'] = requestId;
        response = await _supabase
            .from('delivery_guarantees')
            .insert(data)
            .select()
            .single();
      }

      _logger.i('Face-to-face guarantee recorded');
      return DeliveryGuarantee.fromJson(response);
    } catch (e) {
      _logger.e('Error confirming face-to-face: $e');
      rethrow;
    }
  }

  /// Get the guarantee record for a request.
  Future<DeliveryGuarantee?> getGuarantee(String requestId) async {
    try {
      final response = await _supabase
          .from('delivery_guarantees')
          .select()
          .eq('request_id', requestId)
          .maybeSingle();

      if (response == null) return null;
      return DeliveryGuarantee.fromJson(response);
    } catch (e) {
      _logger.e('Error getting guarantee: $e');
      return null;
    }
  }

  // ============================================================================
  // DELIVERY SUBSCRIPTIONS
  // ============================================================================

  /// Check if a user has an active delivery subscription for the given role.
  Future<DeliverySubscription?> getActiveSubscription(
    String userId,
    String role,
  ) async {
    try {
      final response = await _supabase
          .from('delivery_subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('role', role)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at', ascending: false)
          .maybeSingle();

      if (response == null) return null;
      return DeliverySubscription.fromJson(response);
    } catch (e) {
      _logger.e('Error getting subscription: $e');
      return null;
    }
  }

  /// Latest subscription for a user + role, regardless of status
  /// (active, pending or expired). Lets the UI distinguish « awaiting founder
  /// approval » from « no subscription ».
  Future<DeliverySubscription?> getMySubscription(
    String userId,
    String role,
  ) async {
    try {
      final response = await _supabase
          .from('delivery_subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('role', role)
          .inFilter('status', const ['active', 'pending'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return DeliverySubscription.fromJson(response);
    } catch (e) {
      _logger.e('Error getting my subscription: $e');
      return null;
    }
  }

  /// Purchase a delivery subscription.
  Future<DeliverySubscription?> purchaseSubscription({
    required String userId,
    required String role,
    required double price,
    required int durationDays,
  }) async {
    try {
      _logger.i('Purchasing delivery subscription for $role');
      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: durationDays));

      final response = await _supabase
          .from('delivery_subscriptions')
          .insert({
            'id': const Uuid().v4(),
            'user_id': userId,
            'role': role,
            'price': price,
            'currency': 'DZD',
            'status': 'pending',
            'starts_at': now.toIso8601String(),
            'expires_at': expiresAt.toIso8601String(),
          })
          .select()
          .single();

      _logger.i('Delivery subscription purchased');
      return DeliverySubscription.fromJson(response);
    } catch (e) {
      _logger.e('Error purchasing subscription: $e');
      rethrow;
    }
  }

  /// Get all subscriptions (for founder management).
  Future<List<DeliverySubscription>> getAllSubscriptions({
    String? status,
    String? role,
  }) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('delivery_subscriptions')
          .select('*, users!inner(full_name, email)');
      if (status != null) query = query.eq('status', status);
      if (role != null) query = query.eq('role', role);
      final response = await query.order('created_at', ascending: false);
      return (response as List).map((r) => DeliverySubscription.fromJson(r)).toList();
    } catch (e) {
      _logger.e('Error getting all subscriptions: $e');
      return [];
    }
  }

  /// Approve a subscription (set status to 'active' with proper expiry).
  Future<void> approveSubscription(String subscriptionId) async {
    try {
      final now = DateTime.now();
      final settings = await _supabase
          .from('platform_settings')
          .select('value')
          .eq('key', 'delivery_subscription_duration_days')
          .maybeSingle();
      final days = int.tryParse(settings?['value'] ?? '') ?? 30;
      await _supabase.from('delivery_subscriptions').update({
        'status': 'active',
        'starts_at': now.toIso8601String(),
        'expires_at': now.add(Duration(days: days)).toIso8601String(),
      }).eq('id', subscriptionId);
    } catch (e) {
      _logger.e('Error approving subscription: $e');
      rethrow;
    }
  }

  /// Reject/cancel a subscription.
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      await _supabase.from('delivery_subscriptions').update({
        'status': 'cancelled',
      }).eq('id', subscriptionId);
    } catch (e) {
      _logger.e('Error cancelling subscription: $e');
      rethrow;
    }
  }
}
