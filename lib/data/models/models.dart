// ============================================================================
// USER MODEL
// ============================================================================

class User {
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final String? profilePictureUrl;
  final String role; // client, shipper, admin, super_admin
  final String? wechat;
  final String? whatsapp;
  final String? telegram;
  final String? facebook;
  final String? instagram;
  final String? tiktok;
  final bool isActive;
  final DateTime? deactivatedAt;
  final DateTime? deletionRequestedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    this.profilePictureUrl,
    required this.role,
    this.wechat,
    this.whatsapp,
    this.telegram,
    this.facebook,
    this.instagram,
    this.tiktok,
    this.isActive = true,
    this.deactivatedAt,
    this.deletionRequestedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      fullName: json['full_name'] as String,
      profilePictureUrl: json['profile_picture_url'] as String?,
      role: json['role'] as String,
      wechat: json['wechat'] as String?,
      whatsapp: json['whatsapp'] as String?,
      telegram: json['telegram'] as String?,
      facebook: json['facebook'] as String?,
      instagram: json['instagram'] as String?,
      tiktok: json['tiktok'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      deactivatedAt: json['deactivated_at'] != null
          ? DateTime.tryParse(json['deactivated_at'] as String)
          : null,
      deletionRequestedAt: json['deletion_requested_at'] != null
          ? DateTime.tryParse(json['deletion_requested_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'full_name': fullName,
      'profile_picture_url': profilePictureUrl,
      'role': role,
      'wechat': wechat,
      'whatsapp': whatsapp,
      'telegram': telegram,
      'facebook': facebook,
      'instagram': instagram,
      'tiktok': tiktok,
      'is_active': isActive,
      'deactivated_at': deactivatedAt?.toIso8601String(),
      'deletion_requested_at': deletionRequestedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    String? profilePictureUrl,
    String? role,
    String? wechat,
    String? whatsapp,
    String? telegram,
    String? facebook,
    String? instagram,
    String? tiktok,
    bool? isActive,
    DateTime? deactivatedAt,
    DateTime? deletionRequestedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      role: role ?? this.role,
      wechat: wechat ?? this.wechat,
      whatsapp: whatsapp ?? this.whatsapp,
      telegram: telegram ?? this.telegram,
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      tiktok: tiktok ?? this.tiktok,
      isActive: isActive ?? this.isActive,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      deletionRequestedAt: deletionRequestedAt ?? this.deletionRequestedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================================================
// SHIPPER MODEL (Micro-importateur)
// ============================================================================

class Shipper {
  final String id;
  final String userId;
  final String passportNumber;
  final String passportPhotoUrl;
  final String livePhotoUrl;
  final String verificationStatus; // pending, verified, rejected
  final String shipperType; // voyageur_ordinaire, micro_importateur
  final String? microCardPhotoUrl;
  final String? rejectionReason;
  final String? verifiedByAdminId;
  final DateTime? verifiedAt;
  final double rating; // 0-5
  final int totalShipments;
  final DateTime createdAt;
  final User? user; // Related user object
  final List<String> savedAddresses;

  Shipper({
    required this.id,
    required this.userId,
    required this.passportNumber,
    required this.passportPhotoUrl,
    required this.livePhotoUrl,
    required this.verificationStatus,
    this.shipperType = 'voyageur_ordinaire',
    this.microCardPhotoUrl,
    this.rejectionReason,
    this.verifiedByAdminId,
    this.verifiedAt,
    this.rating = 0.0,
    this.totalShipments = 0,
    required this.createdAt,
    this.user,
    this.savedAddresses = const [],
  });

  factory Shipper.fromJson(Map<String, dynamic> json) {
    return Shipper(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      passportNumber: json['passport_number'] as String,
      passportPhotoUrl: json['passport_photo_url'] as String,
      livePhotoUrl: json['live_photo_url'] as String,
      verificationStatus: json['verification_status'] as String,
      shipperType: json['shipper_type'] as String? ?? 'voyageur_ordinaire',
      microCardPhotoUrl: json['micro_card_photo_url'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      verifiedByAdminId: json['verified_by_admin_id'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalShipments: json['total_shipments'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: json['users'] != null ? User.fromJson(json['users']) : null,
      savedAddresses: (json['saved_addresses'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'passport_number': passportNumber,
      'passport_photo_url': passportPhotoUrl,
      'live_photo_url': livePhotoUrl,
      'verification_status': verificationStatus,
      'shipper_type': shipperType,
      'micro_card_photo_url': microCardPhotoUrl,
      'rejection_reason': rejectionReason,
      'verified_by_admin_id': verifiedByAdminId,
      'verified_at': verifiedAt?.toIso8601String(),
      'rating': rating,
      'total_shipments': totalShipments,
      'created_at': createdAt.toIso8601String(),
      'saved_addresses': savedAddresses,
    };
  }

  bool get isVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';
  bool get isMicroImportateur => shipperType == 'micro_importateur';

  String get ratingDisplay => rating.toStringAsFixed(1);
}

// ============================================================================
// SHIPMENT MODEL (Offre de transport)
// ============================================================================

class Shipment {
  final String id;
  final String shipperId;
  final String? trackingNumber;
  final int maxHopCount;
  final String originCountry;
  final String destinationCity;
  final double availableWeightKg;
  final double reservedWeightKg;
  final double pricePerKg;
  final DateTime departureDate;
  final DateTime arrivalDate;
  final String? airline;
  final String? flightNumber;
  final String status; // active, completed, cancelled
  final String? description;
  final double? publicationFee;
  final String publicationFeeStatus; // pending, awaiting_confirmation, paid
  final double publicationFeeDiscount;
  final DateTime? publicationPaidAt;
  final String? collectionAddress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Shipper? shipper; // Related shipper object

  double get remainingWeightKg => availableWeightKg - reservedWeightKg;
  double get utilizationPercent => (reservedWeightKg / availableWeightKg) * 100;
  bool get isFull => remainingWeightKg <= 0;
  bool get isActive =>
      status == 'active' && arrivalDate.isAfter(DateTime.now());
  /// The offer is only visible to clients once its publication fee is paid.
  bool get isPublished => status == 'active' && publicationFeeStatus == 'paid';

  Shipment({
    required this.id,
    required this.shipperId,
    this.trackingNumber,
    this.maxHopCount = 5,
    required this.originCountry,
    required this.destinationCity,
    required this.availableWeightKg,
    required this.reservedWeightKg,
    required this.pricePerKg,
    required this.departureDate,
    required this.arrivalDate,
    this.airline,
    this.flightNumber,
    required this.status,
    this.description,
    this.publicationFee,
    this.publicationFeeStatus = 'pending',
    this.publicationFeeDiscount = 0,
    this.publicationPaidAt,
    this.collectionAddress,
    required this.createdAt,
    required this.updatedAt,
    this.shipper,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      id: json['id'] as String,
      shipperId: json['shipper_id'] as String,
      trackingNumber: json['tracking_number'] as String?,
      maxHopCount: (json['max_hop_count'] as num?)?.toInt() ?? 5,
      originCountry: json['origin_country'] as String,
      destinationCity: json['destination_city'] as String,
      availableWeightKg: (json['available_weight_kg'] as num).toDouble(),
      reservedWeightKg: (json['reserved_weight_kg'] as num? ?? 0).toDouble(),
      pricePerKg: (json['price_per_kg'] as num).toDouble(),
      departureDate: DateTime.parse(json['departure_date'] as String),
      arrivalDate: DateTime.parse(json['arrival_date'] as String),
      airline: json['airline'] as String?,
      flightNumber: json['flight_number'] as String?,
      status: json['status'] as String,
      description: json['description'] as String?,
      publicationFee: (json['publication_fee'] as num?)?.toDouble(),
      publicationFeeStatus:
          json['publication_fee_status'] as String? ?? 'pending',
      publicationFeeDiscount:
          (json['publication_fee_discount'] as num?)?.toDouble() ?? 0,
      publicationPaidAt: json['publication_paid_at'] != null
          ? DateTime.tryParse(json['publication_paid_at'] as String)
          : null,
      collectionAddress: json['collection_address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      shipper:
          json['shippers'] != null ? Shipper.fromJson(json['shippers']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipper_id': shipperId,
      'tracking_number': trackingNumber,
      'max_hop_count': maxHopCount,
      'origin_country': originCountry,
      'destination_city': destinationCity,
      'available_weight_kg': availableWeightKg,
      'reserved_weight_kg': reservedWeightKg,
      'price_per_kg': pricePerKg,
      'departure_date': departureDate.toIso8601String(),
      'arrival_date': arrivalDate.toIso8601String(),
      'airline': airline,
      'flight_number': flightNumber,
      'status': status,
      'description': description,
      'publication_fee': publicationFee,
      'publication_fee_status': publicationFeeStatus,
      'publication_fee_discount': publicationFeeDiscount,
      'publication_paid_at': publicationPaidAt?.toIso8601String(),
      'collection_address': collectionAddress,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// ============================================================================
// BOOKING MODEL (Réservation client)
// ============================================================================

class Booking {
  final String id;
  final String shipmentId;
  final String clientId;
  final String? packageId;
  final String? tripId;
  final String? idempotencyKey;
  final String productName;
  final String productDescription;
  final List<String>? productPhotosUrl;
  final double requestedWeightKg;
  final double allocatedWeightKg;
  final double totalPrice;
  final String status; // pending, confirmed, collected, verifying, accepted, shipped, arrived, out_for_delivery, delivered, cancelled
  final String paymentStatus; // pending, paid, refunded
  final String? trackingNumber;
  final String? deliveryPhotoUrl;
  final String? receiptPhotoUrl;
  final DateTime? receiptConfirmedAt;
  final String? cniPhotoUrl;
  final String? deliveryPhone;
  final String? deliveryAddress;
  final String? refusalReason;
  final String? cancellationReason;
  final String? collectedPhotoUrl;
  final double? verifiedWeightKg;
  final String verificationStatus; // none, awaiting_verification, verifying, accepted, returned, waiting_client_update
  final String? deliveryMethod; // in_person, courier
  final String? courierName;
  final String? courierPhone;
  final String? courierTrackingCode;
  final DateTime? courierDepositedAt;
  final String? pickupScanPhotoUrl;
  final DateTime? pickupConfirmedAt;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Shipment? shipment;
  final User? client;

  Booking({
    required this.id,
    required this.shipmentId,
    required this.clientId,
    this.packageId,
    this.tripId,
    this.idempotencyKey,
    required this.productName,
    required this.productDescription,
    this.productPhotosUrl,
    required this.requestedWeightKg,
    required this.allocatedWeightKg,
    required this.totalPrice,
    required this.status,
    required this.paymentStatus,
    this.trackingNumber,
    this.deliveryPhotoUrl,
    this.receiptPhotoUrl,
    this.receiptConfirmedAt,
    this.cniPhotoUrl,
    this.deliveryPhone,
    this.deliveryAddress,
    this.refusalReason,
    this.cancellationReason,
    this.collectedPhotoUrl,
    this.verifiedWeightKg,
    this.verificationStatus = 'none',
    this.deliveryMethod,
    this.courierName,
    this.courierPhone,
    this.courierTrackingCode,
    this.courierDepositedAt,
    this.pickupScanPhotoUrl,
    this.pickupConfirmedAt,
    this.deliveredAt,
    required this.createdAt,
    required this.updatedAt,
    this.shipment,
    this.client,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String,
      clientId: json['client_id'] as String,
      packageId: json['package_id'] as String?,
      tripId: json['trip_id'] as String?,
      idempotencyKey: json['idempotency_key'] as String?,
      productName: json['product_name'] as String,
      productDescription: json['product_description'] as String,
      productPhotosUrl: (json['product_photos_url'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      requestedWeightKg: (json['requested_weight_kg'] as num).toDouble(),
      allocatedWeightKg: (json['allocated_weight_kg'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'] as String,
      paymentStatus: json['payment_status'] as String,
      trackingNumber: json['tracking_number'] as String?,
      deliveryPhotoUrl: json['delivery_photo_url'] as String?,
      receiptPhotoUrl: json['receipt_photo_url'] as String?,
      receiptConfirmedAt: json['receipt_confirmed_at'] != null
          ? DateTime.tryParse(json['receipt_confirmed_at'] as String)
          : null,
      cniPhotoUrl: json['cni_photo_url'] as String?,
      deliveryPhone: json['delivery_phone'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      refusalReason: json['refusal_reason'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      collectedPhotoUrl: json['collected_photo_url'] as String?,
      verifiedWeightKg: (json['verified_weight_kg'] as num?)?.toDouble(),
      verificationStatus:
          json['verification_status'] as String? ?? 'none',
      deliveryMethod: json['delivery_method'] as String?,
      courierName: json['courier_name'] as String?,
      courierPhone: json['courier_phone'] as String?,
      courierTrackingCode: json['courier_tracking_code'] as String?,
      courierDepositedAt: json['courier_deposited_at'] != null
          ? DateTime.tryParse(json['courier_deposited_at'] as String)
          : null,
      pickupScanPhotoUrl: json['pickup_scan_photo_url'] as String?,
      pickupConfirmedAt: json['pickup_confirmed_at'] != null
          ? DateTime.tryParse(json['pickup_confirmed_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      shipment: json['shipments'] != null
          ? Shipment.fromJson(json['shipments'])
          : null,
      client: json['users'] != null ? User.fromJson(json['users']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'client_id': clientId,
      'package_id': packageId,
      'trip_id': tripId,
      'idempotency_key': idempotencyKey,
      'product_name': productName,
      'product_description': productDescription,
      'product_photos_url': productPhotosUrl,
      'requested_weight_kg': requestedWeightKg,
      'allocated_weight_kg': allocatedWeightKg,
      'total_price': totalPrice,
      'status': status,
      'payment_status': paymentStatus,
      'tracking_number': trackingNumber,
      'delivery_photo_url': deliveryPhotoUrl,
      'receipt_photo_url': receiptPhotoUrl,
      'receipt_confirmed_at': receiptConfirmedAt?.toIso8601String(),
      'cni_photo_url': cniPhotoUrl,
      'delivery_phone': deliveryPhone,
      'delivery_address': deliveryAddress,
      'refusal_reason': refusalReason,
      'cancellation_reason': cancellationReason,
      'collected_photo_url': collectedPhotoUrl,
      'verified_weight_kg': verifiedWeightKg,
      'verification_status': verificationStatus,
      'delivery_method': deliveryMethod,
      'courier_name': courierName,
      'courier_phone': courierPhone,
      'courier_tracking_code': courierTrackingCode,
      'courier_deposited_at': courierDepositedAt?.toIso8601String(),
      'pickup_scan_photo_url': pickupScanPhotoUrl,
      'pickup_confirmed_at': pickupConfirmedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isPaid => paymentStatus == 'paid';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
}

// ============================================================================
// SHIPMENT TRACKING MODEL
// ============================================================================

class ShipmentTracking {
  final String id;
  final String bookingId;
  final double? latitude;
  final double? longitude;
  final String
      status; // order_processed, collected, verified, verification_returned, departed_origin, in_transit, arrived_destination, customs_cleared, out_for_delivery, delivered
  final DateTime timestamp;
  final String? notes;
  final String? location;
  final DateTime? expectedBy;
  final String? chainHash;
  final Map<String, dynamic>? metadata;

  ShipmentTracking({
    required this.id,
    required this.bookingId,
    this.latitude,
    this.longitude,
    required this.status,
    required this.timestamp,
    this.notes,
    this.location,
    this.expectedBy,
    this.chainHash,
    this.metadata,
  });

  factory ShipmentTracking.fromJson(Map<String, dynamic> json) {
    return ShipmentTracking(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String?,
      location: json['location'] as String?,
      expectedBy: json['expected_by'] != null
          ? DateTime.tryParse(json['expected_by'] as String)
          : null,
      chainHash: json['chain_hash'] as String?,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'location': location,
      'expected_by': expectedBy?.toIso8601String(),
      'chain_hash': chainHash,
      'metadata': metadata,
    };
  }
}

// ============================================================================
// DISPUTE MODEL
// ============================================================================

class Dispute {
  final String id;
  final String bookingId;
  final String reportedByUserId;
  final String type; // fraud, customs_seizure, damage, non_delivery, other
  final String description;
  final List<String>? evidencePhotosUrl;
  final String status; // open, investigating, resolved, rejected
  final String? resolution;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final Booking? booking;

  Dispute({
    required this.id,
    required this.bookingId,
    required this.reportedByUserId,
    required this.type,
    required this.description,
    this.evidencePhotosUrl,
    required this.status,
    this.resolution,
    required this.createdAt,
    this.resolvedAt,
    this.booking,
  });

  factory Dispute.fromJson(Map<String, dynamic> json) {
    return Dispute(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      reportedByUserId: json['reported_by_user_id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      evidencePhotosUrl: (json['evidence_photos_url'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      status: json['status'] as String,
      resolution: json['resolution'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      booking:
          json['bookings'] != null ? Booking.fromJson(json['bookings']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'reported_by_user_id': reportedByUserId,
      'type': type,
      'description': description,
      'evidence_photos_url': evidencePhotosUrl,
      'status': status,
      'resolution': resolution,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  bool get isOpen => status == 'open';
  bool get isResolved => status == 'resolved';
}

// ============================================================================
// NOTIFICATION MODEL
// ============================================================================

class Notification {
  final String id;
  final String userId;
  final String type; // booking_confirmed, shipment_dispatched, etc.
  final String title;
  final String message;
  final String? relatedBookingId;
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedBookingId,
    this.isRead = false,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      relatedBookingId: json['related_booking_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'related_booking_id': relatedBookingId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ============================================================================
// PAYMENT MODEL
// ============================================================================

class Payment {
  final String id;
  final String bookingId;
  final double amount;
  final String currency;
  final String status; // pending, completed, failed, refunded
  final String? paymentMethod;
  final String? transactionId;
  final double discountPercent; // remise Visa (-30% dus plateforme)
  final double? originalAmount;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.bookingId,
    required this.amount,
    this.currency = 'DZD',
    required this.status,
    this.paymentMethod,
    this.transactionId,
    this.discountPercent = 0,
    this.originalAmount,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'DZD',
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String?,
      transactionId: json['transaction_id'] as String?,
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0,
      originalAmount: (json['original_amount'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'discount_percent': discountPercent,
      'original_amount': originalAmount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
}

// ============================================================================
// TRANSACTION ITEM MODEL (Paiement enrichi pour la comptabilité)
// ============================================================================

class TransactionItem {
  final Payment payment;
  final String? shipmentRoute;
  final String? clientId;
  final String? clientName;
  final String? clientAvatar;
  final String? shipperUserId;
  final String? shipperName;
  final String? shipperAvatar;
  final String? productName;

  TransactionItem({
    required this.payment,
    this.shipmentRoute,
    this.clientId,
    this.clientName,
    this.clientAvatar,
    this.shipperUserId,
    this.shipperName,
    this.shipperAvatar,
    this.productName,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    final booking = json['bookings'] as Map<String, dynamic>?;
    final shipment = booking?['shipments'] as Map<String, dynamic>?;
    final shipper = shipment?['shippers'] as Map<String, dynamic>?;
    final shipperUser = shipper?['users'] as Map<String, dynamic>?;
    final client = booking?['users'] as Map<String, dynamic>?;

    return TransactionItem(
      payment: Payment.fromJson(json),
      shipmentRoute: (shipment?['origin_country'] != null &&
              shipment?['destination_city'] != null)
          ? '${shipment!['origin_country']} → ${shipment['destination_city']}'
          : null,
      clientId: client?['id'] as String?,
      clientName: client?['full_name'] as String?,
      clientAvatar: client?['profile_picture_url'] as String?,
      shipperUserId: shipperUser?['id'] as String?,
      shipperName: shipperUser?['full_name'] as String?,
      shipperAvatar: shipperUser?['profile_picture_url'] as String?,
      productName: booking?['product_name'] as String?,
    );
  }
}

// ============================================================================
// PLATFORM FEE MODEL (Commission plateforme / dette expéditeur)
// ============================================================================

class PlatformFee {
  final String id;
  final String? bookingId; // null pour les frais de publication
  final String shipmentId;
  final String shipperId;
  final double amount;
  final String currency; // DZD, EUR, USD, RMB, ...
  final String type; // commission, publication
  final String status; // pending, awaiting_confirmation, paid
  final DateTime? paidAt;
  final DateTime? dueAt; // échéance (délai de 7 jours)
  final String? paymentMethod; // visa, baridimob, cash
  final String escalationStatus; // none, overdue, justice_filed
  final DateTime createdAt;
  final DateTime updatedAt;
  final Shipment? shipment; // Related shipment (route + shipper) for admin lists

  PlatformFee({
    required this.id,
    this.bookingId,
    required this.shipmentId,
    required this.shipperId,
    required this.amount,
    this.currency = 'DZD',
    this.type = 'commission',
    required this.status,
    this.paidAt,
    this.dueAt,
    this.paymentMethod,
    this.escalationStatus = 'none',
    required this.createdAt,
    required this.updatedAt,
    this.shipment,
  });

  factory PlatformFee.fromJson(Map<String, dynamic> json) {
    return PlatformFee(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String?,
      shipmentId: json['shipment_id'] as String,
      shipperId: json['shipper_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'DZD',
      type: json['type'] as String? ?? 'commission',
      status: json['status'] as String,
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'] as String)
          : null,
      dueAt: json['due_at'] != null
          ? DateTime.tryParse(json['due_at'] as String)
          : null,
      paymentMethod: json['payment_method'] as String?,
      escalationStatus: json['escalation_status'] as String? ?? 'none',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      shipment: json['shipments'] != null
          ? Shipment.fromJson(json['shipments'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'shipment_id': shipmentId,
      'shipper_id': shipperId,
      'amount': amount,
      'currency': currency,
      'type': type,
      'status': status,
      'paid_at': paidAt?.toIso8601String(),
      'due_at': dueAt?.toIso8601String(),
      'payment_method': paymentMethod,
      'escalation_status': escalationStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isPaid => status == 'paid';

  bool get isAwaitingConfirmation => status == 'awaiting_confirmation';

  bool get isOverdue =>
      !isPaid && dueAt != null && DateTime.now().isAfter(dueAt!);
}

// ============================================================================
// BROADCAST MODEL (Annonce dépêchée à tous les utilisateurs)
// ============================================================================

class Broadcast {
  final String id;
  final String title;
  final String message;
  final String audience;
  final List<String>? targetUserIds;
  final String createdBy;
  final DateTime createdAt;

  Broadcast({
    required this.id,
    required this.title,
    required this.message,
    required this.audience,
    this.targetUserIds,
    required this.createdBy,
    required this.createdAt,
  });

  factory Broadcast.fromJson(Map<String, dynamic> json) {
    return Broadcast(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      audience: json['audience'] as String? ?? 'all',
      targetUserIds: (json['target_user_ids'] as List?)
          ?.map((e) => e as String)
          .toList(),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'audience': audience,
      'target_user_ids': targetUserIds,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ============================================================================
// AD MODEL (Bannière publicitaire affichée en haut des accueil client/expéditeur)
//
// Cycle de vie : les pubs créées par un admin/fondateur sont actives
// immédiatement et gratuites. Un expéditeur soumet sa pub (pending), un admin
// l'approuve (awaiting_payment), l'expéditeur déclare son paiement puis
// l'admin confirme (active). Rejet possible à chaque étape (rejected).
// ============================================================================

class Ad {
  static const String statusActive = 'active';
  static const String statusPending = 'pending';
  static const String statusAwaitingPayment = 'awaiting_payment';
  static const String statusRejected = 'rejected';

  final String id;
  final String imageUrl;
  final String linkUrl;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? title;

  /// Cible de la pub : 'all', 'clients' ou 'shippers'.
  final String audience;

  /// 'active', 'pending', 'awaiting_payment' ou 'rejected'.
  final String status;

  /// Frais de publication en DZD (0 pour une pub créée par un admin).
  final double priceDzd;

  /// Durée d'affichage choisie à la soumission : 7, 15 ou 30 jours.
  final int durationDays;

  /// Date d'expiration posée automatiquement à l'activation
  /// (activation + durée). Null pour les pubs jamais activées.
  final DateTime? expiresAt;

  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  /// Date à laquelle l'expéditeur a déclaré avoir payé (null sinon).
  final DateTime? paymentDeclaredAt;

  Ad({
    required this.id,
    required this.imageUrl,
    required this.linkUrl,
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.audience = 'all',
    this.status = statusActive,
    this.priceDzd = 0,
    this.durationDays = 7,
    this.expiresAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    this.paymentDeclaredAt,
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String,
      linkUrl: json['link_url'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      title: json['title'] as String?,
      audience: json['audience'] as String? ?? 'all',
      status: json['status'] as String? ?? statusActive,
      priceDzd:
          (json['price_dzd'] as num?)?.toDouble() ?? 0,
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 7,
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] == null
          ? null
          : DateTime.parse(json['reviewed_at'] as String),
      rejectionReason: json['rejection_reason'] as String?,
      paymentDeclaredAt: json['payment_declared_at'] == null
          ? null
          : DateTime.parse(json['payment_declared_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'title': title,
      'audience': audience,
      'status': status,
      'price_dzd': priceDzd,
      'duration_days': durationDays,
      'expires_at': expiresAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'payment_declared_at': paymentDeclaredAt?.toIso8601String(),
    };
  }

  bool get isPending => status == statusPending;
  bool get isAwaitingPayment => status == statusAwaitingPayment;
  bool get isRejected => status == statusRejected;
  bool get isLive => status == statusActive && isActive;

  /// Pub activée dont la période d'affichage est dépassée.
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  /// Grille tarifaire officielle : durée d'affichage → frais en DZD.
  static const Map<int, double> pricingTiers = {
    7: 2000,
    15: 3500,
    30: 6000,
  };

  static double priceForDuration(int days) =>
      pricingTiers[days] ?? pricingTiers[7]!;

  static const Map<String, String> audienceLabels = {
    'all': 'Tous',
    'clients': 'Clients',
    'shippers': 'Expéditeurs',
  };

  String get audienceLabel => audienceLabels[audience] ?? audience;

  Ad copyWith({
    bool? isActive,
    String? status,
    String? rejectionReason,
    DateTime? reviewedAt,
    DateTime? paymentDeclaredAt,
    int? durationDays,
    DateTime? expiresAt,
  }) {
    return Ad(
      id: id,
      imageUrl: imageUrl,
      linkUrl: linkUrl,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      title: title,
      audience: audience,
      status: status ?? this.status,
      priceDzd: priceDzd,
      durationDays: durationDays ?? this.durationDays,
      expiresAt: expiresAt ?? this.expiresAt,
      reviewedBy: reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      paymentDeclaredAt: paymentDeclaredAt ?? this.paymentDeclaredAt,
    );
  }
}

// ============================================================================
// AD PRICING RULE (grille tarifaire configurable par le fondateur)
// ============================================================================

/// Une ligne de la grille tarifaire des publicités : le prix dépend à la fois
/// de la durée d'affichage et de l'audience cible. Stockée dans la table
/// `ad_pricing`, éditable par les admins depuis les réglages plateforme.
class AdPricingRule {
  final int durationDays;
  final String audience; // all, clients, shippers
  final double priceDzd;

  const AdPricingRule({
    required this.durationDays,
    this.audience = 'all',
    required this.priceDzd,
  });

  factory AdPricingRule.fromJson(Map<String, dynamic> json) {
    return AdPricingRule(
      durationDays: (json['duration_days'] as num).toInt(),
      audience: json['audience'] as String? ?? 'all',
      priceDzd: (json['price_dzd'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'duration_days': durationDays,
        'audience': audience,
        'price_dzd': priceDzd,
      };

  String get audienceLabel => Ad.audienceLabels[audience] ?? audience;

  /// Grille hors-ligne de secours si la table n'est pas lisible.
  static const List<AdPricingRule> fallback = [
    AdPricingRule(durationDays: 7, audience: 'all', priceDzd: 2000),
    AdPricingRule(durationDays: 7, audience: 'clients', priceDzd: 2500),
    AdPricingRule(durationDays: 7, audience: 'shippers', priceDzd: 2500),
    AdPricingRule(durationDays: 15, audience: 'all', priceDzd: 3500),
    AdPricingRule(durationDays: 15, audience: 'clients', priceDzd: 4500),
    AdPricingRule(durationDays: 15, audience: 'shippers', priceDzd: 4500),
    AdPricingRule(durationDays: 30, audience: 'all', priceDzd: 6000),
    AdPricingRule(durationDays: 30, audience: 'clients', priceDzd: 7500),
    AdPricingRule(durationDays: 30, audience: 'shippers', priceDzd: 7500),
  ];

  /// Prix d'une (durée, audience), avec repli sur la ligne 'all' puis sur
  /// n'importe quelle ligne de cette durée, puis sur la grille statique.
  static double priceFor(List<AdPricingRule> rules, int days, String audience) {
    for (final r in rules) {
      if (r.durationDays == days && r.audience == audience) return r.priceDzd;
    }
    for (final r in rules) {
      if (r.durationDays == days && r.audience == 'all') return r.priceDzd;
    }
    for (final r in rules) {
      if (r.durationDays == days) return r.priceDzd;
    }
    return Ad.priceForDuration(days);
  }

  /// Prix pour une durée LIBRE (miroir exact du trigger SQL) : palier exact ;
  /// sinon, si le fondateur a paramétré une tarification des durées hors
  /// grille (fixe et/ou variable par jour), prix = fixe + variable × jours ;
  /// sinon interpolation linéaire entre les deux paliers encadrants, sinon
  /// prorata du premier/dernier palier. Courbe utilisée : lignes de
  /// l'audience choisie, sinon les lignes 'all', sinon toutes.
  static double priceForFlexible(
      List<AdPricingRule> rules, int days, String audience,
      {double fixedPrice = 0, double variablePrice = 0}) {
    final d = days.clamp(1, 365);
    var pool = rules.where((r) => r.audience == audience).toList();
    if (pool.isEmpty) pool = rules.where((r) => r.audience == 'all').toList();
    if (pool.isEmpty) pool = List.of(rules);
    pool.sort((a, b) => a.durationDays.compareTo(b.durationDays));

    for (final r in pool) {
      if (r.durationDays == d) return r.priceDzd;
    }
    // Durée hors grille : formule linéaire paramétrée par le fondateur dès
    // que l'un des deux réglages est renseigné (fixe > 0 ou variable > 0).
    if (fixedPrice > 0 || variablePrice > 0) {
      return (fixedPrice + variablePrice * d).ceilToDouble();
    }
    AdPricingRule? lo;
    AdPricingRule? hi;
    for (final r in pool) {
      if (r.durationDays < d) lo = r; // garde le plus proche en dessous
      if (r.durationDays > d && hi == null) hi = r; // premier au-dessus
    }
    double ceil(num v) => v.ceilToDouble();
    if (lo != null && hi != null) {
      return ceil(lo.priceDzd +
          (hi.priceDzd - lo.priceDzd) * (d - lo.durationDays) /
              (hi.durationDays - lo.durationDays));
    }
    if (hi != null) return ceil(hi.priceDzd * d / hi.durationDays);
    if (lo != null) return ceil(lo.priceDzd * d / lo.durationDays);
    return Ad.priceForDuration(d);
  }

  /// Durées disponibles dans la grille, triées.
  static List<int> durationsOf(List<AdPricingRule> rules) {
    final days = rules.map((r) => r.durationDays).toSet().toList()..sort();
    return days.isEmpty ? Ad.pricingTiers.keys.toList() : days;
  }
}

// ============================================================================
// CONVERSATION MODEL (Chat expéditeur ↔ client)
// ============================================================================

class Conversation {
  final String id;
  final String? bookingId;
  final String shipperUserId;
  final String clientUserId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Resolved counterpart display payloads (filled in by the service via joins).
  final User? shipperUser;
  final User? clientUser;

  Conversation({
    required this.id,
    this.bookingId,
    required this.shipperUserId,
    required this.clientUserId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    this.shipperUser,
    this.clientUser,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String?,
      shipperUserId: json['shipper_user_id'] as String,
      clientUserId: json['client_user_id'] as String,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      shipperUser:
          json['shippers'] != null ? User.fromJson(json['shippers']) : null,
      clientUser:
          json['clients'] != null ? User.fromJson(json['clients']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'shipper_user_id': shipperUserId,
      'client_user_id': clientUserId,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Conversation copyWith({
    String? id,
    String? bookingId,
    String? shipperUserId,
    String? clientUserId,
    String? lastMessage,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? shipperUser,
    User? clientUser,
  }) {
    return Conversation(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      shipperUserId: shipperUserId ?? this.shipperUserId,
      clientUserId: clientUserId ?? this.clientUserId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shipperUser: shipperUser ?? this.shipperUser,
      clientUser: clientUser ?? this.clientUser,
    );
  }

  bool get hasUnreadMessagesForMe {
    // A conversation preview "unread" state is derived from the last
    // message sender + read state; computed by the service per message.
    return lastMessageAt != null;
  }
}

// ============================================================================
// CHAT MESSAGE MODEL
// ============================================================================

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    this.deliveredAt,
    this.readAt,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      body: json['body'] as String,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'] as String)
          : null,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'body': body,
      'delivered_at': deliveredAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool isFrom(String userId) => senderId == userId;
  bool get isDelivered => deliveredAt != null;
  bool get isRead => readAt != null;
}

// ============================================================================
// DEPOT MODEL (Magasin de collecte des colis — géré par admin / super_admin)
// ============================================================================

class Depot {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final String? phone;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Depot({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.phone,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Depot.fromJson(Map<String, dynamic> json) {
    return Depot(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      phone: json['phone'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'phone': phone,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// ============================================================================
// DEPOT ITEM MODEL (Colis dans l'inventaire d'un dépôt)
// ============================================================================

class DepotItem {
  final String id;
  final String depotId;
  final String? reference;
  final String? description;
  final double weightKg;
  final String? recipientName;
  final String? recipientPhone;
  final String status; // stored, dispatched, returned
  final DateTime receivedAt;
  final DateTime? dispatchedAt;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  DepotItem({
    required this.id,
    required this.depotId,
    this.reference,
    this.description,
    this.weightKg = 0,
    this.recipientName,
    this.recipientPhone,
    this.status = 'stored',
    required this.receivedAt,
    this.dispatchedAt,
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DepotItem.fromJson(Map<String, dynamic> json) {
    return DepotItem(
      id: json['id'] as String,
      depotId: json['depot_id'] as String,
      reference: json['reference'] as String?,
      description: json['description'] as String?,
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0,
      recipientName: json['recipient_name'] as String?,
      recipientPhone: json['recipient_phone'] as String?,
      status: json['status'] as String? ?? 'stored',
      receivedAt: DateTime.parse(json['received_at'] as String),
      dispatchedAt: json['dispatched_at'] != null
          ? DateTime.tryParse(json['dispatched_at'] as String)
          : null,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'depot_id': depotId,
      'reference': reference,
      'description': description,
      'weight_kg': weightKg,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'status': status,
      'received_at': receivedAt.toIso8601String(),
      'dispatched_at': dispatchedAt?.toIso8601String(),
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isStored => status == 'stored';
  bool get isDispatched => status == 'dispatched';
}

// ============================================================================
// REVIEW MODEL (Notation étoile d'un client pour un expéditeur)
// ============================================================================

class Review {
  final String id;
  final String bookingId;
  final String shipmentId;
  final String shipperId;
  final String clientId;
  final int rating; // 1-5
  final String? comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.bookingId,
    required this.shipmentId,
    required this.shipperId,
    required this.clientId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      shipmentId: json['shipment_id'] as String,
      shipperId: json['shipper_id'] as String,
      clientId: json['client_id'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'shipment_id': shipmentId,
      'shipper_id': shipperId,
      'client_id': clientId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ============================================================================
// ACCOUNT DELETION REQUEST (demande web -> validation super admin)
// ============================================================================

class AccountDeletionRequest {
  final String id;
  final String userId;
  final String email;
  final String? fullName;
  final String? role;
  final String status; // pending | approved | rejected
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final DateTime createdAt;

  AccountDeletionRequest({
    required this.id,
    required this.userId,
    required this.email,
    this.fullName,
    this.role,
    required this.status,
    required this.requestedAt,
    this.reviewedAt,
    this.reviewedBy,
    required this.createdAt,
  });

  factory AccountDeletionRequest.fromJson(Map<String, dynamic> json) {
    return AccountDeletionRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      role: json['role'] as String?,
      status: json['status'] as String,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'role': role,
      'status': status,
      'requested_at': requestedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
}

// ============================================================================
// DELETED ACCOUNT (trace conservée — visible uniquement super admin)
// ============================================================================

class DeletedAccount {
  final String id;
  final String userId;
  final String email;
  final String? fullName;
  final String? role;
  final DateTime accountCreatedAt;
  final DateTime deletedAt;
  final String? deletedBy;
  final Map<String, dynamic> history;
  final DateTime createdAt;

  DeletedAccount({
    required this.id,
    required this.userId,
    required this.email,
    this.fullName,
    this.role,
    required this.accountCreatedAt,
    required this.deletedAt,
    this.deletedBy,
    this.history = const {},
    required this.createdAt,
  });

  factory DeletedAccount.fromJson(Map<String, dynamic> json) {
    return DeletedAccount(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      role: json['role'] as String?,
      accountCreatedAt: DateTime.parse(json['account_created_at'] as String),
      deletedAt: DateTime.parse(json['deleted_at'] as String),
      deletedBy: json['deleted_by'] as String?,
      history: (json['history'] as Map?)?.cast<String, dynamic>() ?? const {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'role': role,
      'account_created_at': accountCreatedAt.toIso8601String(),
      'deleted_at': deletedAt.toIso8601String(),
      'deleted_by': deletedBy,
      'history': history,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
