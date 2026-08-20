import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../../core/config/supabase_config.dart';
import '../../core/constants/app_constants.dart';
import 'package:logger/logger.dart';

class ShipperService {
  SupabaseClient get _supabase => SupabaseConfig.client;
  final _logger = Logger();

  // ============================================================================
  // SHIPPER REGISTRATION & VERIFICATION
  // ============================================================================

  /// Register a new shipper with documents
  Future<Shipper?> registerShipper({
    required String userId,
    required String passportNumber,
    required String passportPhotoUrl,
    required String livePhotoUrl,
  }) async {
    try {
      _logger.i('Registering shipper: $userId');

      final response = await _supabase
          .from('shippers')
          .insert({
            'user_id': userId,
            'passport_number': passportNumber,
            'passport_photo_url': passportPhotoUrl,
            'live_photo_url': livePhotoUrl,
            'verification_status': 'pending',
            'rating': 0.0,
            'total_shipments': 0,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      _logger.i('Shipper registered successfully');
      return Shipper.fromJson(response);
    } catch (e) {
      _logger.e('Error registering shipper: $e');
      rethrow;
    }
  }

  /// Re-submit shipper documents after a rejection
  Future<Shipper?> updateShipperDocuments({
    required String shipperId,
    String? passportNumber,
    String? passportPhotoUrl,
    String? livePhotoUrl,
  }) async {
    try {
      _logger.i('Updating shipper documents: $shipperId');

      final updateData = <String, dynamic>{
        'verification_status': 'pending',
        'rejection_reason': null,
        'verified_by_admin_id': null,
        'verified_at': null,
      };

      if (passportNumber != null) {
        updateData['passport_number'] = passportNumber;
      }
      if (passportPhotoUrl != null) {
        updateData['passport_photo_url'] = passportPhotoUrl;
      }
      if (livePhotoUrl != null) updateData['live_photo_url'] = livePhotoUrl;

      final response = await _supabase
          .from('shippers')
          .update(updateData)
          .eq('id', shipperId)
          .select()
          .single();

      _logger.i('Shipper documents updated');
      return Shipper.fromJson(response);
    } catch (e) {
      _logger.e('Error updating shipper documents: $e');
      rethrow;
    }
  }

  /// Get shipper profile by user ID. Returns null when the user has no shipper
  /// profile yet (e.g. they just switched their role to shipper) instead of
  /// throwing a PGRST116 "0 rows" exception.
  Future<Shipper?> getShipperByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('shippers')
          .select('*, users!shippers_user_id_fkey(*)')
          .eq('user_id', userId)
          .maybeSingle();

      return response == null ? null : Shipper.fromJson(response);
    } catch (e) {
      _logger.w('Error getting shipper: $e');
      return null;
    }
  }

  /// Get shipper by ID
  Future<Shipper?> getShipperById(String shipperId) async {
    try {
      final response = await _supabase
          .from('shippers')
          .select('*, users!shippers_user_id_fkey(*)')
          .eq('id', shipperId)
          .maybeSingle();

      return response == null ? null : Shipper.fromJson(response);
    } catch (e) {
      _logger.w('Error getting shipper by ID: $e');
      return null;
    }
  }

  /// Get all pending shippers (for admin verification)
  Future<List<Shipper>> getPendingShippers(
      {int limit = 50, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('shippers')
          .select('*, users!shippers_user_id_fkey(*)')
          .eq('verification_status', 'pending')
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Shipper.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting pending shippers: $e');
      return [];
    }
  }

  /// Count shippers awaiting verification (founder notification badge).
  Future<int> countPendingShippers() async {
    try {
      final response = await _supabase
          .from('shippers')
          .select('id')
          .eq('verification_status', 'pending');
      return (response as List).length;
    } catch (e) {
      _logger.e('Error counting pending shippers: $e');
      return 0;
    }
  }

  /// Verify shipper (admin only)
  Future<Shipper?> verifyShipper({
    required String shipperId,
    required String adminId,
  }) async {
    try {
      _logger.i('Verifying shipper: $shipperId');

      final response = await _supabase
          .from('shippers')
          .update({
            'verification_status': 'verified',
            'verified_by_admin_id': adminId,
            'verified_at': DateTime.now().toIso8601String(),
          })
          .eq('id', shipperId)
          .select()
          .single();

      _logger.i('Shipper verified successfully');
      return Shipper.fromJson(response);
    } catch (e) {
      _logger.e('Error verifying shipper: $e');
      rethrow;
    }
  }

  /// Reject shipper (admin only)
  Future<Shipper?> rejectShipper({
    required String shipperId,
    required String adminId,
    required String rejectionReason,
  }) async {
    try {
      _logger.i('Rejecting shipper: $shipperId');

      final response = await _supabase
          .from('shippers')
          .update({
            'verification_status': 'rejected',
            'verified_by_admin_id': adminId,
            'verified_at': DateTime.now().toIso8601String(),
            'rejection_reason': rejectionReason,
          })
          .eq('id', shipperId)
          .select()
          .single();

      _logger.i('Shipper rejected');
      return Shipper.fromJson(response);
    } catch (e) {
      _logger.e('Error rejecting shipper: $e');
      rethrow;
    }
  }

  /// Update shipper rating
  Future<void> updateShipperRating(String shipperId, double newRating) async {
    try {
      await _supabase
          .from('shippers')
          .update({'rating': newRating}).eq('id', shipperId);

      _logger.i('Shipper rating updated');
    } catch (e) {
      _logger.e('Error updating shipper rating: $e');
      rethrow;
    }
  }

