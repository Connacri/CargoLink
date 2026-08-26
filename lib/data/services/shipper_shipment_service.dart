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
    String shipperType = 'voyageur_ordinaire',
    String? microCardPhotoUrl,
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
            'shipper_type': shipperType,
            'micro_card_photo_url': microCardPhotoUrl,
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
    String? shipperType,
    String? microCardPhotoUrl,
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
      if (shipperType != null) updateData['shipper_type'] = shipperType;
      if (microCardPhotoUrl != null) {
        updateData['micro_card_photo_url'] = microCardPhotoUrl;
      }

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

  /// Save a collection address to the shipper's saved addresses list.
  Future<void> saveCollectionAddress({
    required String shipperId,
    required String address,
  }) async {
    try {
      _logger.i('Saving collection address for shipper: $shipperId');
      // Fetch current saved addresses
      final response = await _supabase
          .from('shippers')
          .select('saved_addresses')
          .eq('id', shipperId)
          .single();
      final current = (response['saved_addresses'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [];
      if (current.contains(address)) return; // déjà sauvegardée
      current.add(address);
      await _supabase.from('shippers').update({
        'saved_addresses': current,
      }).eq('id', shipperId);
      _logger.i('Collection address saved');
    } catch (e) {
      _logger.e('Error saving collection address: $e');
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

  /// Tous les expéditeurs avec leur profil utilisateur (dashboard fondateur :
  /// répartition voyageurs ordinaires / micro-importateurs et finances).
  Future<List<Shipper>> getAllShippers({int limit = 500, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('shippers')
          .select('*, users!shippers_user_id_fkey(*)')
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Shipper.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting all shippers: $e');
      return [];
    }
  }

  /// Count shippers awaiting verification (founder notification badge).
  Future<int> countPendingShippers() async {    try {
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
    DateTime? arrivalDate,
    String? airline,
    String? flightNumber,
    String? description,
    String? collectionAddress,
    double? publicationFee,
    double publicationFeeDiscount = 0,
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
            'arrival_date': arrivalDate?.toIso8601String(),
            'airline': airline,
            'flight_number': flightNumber,
            'status': 'active',
            'publication_fee': publicationFee,
            // Paiement par carte Visa (-30%) → l'offre reste cachée des
            // clients tant que le fondateur n'a pas confirmé le paiement.
            // Toute autre publication est visible immédiatement.
            'publication_fee_status':
                publicationFee != null && publicationFeeDiscount > 0
                    ? 'awaiting_confirmation'
                    : 'paid',
            'publication_fee_discount': publicationFeeDiscount,
            'description': description,
            'collection_address': collectionAddress,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('*, shippers(*, users!shippers_user_id_fkey(*))')
          .single();

      // Le dû de publication est enregistré comme platform_fee (portefeuille
      // fondateur) : Visa → awaiting_confirmation (paiement à confirmer),
      // sinon pending avec échéance 7 jours.
      if (publicationFee != null && publicationFee > 0) {
        final discounted = publicationFeeDiscount > 0
            ? publicationFee - (publicationFee * publicationFeeDiscount / 100)
            : publicationFee;
        await _supabase.from('platform_fees').insert({
          'shipment_id': response['id'],
          'shipper_id': shipperId,
          'amount': discounted,
          'currency': 'DZD',
          'type': 'publication',
          'status': publicationFeeDiscount > 0
              ? 'awaiting_confirmation'
              : 'pending',
          if (publicationFeeDiscount > 0) 'payment_method': 'visa',
          if (publicationFeeDiscount <= 0)
            'due_at':
                DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        });
      }

      _logger.i('Shipment published successfully');
      return Shipment.fromJson(response);
    } catch (e) {
      _logger.e('Error publishing shipment: $e');
      rethrow;
    }
  }

  /// The shipper requests to pay the publication fee by card. The 30% Visa
  /// discount is already applied by the caller when the checkbox is checked.
  /// The offer stays hidden from clients until the founder confirms.
  Future<Shipment?> payShipmentPublicationFee(String shipmentId,
      {double discount = 0}) async {
    try {
      final response = await _supabase
          .from('shipments')
          .update({
            'publication_fee_status': 'awaiting_confirmation',
            'publication_fee_discount': discount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', shipmentId)
          .select('*, shippers(*, users!shippers_user_id_fkey(*))')
          .single();
      _logger.i('Publication fee payment requested for shipment: $shipmentId');
      return Shipment.fromJson(response);
    } catch (e) {
      _logger.e('Error paying shipment publication fee: $e');
      rethrow;
    }
  }

  /// Founder confirms the publication payment → the offer becomes visible to
  /// clients (publication_fee_status = paid) and the publication platform fee
  /// is marked paid in the founder wallet.
  Future<Shipment?> confirmShipmentPublication(String shipmentId) async {
    try {
      final response = await _supabase
          .from('shipments')
          .update({
            'publication_fee_status': 'paid',
            'publication_paid_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', shipmentId)
          .select('*, shippers(*, users!shippers_user_id_fkey(*))')
          .single();
      await _supabase
          .from('platform_fees')
          .update({
            'status': 'paid',
            'paid_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('shipment_id', shipmentId)
          .eq('type', 'publication')
          .eq('status', 'awaiting_confirmation');
      _logger.i('Shipment publication confirmed: $shipmentId');
      return Shipment.fromJson(response);
    } catch (e) {
      _logger.e('Error confirming shipment publication: $e');
      rethrow;
    }
  }

  /// Offers whose publication fee is pending or awaiting confirmation — used
  /// by the founder dashboard to validate the payment and make them visible.
  /// (admin / super_admin only, enforced by RLS).
  Future<List<Shipment>> getAwaitingPublicationShipments({
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('shipments')
          .select('*, shippers(*, users!shippers_user_id_fkey(*))')
          .neq('publication_fee_status', 'paid')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (response as List)
          .map((item) => Shipment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting awaiting publication shipments: $e');
      return [];
    }
  }

  /// Count of offers awaiting publication confirmation — powers the founder
  /// dashboard badge.
  Future<int> countAwaitingPublicationShipments() async {
    try {
      final response = await _supabase
          .from('shipments')
          .select('id')
          .neq('publication_fee_status', 'paid')
          .eq('status', 'active');
      return (response as List).length;
    } catch (e) {
      _logger.e('Error counting awaiting publication shipments: $e');
      return 0;
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

  /// Résout les ids des expéditeurs d'un type donné. La table `shippers`
  /// étant petite, ce pré-filtre explicite est plus fiable qu'un filtre
  /// embedded (`shippers.shipper_type=eq.…`) côté PostgREST, dont la
  /// sémantique semi-jointure s'est révélée non fiable ici (les chips de
  /// filtre affichaient toutes les offres quel que soit le type choisi).
  Future<List<String>> _shipperIdsOfType(String shipperType) async {
    final rows = await _supabase
        .from('shippers')
        .select('id')
        .eq('shipper_type', shipperType);
    return (rows as List).map((r) => r['id'] as String).toList();
  }

  /// Get active shipments with filters. Only offers whose publication fee was
  /// confirmed by the founder (publication_fee_status = 'paid') are shown to
  /// clients.
  Future<List<Shipment>> getActiveShipments({
    String? destinationCity,
    String? originCountry,
    String? shipperType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Filtre par type d'expéditeur : ids résolus en amont puis `inFilter`,
      // jamais via un filtre embedded (voir _shipperIdsOfType).
      List<String>? shipperIds;
      if (shipperType != null) {
        shipperIds = await _shipperIdsOfType(shipperType);
        if (shipperIds.isEmpty) return const [];
      }

      var query = _supabase
          .from('shipments')
          .select('*, shippers(*, users!shippers_user_id_fkey(*))')
          .eq('status', 'active')
          .eq('publication_fee_status', 'paid')
          .gt('available_weight_kg', 0);

      if (destinationCity != null) {
        query = query.ilike('destination_city', '%$destinationCity%');
      }

      if (originCountry != null) {
        query = query.ilike('origin_country', originCountry);
      }

      if (shipperIds != null) {
        query = query.inFilter('shipper_id', shipperIds);
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

  /// Search shipments (server-side, paginated). [shipperType] restreint les
  /// résultats au même filtre que les chips de l'accueil (voir
  /// getActiveShipments pour le choix du pré-filtre explicite).
  Future<List<Shipment>> searchShipments({
    required String query,
    String? shipperType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      List<String>? shipperIds;
      if (shipperType != null) {
        shipperIds = await _shipperIdsOfType(shipperType);
        if (shipperIds.isEmpty) return const [];
      }

      var searchQuery = _supabase
          .from('shipments')
          .select('*, shippers(*, users!shippers_user_id_fkey(*))')
          .or(
            'origin_country.ilike.%$query%,destination_city.ilike.%$query%',
          )
          .eq('status', 'active')
          // Même filtre que getActiveShipments : une offre dont le paiement
          // Visa n'a pas été confirmé par le fondateur ne doit pas fuiter
          // dans les résultats de recherche.
          .eq('publication_fee_status', 'paid');

      if (shipperIds != null) {
        searchQuery = searchQuery.inFilter('shipper_id', shipperIds);
      }

      final response = await searchQuery
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
