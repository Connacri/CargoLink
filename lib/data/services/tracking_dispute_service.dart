import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../../core/config/supabase_config.dart';
import './booking_payment_service.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

// ============================================================================
// TRACKING SERVICE
// ============================================================================

class TrackingService {
  SupabaseClient get _supabase => SupabaseConfig.client;
  final _logger = Logger();

  /// Add tracking update
  Future<ShipmentTracking?> addTrackingUpdate({
    required String bookingId,
    required String status,
    double? latitude,
    double? longitude,
    String? notes,
    String? location,
  }) async {
    try {
      _logger.i('Adding tracking update for booking: $bookingId');

      final response = await _supabase
          .from('shipment_tracking')
          .insert({
            'id': const Uuid().v4(),
            'booking_id': bookingId,
            'latitude': latitude,
            'longitude': longitude,
            'status': status,
            'timestamp': DateTime.now().toIso8601String(),
            'notes': notes,
            'location': location,
          })
          .select()
          .single();

      _logger.i('Tracking update added');
      return ShipmentTracking.fromJson(response);
    } catch (e) {
      _logger.e('Error adding tracking update: $e');
      rethrow;
    }
  }

  /// Get tracking history for booking
  Future<List<ShipmentTracking>> getTrackingHistory(String bookingId) async {
    try {
      final response = await _supabase
          .from('shipment_tracking')
          .select()
          .eq('booking_id', bookingId)
          .order('timestamp', ascending: true);

      return (response as List)
          .map(
              (item) => ShipmentTracking.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting tracking history: $e');
      return [];
    }
  }

  /// Get latest tracking update
  Future<ShipmentTracking?> getLatestTracking(String bookingId) async {
    try {
      final response = await _supabase
          .from('shipment_tracking')
          .select()
          .eq('booking_id', bookingId)
          .order('timestamp', ascending: false)
          .limit(1)
          .single();

      return ShipmentTracking.fromJson(response);
    } catch (e) {
      _logger.e('Error getting latest tracking: $e');
      return null;
    }
  }

  /// Listen to real-time tracking updates
  Stream<List<ShipmentTracking>> listenToTrackingUpdates(String bookingId) {
    try {
      return _supabase
          .from('shipment_tracking')
          .stream(primaryKey: ['id'])
          .eq('booking_id', bookingId)
          .order('timestamp')
          .map((data) => (data as List)
              .map((item) =>
                  ShipmentTracking.fromJson(item as Map<String, dynamic>))
              .toList());
    } catch (e) {
      _logger.e('Error listening to tracking updates: $e');
      return Stream.value([]);
    }
  }

  /// Calculate distance between two coordinates
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p / 2) +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p / 2)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R; R = 6371 km, result in meters
  }

  /// Get estimated delivery time (placeholder)
  Duration estimateDeliveryTime(
    double? currentLat,
    double? currentLon,
    double destinationLat,
    double destinationLon,
  ) {
    if (currentLat == null || currentLon == null) {
      return Duration(hours: 24); // Default 24 hours
    }

    final distanceMeters = calculateDistance(
      currentLat,
      currentLon,
      destinationLat,
      destinationLon,
    );

    // Assume average speed of 100 km/h
    final hours = (distanceMeters / 1000) / 100;
    return Duration(hours: hours.ceil());
  }
}

// ============================================================================
// DISPUTE SERVICE
// ============================================================================

class DisputeService {
  SupabaseClient get _supabase => SupabaseConfig.client;
  final _logger = Logger();