  /// Get shipper stats
  Future<Map<String, dynamic>?> getShipperStats(String shipperId) async {
    try {
      final shipments = await _supabase
          .from('shipments')
          .select()
          .eq('shipper_id', shipperId);
      final shipmentsList = shipments as List;

      final completedShipments =
          shipmentsList.where((s) => s['status'] == 'completed').length;

      var totalBookings = 0;
      if (shipmentsList.isNotEmpty) {
        final bookings = await _supabase
            .from('bookings')
            .select('id, shipments!inner(shipper_id)')
            .eq('shipments.shipper_id', shipperId);
        totalBookings = (bookings as List).length;
      }

      return {
        'total_shipments': shipmentsList.length,
        'completed_shipments': completedShipments,
        'active_shipments': shipmentsList.length - completedShipments,
        'total_bookings': totalBookings,
      };
    } catch (e) {
      _logger.e('Error getting shipper stats: $e');
      return null;
    }
  }
}

// ============================================================================
// SHIPMENT SERVICE
// ============================================================================

class ShipmentService {
  SupabaseClient get _supabase => SupabaseConfig.client;
  final _logger = Logger();

  /// Publish a new shipment
  Future<Shipment?> publishShipment({
    required String shipperId,
    required String originCountry,
    required String destinationCity,
    required double availableWeightKg,
    required double pricePerKg,
    required DateTime departureDate,
    required DateTime arrivalDate,
    String? flightNumber,
    String? description,
  }) async {
    try {
      _logger.i('Publishing shipment for shipper: $shipperId');

      final response = await _supabase
          .from('shipments')
          .insert({
            'shipper_id': shipperId,
            'origin_country': originCountry,
            'destination_city': destinationCity,
            'available_weight_kg': availableWeightKg,
            'reserved_weight_kg': 0,
            'price_per_kg': pricePerKg,
            'departure_date': departureDate.toIso8601String(),
            'arrival_date': arrivalDate.toIso8601String(),
            'flight_number': flightNumber,
            'status': 'active',
            'description': description,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('*, shippers(*, users!shippers_user_id_fkey(*))')
          .single();

      _logger.i('Shipment published successfully');
      return Shipment.fromJson(response);
    } catch (e) {
      _logger.e('Error publishing shipment: $e');
      rethrow;
    }
  }

  /// Get shipment by ID
  Future<Shipment?> getShipmentById(String shipmentId) async {
    try {
      final response = await _supabase
          .from('shipments')
          .select('*, shippers(*, users!shippers_user_id_fkey(*))')
          .eq('id', shipmentId)
          .single();

      return Shipment.fromJson(response);
    } catch (e) {
      _logger.e('Error getting shipment: $e');
      return null;
    }
  }

  /// Get active shipments with filters
  Future<List<Shipment>> getActiveShipments({
    String? destinationCity,
    String? originCountry,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('shipments')
          .select('*, shippers(*, users!shippers_user_id_fkey(*))')
          .eq('status', 'active')
          .gt('available_weight_kg', 0);

      if (destinationCity != null) {
        query = query.ilike('destination_city', destinationCity);
      }

      if (originCountry != null) {
        query = query.ilike('origin_country', originCountry);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => Shipment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting active shipments: $e');
      return [];
    }
  }

  /// Get shipper's shipments
  Future<List<Shipment>> getShipperShipments({
    required String shipperId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('shipments')
          .select('*, shippers(*, users!shippers_user_id_fkey(*))')
          .eq('shipper_id', shipperId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => Shipment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting shipper shipments: $e');
      return [];
    }
  }

  /// Get all shipments (admin / super_admin only, enforced by RLS).
  Future<List<Shipment>> getAllShipments(
      {int limit = 200, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('shipments')
          .select('*, shippers(*, users!shippers_user_id_fkey(*))')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => Shipment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting all shipments: $e');
      return [];
    }
  }

  /// Update shipment status
  Future<Shipment?> updateShipmentStatus(
    String shipmentId,
    String newStatus,
  ) async {
    try {
      final response = await _supabase
          .from('shipments')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', shipmentId)
          .select('*, shippers(*, users!shippers_user_id_fkey(*))')
          .single();

      _logger.i('Shipment status updated to: $newStatus');
      return Shipment.fromJson(response);
    } catch (e) {
      _logger.e('Error updating shipment status: $e');
      rethrow;
    }
  }

  /// Calculate allocation weight (rounding logic)
  double calculateAllocationWeight(
    double requestedWeight,
    double availableWeight, {
    int roundingPrecision = AppConstants.roundingPrecision,
  }) {
    // Round up to nearest configured rounding precision (kg)
    double allocatedWeight =
        (requestedWeight / roundingPrecision).ceil() *
            roundingPrecision.toDouble();

    // Don't allocate more than available (the rounding-up rule must NOT be
    // capped back to the requested weight, otherwise the displayed "rounded
    // weight" preview in the booking wizard would never match the amount
    // actually charged).
    allocatedWeight =
        allocatedWeight > availableWeight ? availableWeight : allocatedWeight;

    return allocatedWeight;
  }

  /// Search shipments (server-side, paginated)
  Future<List<Shipment>> searchShipments({
    required String query,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('shipments')
          .select('*, shippers(*, users!shippers_user_id_fkey(*))')
          .or(
            'origin_country.ilike.%$query%,destination_city.ilike.%$query%',
          )
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => Shipment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error searching shipments: $e');
      return [];
    }
  }
}
