// ============================================================================
// DELIVERY REQUEST MODELS (Demande de Livraison)
// ============================================================================

enum DeliveryRequestStatus {
  open,
  accepted,
  confirmed,
  paid,
  inTransit,
  delivered,
  cancelled,
  disputed;

  factory DeliveryRequestStatus.fromString(String value) {
    return DeliveryRequestStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DeliveryRequestStatus.open,
    );
  }

  String get label {
    switch (this) {
      case DeliveryRequestStatus.open:
        return 'Ouverte';
      case DeliveryRequestStatus.accepted:
        return 'Acceptée';
      case DeliveryRequestStatus.confirmed:
        return 'Confirmée';
      case DeliveryRequestStatus.paid:
        return 'Payée';
      case DeliveryRequestStatus.inTransit:
        return 'En transit';
      case DeliveryRequestStatus.delivered:
        return 'Livrée';
      case DeliveryRequestStatus.cancelled:
        return 'Annulée';
      case DeliveryRequestStatus.disputed:
        return 'En litige';
    }
  }
}

enum DeliveryResponseStatus {
  pending,
  accepted,
  rejected,
  expired;

  factory DeliveryResponseStatus.fromString(String value) {
    return DeliveryResponseStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DeliveryResponseStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case DeliveryResponseStatus.pending:
        return 'En attente';
      case DeliveryResponseStatus.accepted:
        return 'Acceptée';
      case DeliveryResponseStatus.rejected:
        return 'Refusée';
      case DeliveryResponseStatus.expired:
        return 'Expirée';
    }
  }
}

class DeliveryRequest {
  final String id;
  final String clientId;
  final String productName;
  final String? productDescription;
  final List<String>? productPhotosUrl;
  final String originCountry;
  final String destinationCity;
  final double requestedWeightKg;
  final DateTime deadline;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeliveryRequest({
    required this.id,
    required this.clientId,
    required this.productName,
    this.productDescription,
    this.productPhotosUrl,
    required this.originCountry,
    required this.destinationCity,
    required this.requestedWeightKg,
    required this.deadline,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryRequest.fromJson(Map<String, dynamic> json) {
    return DeliveryRequest(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      productName: json['product_name'] as String,
      productDescription: json['product_description'] as String?,
      productPhotosUrl: (json['product_photos_url'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      originCountry: json['origin_country'] as String,
      destinationCity: json['destination_city'] as String,
      requestedWeightKg: (json['requested_weight_kg'] as num).toDouble(),
      deadline: DateTime.parse(json['deadline'] as String),
      status: json['status'] as String? ?? 'open',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'product_name': productName,
      'product_description': productDescription,
      'product_photos_url': productPhotosUrl,
      'origin_country': originCountry,
      'destination_city': destinationCity,
      'requested_weight_kg': requestedWeightKg,
      'deadline': deadline.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DeliveryRequestStatus get statusEnum =>
      DeliveryRequestStatus.fromString(status);

  bool get isOpen => status == 'open';
  bool get isActive =>
      status != 'cancelled' && status != 'delivered' && status != 'disputed';
}

// ============================================================================
// DELIVERY RESPONSE MODEL (Proposition d'expéditeur)
// ============================================================================

class DeliveryResponse {
  final String id;
  final String requestId;
  final String shipperId;
  final double proposedPrice;
  final DateTime proposedDate;
  final String? message;
  final String status;
  final DateTime createdAt;

  DeliveryResponse({
    required this.id,
    required this.requestId,
    required this.shipperId,
    required this.proposedPrice,
    required this.proposedDate,
    this.message,
    required this.status,
    required this.createdAt,
  });

  factory DeliveryResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryResponse(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      shipperId: json['shipper_id'] as String,
      proposedPrice: (json['proposed_price'] as num).toDouble(),
      proposedDate: DateTime.parse(json['proposed_date'] as String),
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'shipper_id': shipperId,
      'proposed_price': proposedPrice,
      'proposed_date': proposedDate.toIso8601String(),
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  DeliveryResponseStatus get statusEnum =>
      DeliveryResponseStatus.fromString(status);

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
}

// ============================================================================
// DELIVERY GUARANTEE MODEL (Vérification face-à-face)
// ============================================================================

class DeliveryGuarantee {
  final String id;
  final String requestId;
  final String? clientPassportUrl;
  final String? clientSelfieUrl;
  final String? shipperPassportUrl;
  final String? shipperSelfieUrl;
  final bool faceToFaceConfirmed;
  final DateTime? confirmedAt;
  final DateTime createdAt;

  DeliveryGuarantee({
    required this.id,
    required this.requestId,
    this.clientPassportUrl,
    this.clientSelfieUrl,
    this.shipperPassportUrl,
    this.shipperSelfieUrl,
    this.faceToFaceConfirmed = false,
    this.confirmedAt,
    required this.createdAt,
  });

  factory DeliveryGuarantee.fromJson(Map<String, dynamic> json) {
    return DeliveryGuarantee(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      clientPassportUrl: json['client_passport_url'] as String?,
      clientSelfieUrl: json['client_selfie_url'] as String?,
      shipperPassportUrl: json['shipper_passport_url'] as String?,
      shipperSelfieUrl: json['shipper_selfie_url'] as String?,
      faceToFaceConfirmed: json['face_to_face_confirmed'] as bool? ?? false,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.tryParse(json['confirmed_at'] as String)
          : null,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'client_passport_url': clientPassportUrl,
      'client_selfie_url': clientSelfieUrl,
      'shipper_passport_url': shipperPassportUrl,
      'shipper_selfie_url': shipperSelfieUrl,
      'face_to_face_confirmed': faceToFaceConfirmed,
      'confirmed_at': confirmedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isConfirmed => faceToFaceConfirmed;

  bool get isComplete =>
      clientPassportUrl != null &&
      clientSelfieUrl != null &&
      shipperPassportUrl != null &&
      shipperSelfieUrl != null;
}

// ============================================================================
// DELIVERY SUBSCRIPTION MODEL
// ============================================================================

class DeliverySubscription {
  final String id;
  final String userId;
  final String role;
  final double price;
  final String currency;
  final String status;
  final DateTime startsAt;
  final DateTime expiresAt;
  final DateTime createdAt;

  DeliverySubscription({
    required this.id,
    required this.userId,
    required this.role,
    required this.price,
    this.currency = 'DZD',
    required this.status,
    required this.startsAt,
    required this.expiresAt,
    required this.createdAt,
  });

  factory DeliverySubscription.fromJson(Map<String, dynamic> json) {
    return DeliverySubscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'DZD',
      status: json['status'] as String? ?? 'active',
      startsAt: DateTime.tryParse(json['starts_at'] as String? ?? '') ?? DateTime.now(),
      expiresAt:
          DateTime.tryParse(json['expires_at'] as String? ?? '') ?? DateTime.now(),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'role': role,
      'price': price,
      'currency': currency,
      'status': status,
      'starts_at': startsAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'active' && expiresAt.isAfter(DateTime.now());
  bool get isExpired => status == 'expired' || expiresAt.isBefore(DateTime.now());
  bool get isCancelled => status == 'cancelled';
}