  /// Create a dispute
  Future<Dispute?> createDispute({
    required String bookingId,
    required String reportedByUserId,
    required String type,
    required String description,
    List<String>? evidencePhotosUrl,
  }) async {
    try {
      _logger.i('Creating dispute for booking: $bookingId');

      final response = await _supabase
          .from('disputes')
          .insert({
            'id': const Uuid().v4(),
            'booking_id': bookingId,
            'reported_by_user_id': reportedByUserId,
            'type': type,
            'description': description,
            'evidence_photos_url': evidencePhotosUrl ?? [],
            'status': 'open',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select(
              '*, bookings(*, shipments(*, shippers(*, users!shippers_user_id_fkey(*))), users!bookings_client_id_fkey(*))')
          .single();

      _logger.i('Dispute created successfully');
      return Dispute.fromJson(response);
    } catch (e) {
      _logger.e('Error creating dispute: $e');
      rethrow;
    }
  }

  /// Get dispute by ID
  Future<Dispute?> getDisputeById(String disputeId) async {
    try {
      final response = await _supabase
          .from('disputes')
          .select(
              '*, bookings(*, shipments(*, shippers(*, users!shippers_user_id_fkey(*))), users!bookings_client_id_fkey(*))')
          .eq('id', disputeId)
          .single();

      return Dispute.fromJson(response);
    } catch (e) {
      _logger.e('Error getting dispute: $e');
      return null;
    }
  }

  /// Get disputes for booking
  Future<List<Dispute>> getBookingDisputes(String bookingId) async {
    try {
      final response = await _supabase
          .from('disputes')
          .select(
              '*, bookings(*, shipments(*, shippers(*, users!shippers_user_id_fkey(*))), users!bookings_client_id_fkey(*))')
          .eq('booking_id', bookingId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Dispute.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting booking disputes: $e');
      return [];
    }
  }

  /// Get disputes reported by a specific user (admin drill-down).
  Future<List<Dispute>> getUserDisputes(String userId) async {
    try {
      final response = await _supabase
          .from('disputes')
          .select(
              '*, bookings(*, shipments(*, shippers(*, users!shippers_user_id_fkey(*))), users!bookings_client_id_fkey(*))')
          .eq('reported_by_user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Dispute.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting user disputes: $e');
      return [];
    }
  }

  /// Get all open disputes (admin)
  Future<List<Dispute>> getOpenDisputes(
      {int limit = 50, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('disputes')
          .select(
              '*, bookings(*, shipments(*, shippers(*, users!shippers_user_id_fkey(*))), users!bookings_client_id_fkey(*))')
          .eq('status', 'open')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => Dispute.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting open disputes: $e');
      return [];
    }
  }

  /// Get all disputes (admin / super_admin only, enforced by RLS).
  Future<List<Dispute>> getAllDisputes(
      {int limit = 200, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('disputes')
          .select(
              '*, bookings(*, shipments(*, shippers(*, users!shippers_user_id_fkey(*))), users!bookings_client_id_fkey(*))')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => Dispute.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting all disputes: $e');
      return [];
    }
  }

  /// Update dispute status (admin)
  Future<Dispute?> updateDisputeStatus({
    required String disputeId,
    required String newStatus,
    String? resolution,
  }) async {
    try {
      _logger.i('Updating dispute status: $disputeId');

      final Map<String, dynamic> updateData = {'status': newStatus};

      if (resolution != null) {
        updateData['resolution'] = resolution;
      }

      if (newStatus == 'resolved' || newStatus == 'rejected') {
        updateData['resolved_at'] = DateTime.now().toIso8601String();
      }

      final response = await _supabase
          .from('disputes')
          .update(updateData)
          .eq('id', disputeId)
          .select(
              '*, bookings(*, shipments(*, shippers(*, users!shippers_user_id_fkey(*))), users!bookings_client_id_fkey(*))')
          .single();

      _logger.i('Dispute status updated');
      return Dispute.fromJson(response);
    } catch (e) {
      _logger.e('Error updating dispute status: $e');
      rethrow;
    }
  }

  /// Resolve dispute in favor of client (refund)
  Future<Dispute?> resolveInFavorOfClient({
    required String disputeId,
    required String resolution,
  }) async {
    try {
      _logger.i('Resolving dispute in favor of client: $disputeId');

      // Get dispute details
      final dispute = await getDisputeById(disputeId);
      if (dispute == null) throw Exception('Dispute not found');

      // Refund payment
      final paymentService = PaymentService();
      await paymentService.refundPayment(dispute.bookingId);

      // Update dispute status
      return await updateDisputeStatus(
        disputeId: disputeId,
        newStatus: 'resolved',
        resolution: resolution,
      );
    } catch (e) {
      _logger.e('Error resolving dispute: $e');
      rethrow;
    }
  }

  /// Reject dispute
  Future<Dispute?> rejectDispute({
    required String disputeId,
    required String resolution,
  }) async {
    try {
      return await updateDisputeStatus(
        disputeId: disputeId,
        newStatus: 'rejected',
        resolution: resolution,
      );
    } catch (e) {
      _logger.e('Error rejecting dispute: $e');
      rethrow;
    }
  }

  /// Get dispute statistics (admin)
  Future<Map<String, dynamic>?> getDisputeStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase.from('disputes').select();

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final disputes = await query;
      final disputesList = disputes as List;

      final open = disputesList.where((d) => d['status'] == 'open').length;
      final investigating =
          disputesList.where((d) => d['status'] == 'investigating').length;
      final resolved =
          disputesList.where((d) => d['status'] == 'resolved').length;
      final rejected =
          disputesList.where((d) => d['status'] == 'rejected').length;

      // Count by type
      final fraudCount = disputesList.where((d) => d['type'] == 'fraud').length;
      final customsCount =
          disputesList.where((d) => d['type'] == 'customs_seizure').length;
      final damageCount =
          disputesList.where((d) => d['type'] == 'damage').length;

      return {
        'total_disputes': disputesList.length,
        'open': open,
        'investigating': investigating,
        'resolved': resolved,
        'rejected': rejected,
        'fraud_cases': fraudCount,
        'customs_seizures': customsCount,
        'damage_claims': damageCount,
        'resolution_rate': disputesList.isEmpty
            ? 0
            : ((resolved + rejected) / disputesList.length) * 100,
      };
    } catch (e) {
      _logger.e('Error getting dispute stats: $e');
      return null;
    }
  }

  /// Flag shipper for suspicious activity
  Future<void> flagShipperForReview(String shipperId, String reason) async {
    try {
      _logger.i('Flagging shipper for review: $shipperId');

      // Create a dispute-related note or flag in a separate table
      // This is a security feature to track problematic shippers
      await _supabase.from('shipper_flags').insert({
        'id': const Uuid().v4(),
        'shipper_id': shipperId,
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });

      _logger.i('Shipper flagged for review');
    } catch (e) {
      _logger.e('Error flagging shipper: $e');
      rethrow;
    }
  }
}

// ============================================================================
// NOTIFICATION SERVICE
// ============================================================================

class NotificationService {
  SupabaseClient get _supabase => SupabaseConfig.client;
  final _logger = Logger();

