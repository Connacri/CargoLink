// ============================================================================
// V2 MODELS — Réseau logistique multi-shipper (CARGOLINK_V2_AMELIORE.md)
// ============================================================================

// ----------------------------------------------------------------------------
// TRIP (§14) — Offre de capacité d'un Shipper
// ----------------------------------------------------------------------------

class Trip {
  final String id;
  final String shipperId;
  final String origin;
  final String destination;
  final String? originLocation;
  final String? destinationLocation;
  final DateTime? departureAt;
  final DateTime? estimatedArrivalAt;
  final double capacityKg;
  final double reservedKg;
  final double availableKg;
  final double pricePerKg;
  final String? flightNumber;
  final String status; // active, in_progress, completed, cancelled
  final DateTime createdAt;
  final DateTime updatedAt;

  Trip({
    required this.id,
    required this.shipperId,
    required this.origin,
    required this.destination,
    this.originLocation,
    this.destinationLocation,
    this.departureAt,
    this.estimatedArrivalAt,
    required this.capacityKg,
    required this.reservedKg,
    required this.availableKg,
    required this.pricePerKg,
    this.flightNumber,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      shipperId: json['shipper_id'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      originLocation: json['origin_location'] as String?,
      destinationLocation: json['destination_location'] as String?,
      departureAt: json['departure_at'] != null
          ? DateTime.tryParse(json['departure_at'] as String)
          : null,
      estimatedArrivalAt: json['estimated_arrival_at'] != null
          ? DateTime.tryParse(json['estimated_arrival_at'] as String)
          : null,
      capacityKg: (json['capacity_kg'] as num).toDouble(),
      reservedKg: (json['reserved_kg'] as num? ?? 0).toDouble(),
      availableKg: (json['available_kg'] as num? ?? 0).toDouble(),
      pricePerKg: (json['price_per_kg'] as num).toDouble(),
      flightNumber: json['flight_number'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipper_id': shipperId,
      'origin': origin,
      'destination': destination,
      'origin_location': originLocation,
      'destination_location': destinationLocation,
      'departure_at': departureAt?.toIso8601String(),
      'estimated_arrival_at': estimatedArrivalAt?.toIso8601String(),
      'capacity_kg': capacityKg,
      'reserved_kg': reservedKg,
      'available_kg': availableKg,
      'price_per_kg': pricePerKg,
      'flight_number': flightNumber,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double get remainingKg => availableKg - reservedKg;
  bool get isFull => remainingKg <= 0;
}

// ----------------------------------------------------------------------------
// SHIPMENT PACKAGE (§13) — Unité physique traçable
// ----------------------------------------------------------------------------

class ShipmentPackage {
  final String id;
  final String shipmentId;
  final String? trackingCode; // CLX-YYYY-NNNNNN-NN
  final int packageNumber;
  final double weight;
  final double? declaredValue;
  final String? description;
  final bool isDivisible; // verrouillé après premier handover
  final String? packageFingerprint;
  final String status;
  final String? currentCustodianId;
  final String? currentLegId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShipmentPackage({
    required this.id,
    required this.shipmentId,
    this.trackingCode,
    required this.packageNumber,
    required this.weight,
    this.declaredValue,
    this.description,
    this.isDivisible = false,
    this.packageFingerprint,
    required this.status,
    this.currentCustodianId,
    this.currentLegId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShipmentPackage.fromJson(Map<String, dynamic> json) {
    return ShipmentPackage(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String,
      trackingCode: json['tracking_code'] as String?,
      packageNumber: json['package_number'] as int,
      weight: (json['weight'] as num).toDouble(),
      declaredValue: (json['declared_value'] as num?)?.toDouble(),
      description: json['description'] as String?,
      isDivisible: json['is_divisible'] as bool? ?? false,
      packageFingerprint: json['package_fingerprint'] as String?,
      status: json['status'] as String,
      currentCustodianId: json['current_custodian_id'] as String?,
      currentLegId: json['current_leg_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'tracking_code': trackingCode,
      'package_number': packageNumber,
      'weight': weight,
      'declared_value': declaredValue,
      'description': description,
      'is_divisible': isDivisible,
      'package_fingerprint': packageFingerprint,
      'status': status,
      'current_custodian_id': currentCustodianId,
      'current_leg_id': currentLegId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// ----------------------------------------------------------------------------
// SHIPMENT LEG (§16) — Portion du trajet sous un seul Shipper
// ----------------------------------------------------------------------------

class ShipmentLeg {
  final String id;
  final String shipmentId;
  final String? tripId;
  final String shipperId;
  final String? fromLocation;
  final String? toLocation;
  final DateTime? plannedDeparture;
  final DateTime? plannedArrival;
  final DateTime? actualDeparture;
  final DateTime? actualArrival;
  final double allocatedWeight;
  final String status; // planned, active, in_transit, completed, cancelled, exception
  final int sequenceNumber;
  final String? parentLegId; // arbres de split/merge
  final DateTime createdAt;
  final DateTime updatedAt;

  ShipmentLeg({
    required this.id,
    required this.shipmentId,
    this.tripId,
    required this.shipperId,
    this.fromLocation,
    this.toLocation,
    this.plannedDeparture,
    this.plannedArrival,
    this.actualDeparture,
    this.actualArrival,
    required this.allocatedWeight,
    required this.status,
    required this.sequenceNumber,
    this.parentLegId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShipmentLeg.fromJson(Map<String, dynamic> json) {
    return ShipmentLeg(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String,
      tripId: json['trip_id'] as String?,
      shipperId: json['shipper_id'] as String,
      fromLocation: json['from_location'] as String?,
      toLocation: json['to_location'] as String?,
      plannedDeparture: json['planned_departure'] != null
          ? DateTime.tryParse(json['planned_departure'] as String)
          : null,
      plannedArrival: json['planned_arrival'] != null
          ? DateTime.tryParse(json['planned_arrival'] as String)
          : null,
      actualDeparture: json['actual_departure'] != null
          ? DateTime.tryParse(json['actual_departure'] as String)
          : null,
      actualArrival: json['actual_arrival'] != null
          ? DateTime.tryParse(json['actual_arrival'] as String)
          : null,
      allocatedWeight: (json['allocated_weight'] as num).toDouble(),
      status: json['status'] as String,
      sequenceNumber: json['sequence_number'] as int,
      parentLegId: json['parent_leg_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'trip_id': tripId,
      'shipper_id': shipperId,
      'from_location': fromLocation,
      'to_location': toLocation,
      'planned_departure': plannedDeparture?.toIso8601String(),
      'planned_arrival': plannedArrival?.toIso8601String(),
      'actual_departure': actualDeparture?.toIso8601String(),
      'actual_arrival': actualArrival?.toIso8601String(),
      'allocated_weight': allocatedWeight,
      'status': status,
      'sequence_number': sequenceNumber,
      'parent_leg_id': parentLegId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isCompleted => status == 'completed';
}

// ----------------------------------------------------------------------------
// CUSTODY TRANSFER (§17) — Historique de possession vérifiable
// ----------------------------------------------------------------------------

class CustodyTransfer {
  final String id;
  final String shipmentId;
  final String fromUserId;
  final String toUserId;
  final String? fromLegId;
  final String? toLegId;
  final String transferType; // FULL | PARTIAL | PACKAGE | MERGE | SPLIT
  final double totalWeight;
  final String status; // requested, accepted, completed, declined, cancelled
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final double? latitude;
  final double? longitude;
  final String? verificationMethod; // QR, OTP, QR+OTP, GPS, SIGNATURE, PHOTO
  final String? qrTokenId;
  final String? otpId;
  final String? chainHash;
  final String? signatureFrom;
  final String? signatureTo;
  final String? idempotencyKey;
  final String? notes;
  final DateTime createdAt;

  CustodyTransfer({
    required this.id,
    required this.shipmentId,
    required this.fromUserId,
    required this.toUserId,
    this.fromLegId,
    this.toLegId,
    required this.transferType,
    required this.totalWeight,
    required this.status,
    required this.requestedAt,
    this.acceptedAt,
    this.completedAt,
    this.latitude,
    this.longitude,
    this.verificationMethod,
    this.qrTokenId,
    this.otpId,
    this.chainHash,
    this.signatureFrom,
    this.signatureTo,
    this.idempotencyKey,
    this.notes,
    required this.createdAt,
  });

  factory CustodyTransfer.fromJson(Map<String, dynamic> json) {
    return CustodyTransfer(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      fromLegId: json['from_leg_id'] as String?,
      toLegId: json['to_leg_id'] as String?,
      transferType: json['transfer_type'] as String,
      totalWeight: (json['total_weight'] as num).toDouble(),
      status: json['status'] as String,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      verificationMethod: json['verification_method'] as String?,
      qrTokenId: json['qr_token_id'] as String?,
      otpId: json['otp_id'] as String?,
      chainHash: json['chain_hash'] as String?,
      signatureFrom: json['signature_from'] as String?,
      signatureTo: json['signature_to'] as String?,
      idempotencyKey: json['idempotency_key'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'from_leg_id': fromLegId,
      'to_leg_id': toLegId,
      'transfer_type': transferType,
      'total_weight': totalWeight,
      'status': status,
      'requested_at': requestedAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'verification_method': verificationMethod,
      'qr_token_id': qrTokenId,
      'otp_id': otpId,
      'chain_hash': chainHash,
      'signature_from': signatureFrom,
      'signature_to': signatureTo,
      'idempotency_key': idempotencyKey,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isCompletedTransfer => status == 'completed';
}

// ----------------------------------------------------------------------------
// SHIPMENT EVENT (§18) — Vérité historique append-only
// ----------------------------------------------------------------------------

class ShipmentEvent {
  final String id;
  final String shipmentId;
  final String? packageId;
  final String? legId;
  final String eventType;
  final String? actorId;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final String? proofId;
  final DateTime? expectedBy; // SLA §21bis

  ShipmentEvent({
    required this.id,
    required this.shipmentId,
    this.packageId,
    this.legId,
    required this.eventType,
    this.actorId,
    this.latitude,
    this.longitude,
    this.accuracy,
    required this.createdAt,
    this.metadata,
    this.proofId,
    this.expectedBy,
  });

  factory ShipmentEvent.fromJson(Map<String, dynamic> json) {
    return ShipmentEvent(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String,
      packageId: json['package_id'] as String?,
      legId: json['leg_id'] as String?,
      eventType: json['event_type'] as String,
      actorId: json['actor_id'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      proofId: json['proof_id'] as String?,
      expectedBy: json['expected_by'] != null
          ? DateTime.tryParse(json['expected_by'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'package_id': packageId,
      'leg_id': legId,
      'event_type': eventType,
      'actor_id': actorId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
      'proof_id': proofId,
      'expected_by': expectedBy?.toIso8601String(),
    };
  }
}

// ----------------------------------------------------------------------------
// TRACKING POINT (§40-41) — Preuve de localisation physique
// ----------------------------------------------------------------------------

class TrackingPoint {
  final String id;
  final String? shipmentId;
  final String? packageId;
  final String? legId;
  final String? shipperId;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final DateTime createdAt;

  TrackingPoint({
    required this.id,
    this.shipmentId,
    this.packageId,
    this.legId,
    this.shipperId,
    this.latitude,
    this.longitude,
    this.accuracy,
    required this.createdAt,
  });

  factory TrackingPoint.fromJson(Map<String, dynamic> json) {
    return TrackingPoint(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String?,
      packageId: json['package_id'] as String?,
      legId: json['leg_id'] as String?,
      shipperId: json['shipper_id'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'package_id': packageId,
      'leg_id': legId,
      'shipper_id': shipperId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ----------------------------------------------------------------------------
// SHIPMENT PROOF (§105) — Preuve opérationnelle combinée
// ----------------------------------------------------------------------------

class ShipmentProof {
  final String id;
  final String? shipmentId;
  final String? packageId;
  final String? transferId;
  final String? eventId;
  final String proofType; // PHOTO, OTP, QR, SIGNATURE, GPS, DOCUMENT
  final String? reference;
  final String? url;
  final DateTime createdAt;

  ShipmentProof({
    required this.id,
    this.shipmentId,
    this.packageId,
    this.transferId,
    this.eventId,
    required this.proofType,
    this.reference,
    this.url,
    required this.createdAt,
  });

  factory ShipmentProof.fromJson(Map<String, dynamic> json) {
    return ShipmentProof(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String?,
      packageId: json['package_id'] as String?,
      transferId: json['transfer_id'] as String?,
      eventId: json['event_id'] as String?,
      proofType: json['proof_type'] as String,
      reference: json['reference'] as String?,
      url: json['url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'package_id': packageId,
      'transfer_id': transferId,
      'event_id': eventId,
      'proof_type': proofType,
      'reference': reference,
      'url': url,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ----------------------------------------------------------------------------
// PAYMENT ALLOCATION (§56bis) — Payout scindé par allocation
// ----------------------------------------------------------------------------

class PaymentAllocation {
  final String id;
  final String? shipmentId;
  final String? legId;
  final String? bookingId;
  final String? shipperId;
  final double amount;
  final String status; // pending, released, frozen, refunded
  final String? payoutStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentAllocation({
    required this.id,
    this.shipmentId,
    this.legId,
    this.bookingId,
    this.shipperId,
    required this.amount,
    required this.status,
    this.payoutStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentAllocation.fromJson(Map<String, dynamic> json) {
    return PaymentAllocation(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String?,
      legId: json['leg_id'] as String?,
      bookingId: json['booking_id'] as String?,
      shipperId: json['shipper_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      payoutStatus: json['payout_status'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'leg_id': legId,
      'booking_id': bookingId,
      'shipper_id': shipperId,
      'amount': amount,
      'status': status,
      'payout_status': payoutStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isFrozen => status == 'frozen' || payoutStatus == 'frozen';
}

// ----------------------------------------------------------------------------
// PAYOUT (§58)
// ----------------------------------------------------------------------------

class Payout {
  final String id;
  final String? allocationId;
  final String? shipperId;
  final double amount;
  final double? platformFee;
  final String status; // pending, released, frozen, paid, failed
  final DateTime? releasedAt;
  final DateTime createdAt;

  Payout({
    required this.id,
    this.allocationId,
    this.shipperId,
    required this.amount,
    this.platformFee,
    required this.status,
    this.releasedAt,
    required this.createdAt,
  });

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: json['id'] as String,
      allocationId: json['allocation_id'] as String?,
      shipperId: json['shipper_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      platformFee: (json['platform_fee'] as num?)?.toDouble(),
      status: json['status'] as String,
      releasedAt: json['released_at'] != null
          ? DateTime.tryParse(json['released_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'allocation_id': allocationId,
      'shipper_id': shipperId,
      'amount': amount,
      'platform_fee': platformFee,
      'status': status,
      'released_at': releasedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ----------------------------------------------------------------------------
// SHIPMENT EXCEPTION (§61-62) — Incidents, jamais mélangés aux jalons
// ----------------------------------------------------------------------------

class ShipmentException {
  final String id;
  final String? shipmentId;
  final String? packageId;
  final String? legId;
  final String type; // SHIPPER_DELAY, MISSED_FLIGHT, ... SLA_BREACH
  final String severity; // INFO, WARNING, CRITICAL
  final String? description;
  final String? reportedBy;
  final DateTime reportedAt;
  final String? location;
  final String status; // open, resolved, escalated
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolution;
  final bool autoGenerated; // SLA §21bis vs humain

  ShipmentException({
    required this.id,
    this.shipmentId,
    this.packageId,
    this.legId,
    required this.type,
    required this.severity,
    this.description,
    this.reportedBy,
    required this.reportedAt,
    this.location,
    required this.status,
    this.resolvedAt,
    this.resolvedBy,
    this.resolution,
    this.autoGenerated = false,
  });

  factory ShipmentException.fromJson(Map<String, dynamic> json) {
    return ShipmentException(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String?,
      packageId: json['package_id'] as String?,
      legId: json['leg_id'] as String?,
      type: json['type'] as String,
      severity: json['severity'] as String,
      description: json['description'] as String?,
      reportedBy: json['reported_by'] as String?,
      reportedAt: DateTime.parse(json['reported_at'] as String),
      location: json['location'] as String?,
      status: json['status'] as String,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'] as String)
          : null,
      resolvedBy: json['resolved_by'] as String?,
      resolution: json['resolution'] as String?,
      autoGenerated: json['auto_generated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'package_id': packageId,
      'leg_id': legId,
      'type': type,
      'severity': severity,
      'description': description,
      'reported_by': reportedBy,
      'reported_at': reportedAt.toIso8601String(),
      'location': location,
      'status': status,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
      'resolution': resolution,
      'auto_generated': autoGenerated,
    };
  }
}

// ----------------------------------------------------------------------------
// CLAIM (§86) — Demande formelle d'indemnisation
// ----------------------------------------------------------------------------

class Claim {
  final String id;
  final String disputeId;
  final String claimantUserId;
  final String? shipmentId;
  final String? packageId;
  final String claimType; // refund, compensation, other
  final double amount;
  final String currency;
  final String status; // submitted, under_review, approved, rejected, paid
  final String? decision;
  final String? decidedBy;
  final DateTime? decidedAt;
  final DateTime createdAt;

  Claim({
    required this.id,
    required this.disputeId,
    required this.claimantUserId,
    this.shipmentId,
    this.packageId,
    required this.claimType,
    required this.amount,
    this.currency = 'DZD',
    required this.status,
    this.decision,
    this.decidedBy,
    this.decidedAt,
    required this.createdAt,
  });

  factory Claim.fromJson(Map<String, dynamic> json) {
    return Claim(
      id: json['id'] as String,
      disputeId: json['dispute_id'] as String,
      claimantUserId: json['claimant_user_id'] as String,
      shipmentId: json['shipment_id'] as String?,
      packageId: json['package_id'] as String?,
      claimType: json['claim_type'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'DZD',
      status: json['status'] as String,
      decision: json['decision'] as String?,
      decidedBy: json['decided_by'] as String?,
      decidedAt: json['decided_at'] != null
          ? DateTime.tryParse(json['decided_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dispute_id': disputeId,
      'claimant_user_id': claimantUserId,
      'shipment_id': shipmentId,
      'package_id': packageId,
      'claim_type': claimType,
      'amount': amount,
      'currency': currency,
      'status': status,
      'decision': decision,
      'decided_by': decidedBy,
      'decided_at': decidedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ----------------------------------------------------------------------------
// CLAIM DOCUMENT (§87)
// ----------------------------------------------------------------------------

class ClaimDocument {
  final String id;
  final String claimId;
  final String? url;
  final String? docType;
  final DateTime createdAt;

  ClaimDocument({
    required this.id,
    required this.claimId,
    this.url,
    this.docType,
    required this.createdAt,
  });

  factory ClaimDocument.fromJson(Map<String, dynamic> json) {
    return ClaimDocument(
      id: json['id'] as String,
      claimId: json['claim_id'] as String,
      url: json['url'] as String?,
      docType: json['doc_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'claim_id': claimId,
      'url': url,
      'doc_type': docType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
