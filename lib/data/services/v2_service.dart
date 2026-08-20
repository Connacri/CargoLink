import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../models/v2_models.dart';
import '../../core/config/supabase_config.dart';

// ============================================================================
// V2 SERVICE — Réseau logistique multi-shipper (CARGOLINK_V2_AMELIORE.md)
//
// Lectures : accès direct (RLS).
// Écritures critiques (custody, tokens, solde de capacité, paiements) :
// uniquement via RPC SECURITY DEFINER (jamais un UPDATE direct autorisé par
// RLS seul — §91, §92, §93).
// ============================================================================

class V2Service {
  SupabaseClient get _supabase => SupabaseConfig.client;
  final _logger = Logger();

  // --------------------------------------------------------------------------
  // TRIPS
  // --------------------------------------------------------------------------

  Future<List<Trip>> getActiveTrips({
    String? destination,
    String? origin,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('trips').select().eq('status', 'active');

      if (destination != null) {
        query = query.eq('destination', destination);
      }
      if (origin != null) {
        query = query.eq('origin', origin);
      }

      final response = await query
          .order('departure_at', ascending: true)
          .range(offset, offset + limit - 1);
      return (response as List)
          .map((item) => Trip.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting active trips: $e');
      return [];
    }
  }

  Future<List<Trip>> getShipperTrips({
    required String shipperId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('trips')
          .select()
          .eq('shipper_id', shipperId)
          .order('departure_at', ascending: true)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => Trip.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting shipper trips: $e');
      return [];
    }
  }

  /// Création d'un trip (RLS : le shipper gère ses propres trips).
  Future<Trip?> createTrip({
    required String shipperId,
    required String origin,
    required String destination,
    required double capacityKg,
    required double pricePerKg,
    DateTime? departureAt,
    DateTime? estimatedArrivalAt,
    String? airline,
    String? flightNumber,
    String? originLocation,
    String? destinationLocation,
  }) async {
    try {
      final response = await _supabase
          .from('trips')
          .insert({
            'id': const Uuid().v4(),
            'shipper_id': shipperId,
            'origin': origin,
            'destination': destination,
            'origin_location': originLocation,
            'destination_location': destinationLocation,
            'departure_at': departureAt?.toIso8601String(),
            'estimated_arrival_at': estimatedArrivalAt?.toIso8601String(),
            'capacity_kg': capacityKg,
            'reserved_kg': 0,
            'available_kg': capacityKg,
            'price_per_kg': pricePerKg,
            'airline': airline,
            'flight_number': flightNumber,
            'status': 'active',
          })
          .select()
          .single();

      _logger.i('Trip created');
      return Trip.fromJson(response);
    } catch (e) {
      _logger.e('Error creating trip: $e');
      rethrow;
    }
  }

  Future<void> cancelTrip(String tripId) async {
    try {
      await _supabase
          .from('trips')
          .update({'status': 'cancelled'})
          .eq('id', tripId);
      _logger.i('Trip cancelled');
    } catch (e) {
      _logger.e('Error cancelling trip: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // PACKAGES
  // --------------------------------------------------------------------------

  Future<List<ShipmentPackage>> getShipmentPackages(String shipmentId) async {
    try {
      final response = await _supabase
          .from('shipment_packages')
          .select()
          .eq('shipment_id', shipmentId)
          .order('package_number', ascending: true);

      return (response as List)
          .map((item) => ShipmentPackage.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting shipment packages: $e');
      return [];
    }
  }

  Future<List<ShipmentPackage>> getPackagesInCustody(String custodianId) async {
    try {
      final response = await _supabase
          .from('shipment_packages')
          .select()
          .eq('current_custodian_id', custodianId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => ShipmentPackage.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting packages in custody: $e');
      return [];
    }
  }

  /// Création d'un package. `is_divisible` est verrouillé après le premier
  /// handover — cette insertion n'utilise que le statut initial.
  Future<ShipmentPackage?> createPackage({
    required String shipmentId,
    required int packageNumber,
    required double weight,
    double? declaredValue,
    String? description,
    bool isDivisible = false,
    String? packageFingerprint,
    String? trackingCode,
  }) async {
    try {
      final response = await _supabase
          .from('shipment_packages')
          .insert({
            'id': const Uuid().v4(),
            'shipment_id': shipmentId,
            'tracking_code': trackingCode,
            'package_number': packageNumber,
            'weight': weight,
            'declared_value': declaredValue,
            'description': description,
            'is_divisible': isDivisible,
            'package_fingerprint': packageFingerprint,
            'status': 'created',
          })
          .select()
          .single();

      _logger.i('Package created');
      return ShipmentPackage.fromJson(response);
    } catch (e) {
      _logger.e('Error creating package: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // LEGS
  // --------------------------------------------------------------------------

  Future<List<ShipmentLeg>> getShipmentLegs(String shipmentId) async {
    try {
      final response = await _supabase
          .from('shipment_legs')
          .select()
          .eq('shipment_id', shipmentId)
          .order('sequence_number', ascending: true);

      return (response as List)
          .map((item) => ShipmentLeg.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting shipment legs: $e');
      return [];
    }
  }

  Future<List<ShipmentLeg>> getShipperLegs(String shipperId) async {
    try {
      final response = await _supabase
          .from('shipment_legs')
          .select()
          .eq('shipper_id', shipperId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => ShipmentLeg.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting shipper legs: $e');
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // EVENTS (§19 — jalons ; jamais UPDATE sur un événement, §76)
  // --------------------------------------------------------------------------

  Future<ShipmentEvent?> addShipmentEvent({
    required String shipmentId,
    required String eventType,
    String? packageId,
    String? legId,
    String? actorId,
    double? latitude,
    double? longitude,
    double? accuracy,
    Map<String, dynamic>? metadata,
    String? proofId,
    DateTime? expectedBy,
  }) async {
    try {
      final response = await _supabase
          .from('shipment_events')
          .insert({
            'id': const Uuid().v4(),
            'shipment_id': shipmentId,
            'package_id': packageId,
            'leg_id': legId,
            'event_type': eventType,
            'actor_id': actorId,
            'latitude': latitude,
            'longitude': longitude,
            'accuracy': accuracy,
            'metadata': metadata,
            'proof_id': proofId,
            'expected_by': expectedBy?.toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      _logger.i('Shipment event added: $eventType');
      return ShipmentEvent.fromJson(response);
    } catch (e) {
      _logger.e('Error adding shipment event: $e');
      rethrow;
    }
  }

  Future<List<ShipmentEvent>> getShipmentEvents(
    String shipmentId, {
    String? packageId,
    int limit = 100,
  }) async {
    try {
      var query = _supabase
          .from('shipment_events')
          .select()
          .eq('shipment_id', shipmentId);

      if (packageId != null) {
        query = query.eq('package_id', packageId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((item) => ShipmentEvent.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting shipment events: $e');
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // CUSTODY TRANSFERS (lecture) — écritures via RPC uniquement
  // --------------------------------------------------------------------------

  Future<List<CustodyTransfer>> getShipmentTransfers(String shipmentId) async {
    try {
      final response = await _supabase
          .from('custody_transfers')
          .select()
          .eq('shipment_id', shipmentId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((item) => CustodyTransfer.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting shipment transfers: $e');
      return [];
    }
  }

  Future<List<CustodyTransfer>> getUserTransfers(String userId) async {
    try {
      final response = await _supabase
          .from('custody_transfers')
          .select()
          .or('from_user_id.eq.$userId,to_user_id.eq.$userId')
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => CustodyTransfer.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting user transfers: $e');
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // RPC CRITIQUES (§92-93)
  // Chaque fonction RPC porte un idempotency_key (§29bis) : un retry réseau ne
  // produit jamais de double écriture. La vérification chain_hash/signatures est
  // effectuée par la fonction serveur avant commit.
  // --------------------------------------------------------------------------

  Future<Map<String, dynamic>?> completeTransfer({
    required String transferId,
    required String idempotencyKey,
    String? verificationMethod,
    double? latitude,
    double? longitude,
    String? chainHash,
    String? signatureFrom,
    String? signatureTo,
  }) async {
    try {
      final response = await _supabase.rpc('complete_transfer', params: {
        'p_transfer_id': transferId,
        'p_idempotency_key': idempotencyKey,
        'p_verification_method': verificationMethod,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_chain_hash': chainHash,
        'p_signature_from': signatureFrom,
        'p_signature_to': signatureTo,
      });
      return response as Map<String, dynamic>?;
    } catch (e) {
      _logger.e('Error completing transfer: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> createTransfer({
    required String shipmentId,
    required String fromUserId,
    required String toUserId,
    required double totalWeight,
    required String transferType,
    String? fromLegId,
    String? toLegId,
    List<String>? packageIds,
    String? notes,
  }) async {
    try {
      final response = await _supabase.rpc('create_transfer', params: {
        'p_shipment_id': shipmentId,
        'p_from_user_id': fromUserId,
        'p_to_user_id': toUserId,
        'p_total_weight': totalWeight,
        'p_transfer_type': transferType,
        'p_from_leg_id': fromLegId,
        'p_to_leg_id': toLegId,
        'p_package_ids': packageIds,
        'p_notes': notes,
      });
      return response as Map<String, dynamic>?;
    } catch (e) {
      _logger.e('Error creating transfer: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> acceptTransfer({
    required String transferId,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _supabase.rpc('accept_transfer', params: {
        'p_transfer_id': transferId,
        'p_idempotency_key': idempotencyKey,
      });
      return response as Map<String, dynamic>?;
    } catch (e) {
      _logger.e('Error accepting transfer: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // PROOFS
  // --------------------------------------------------------------------------

  Future<ShipmentProof?> addProof({
    String? shipmentId,
    String? packageId,
    String? transferId,
    String? eventId,
    required String proofType,
    String? reference,
    String? url,
  }) async {
    try {
      final response = await _supabase
          .from('shipment_proofs')
          .insert({
            'id': const Uuid().v4(),
            'shipment_id': shipmentId,
            'package_id': packageId,
            'transfer_id': transferId,
            'event_id': eventId,
            'proof_type': proofType,
            'reference': reference,
            'url': url,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return ShipmentProof.fromJson(response);
    } catch (e) {
      _logger.e('Error adding proof: $e');
      rethrow;
    }
  }

  Future<List<ShipmentProof>> getShipmentProofs(String shipmentId) async {
    try {
      final response = await _supabase
          .from('shipment_proofs')
          .select()
          .eq('shipment_id', shipmentId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((item) => ShipmentProof.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting shipment proofs: $e');
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // TRACKING POINTS
  // --------------------------------------------------------------------------

  Future<TrackingPoint?> addTrackingPoint({
    String? shipmentId,
    String? packageId,
    String? legId,
    String? shipperId,
    double? latitude,
    double? longitude,
    double? accuracy,
  }) async {
    try {
      final response = await _supabase
          .from('tracking_points')
          .insert({
            'id': const Uuid().v4(),
            'shipment_id': shipmentId,
            'package_id': packageId,
            'leg_id': legId,
            'shipper_id': shipperId,
            'latitude': latitude,
            'longitude': longitude,
            'accuracy': accuracy,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return TrackingPoint.fromJson(response);
    } catch (e) {
      _logger.e('Error adding tracking point: $e');
      rethrow;
    }
  }

  Future<List<TrackingPoint>> getShipmentTrackingPoints(
    String shipmentId, {
    int limit = 200,
  }) async {
    try {
      final response = await _supabase
          .from('tracking_points')
          .select()
          .eq('shipment_id', shipmentId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((item) => TrackingPoint.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting tracking points: $e');
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // ALLOCATIONS / PAYOUTS (§56bis) — gel par allocation, jamais par shipment
  // --------------------------------------------------------------------------

  Future<List<PaymentAllocation>> getShipmentAllocations(String shipmentId) async {
    try {
      final response = await _supabase
          .from('payment_allocations')
          .select()
          .eq('shipment_id', shipmentId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((item) => PaymentAllocation.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting shipment allocations: $e');
      return [];
    }
  }

  Future<List<PaymentAllocation>> getShipperAllocations(String shipperId) async {
    try {
      final response = await _supabase
          .from('payment_allocations')
          .select()
          .eq('shipper_id', shipperId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => PaymentAllocation.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting shipper allocations: $e');
      return [];
    }
  }

  Future<List<Payout>> getShipperPayouts(String shipperId) async {
    try {
      final response = await _supabase
          .from('payouts')
          .select()
          .eq('shipper_id', shipperId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Payout.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting shipper payouts: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> freezeAllocation({
    required String allocationId,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _supabase.rpc('freeze_payout', params: {
        'p_allocation_id': allocationId,
        'p_idempotency_key': idempotencyKey,
      });
      return response as Map<String, dynamic>?;
    } catch (e) {
      _logger.e('Error freezing allocation: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> releasePayout({
    required String payoutId,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _supabase.rpc('release_payout', params: {
        'p_payout_id': payoutId,
        'p_idempotency_key': idempotencyKey,
      });
      return response as Map<String, dynamic>?;
    } catch (e) {
      _logger.e('Error releasing payout: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // EXCEPTIONS (§61-62)
  // --------------------------------------------------------------------------

  Future<List<ShipmentException>> getOpenExceptions({
    String? shipmentId,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('shipment_exceptions')
          .select()
          .eq('status', 'open');

      if (shipmentId != null) {
        query = query.eq('shipment_id', shipmentId);
      }

      final response = await query
          .order('reported_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((item) => ShipmentException.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting open exceptions: $e');
      return [];
    }
  }

  Future<ShipmentException?> reportException({
    String? shipmentId,
    String? packageId,
    String? legId,
    required String type,
    required String severity,
    String? description,
    String? reportedBy,
    String? location,
  }) async {
    try {
      final response = await _supabase
          .from('shipment_exceptions')
          .insert({
            'id': const Uuid().v4(),
            'shipment_id': shipmentId,
            'package_id': packageId,
            'leg_id': legId,
            'type': type,
            'severity': severity,
            'description': description,
            'reported_by': reportedBy,
            'reported_at': DateTime.now().toIso8601String(),
            'location': location,
            'status': 'open',
            'auto_generated': false,
          })
          .select()
          .single();

      _logger.i('Exception reported: $type');
      return ShipmentException.fromJson(response);
    } catch (e) {
      _logger.e('Error reporting exception: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // CLAIMS (§86-87)
  // --------------------------------------------------------------------------

  Future<Claim?> createClaim({
    required String disputeId,
    required String claimantUserId,
    String? shipmentId,
    String? packageId,
    required String claimType,
    required double amount,
    String currency = 'DZD',
  }) async {
    try {
      final response = await _supabase
          .from('claims')
          .insert({
            'id': const Uuid().v4(),
            'dispute_id': disputeId,
            'claimant_user_id': claimantUserId,
            'shipment_id': shipmentId,
            'package_id': packageId,
            'claim_type': claimType,
            'amount': amount,
            'currency': currency,
            'status': 'submitted',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Claim.fromJson(response);
    } catch (e) {
      _logger.e('Error creating claim: $e');
      rethrow;
    }
  }

  Future<List<Claim>> getUserClaims(String userId) async {
    try {
      final response = await _supabase
          .from('claims')
          .select()
          .eq('claimant_user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Claim.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting user claims: $e');
      return [];
    }
  }

  Future<List<Claim>> getOpenClaims() async {
    try {
      final response = await _supabase
          .from('claims')
          .select()
          .inFilter('status', ['submitted', 'under_review'])
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Claim.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting open claims: $e');
      return [];
    }
  }

  Future<ClaimDocument?> addClaimDocument({
    required String claimId,
    required String url,
    String? docType,
  }) async {
    try {
      final response = await _supabase
          .from('claim_documents')
          .insert({
            'id': const Uuid().v4(),
            'claim_id': claimId,
            'url': url,
            'doc_type': docType,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return ClaimDocument.fromJson(response);
    } catch (e) {
      _logger.e('Error adding claim document: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // CHAIN INTEGRITY (§31bis, §53bis)
  // --------------------------------------------------------------------------

  /// Vérifie la continuité des chain_hash des transferts d'un package.
  /// Retourne les transferts dont le hash casse la chaîne.
  Future<List<CustodyTransfer>> verifyChainIntegrity(
    String shipmentId, {
    String? packageId,
  }) async {
    try {
      final transfers = await getShipmentTransfers(shipmentId);
      final broken = <CustodyTransfer>[];
      String? prevHash;

      for (final t in transfers) {
        if (packageId != null &&
            t.qrTokenId != packageId &&
            t.notes != null &&
            !t.notes!.contains(packageId)) {
          continue;
        }
        if (prevHash != null && t.chainHash != null && !t.chainHash!.contains(prevHash)) {
          broken.add(t);
        }
        if (t.chainHash != null) {
          prevHash = t.chainHash;
        }
      }
      return broken;
    } catch (e) {
      _logger.e('Error verifying chain integrity: $e');
      return [];
    }
  }
}