  /// Create a notification
  Future<Notification?> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? relatedBookingId,
  }) async {
    try {
      final response = await _supabase
          .from('notifications')
          .insert({
            'id': const Uuid().v4(),
            'user_id': userId,
            'type': type,
            'title': title,
            'message': message,
            'related_booking_id': relatedBookingId,
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      _logger.i('Notification created for user: $userId');
      return Notification.fromJson(response);
    } catch (e) {
      _logger.e('Error creating notification: $e');
      return null;
    }
  }

  /// Get user notifications
  Future<List<Notification>> getUserNotifications({
    required String userId,
    bool unreadOnly = false,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query =
          _supabase.from('notifications').select().eq('user_id', userId);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => Notification.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);

      _logger.i('Notification marked as read');
    } catch (e) {
      _logger.e('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('user_id', userId);

      _logger.i('All notifications marked as read');
    } catch (e) {
      _logger.e('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Listen to real-time notifications
  Stream<List<Notification>> listenToNotifications(String userId) {
    try {
      return _supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at')
          .map((data) => (data as List)
              .map(
                  (item) => Notification.fromJson(item as Map<String, dynamic>))
              .toList());
    } catch (e) {
      _logger.e('Error listening to notifications: $e');
      return Stream.value([]);
    }
  }

  /// Send notification to shipper
  Future<void> notifyShipperBookingConfirmed({
    required String shipperId,
    required String bookingId,
    required String productName,
    required double allocatedWeight,
  }) async {
    try {
      await createNotification(
        userId: shipperId,
        type: 'booking_confirmed',
        title: 'Nouvelle commande confirmée',
        message: 'Un client a réservé $allocatedWeight kg pour "$productName"',
        relatedBookingId: bookingId,
      );
    } catch (e) {
      _logger.e('Error notifying shipper: $e');
    }
  }

  /// Send notification to client
  Future<void> notifyClientShipmentDispatched({
    required String clientId,
    required String bookingId,
    required String destination,
  }) async {
    try {
      await createNotification(
        userId: clientId,
        type: 'shipment_dispatched',
        title: 'Votre colis a été expédié',
        message: 'Votre colis est en route vers $destination',
        relatedBookingId: bookingId,
      );
    } catch (e) {
      _logger.e('Error notifying client: $e');
    }
  }

  /// Send notification to client
  Future<void> notifyClientShipmentDelivered({
    required String clientId,
    required String bookingId,
  }) async {
    try {
      await createNotification(
        userId: clientId,
        type: 'shipment_delivered',
        title: 'Colis livré avec succès',
        message: 'Votre commande a été livrée. Merci!',
        relatedBookingId: bookingId,
      );
    } catch (e) {
      _logger.e('Error notifying client: $e');
    }
  }
}
