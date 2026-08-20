// ============================================================================
// USER MODEL
// ============================================================================

class User {
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final String? profilePictureUrl;
  final String role; // client, shipper, admin
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
  final String? rejectionReason;
  final String? verifiedByAdminId;
  final DateTime? verifiedAt;
  final double rating; // 0-5
  final int totalShipments;
  final DateTime createdAt;
  final User? user; // Related user object

  Shipper({
    required this.id,
    required this.userId,
    required this.passportNumber,
    required this.passportPhotoUrl,
    required this.livePhotoUrl,
    required this.verificationStatus,
    this.rejectionReason,
    this.verifiedByAdminId,
    this.verifiedAt,
    this.rating = 0.0,
    this.totalShipments = 0,
    required this.createdAt,
    this.user,
  });

  factory Shipper.fromJson(Map<String, dynamic> json) {
    return Shipper(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      passportNumber: json['passport_number'] as String,
      passportPhotoUrl: json['passport_photo_url'] as String,
      livePhotoUrl: json['live_photo_url'] as String,
      verificationStatus: json['verification_status'] as String,
      rejectionReason: json['rejection_reason'] as String?,
      verifiedByAdminId: json['verified_by_admin_id'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalShipments: json['total_shipments'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: json['users'] != null ? User.fromJson(json['users']) : null,
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
      'rejection_reason': rejectionReason,
      'verified_by_admin_id': verifiedByAdminId,
      'verified_at': verifiedAt?.toIso8601String(),
      'rating': rating,
      'total_shipments': totalShipments,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';

  String get ratingDisplay => rating.toStringAsFixed(1);
}

// ============================================================================
// SHIPMENT MODEL (Offre de transport)
// ============================================================================

class Shipment {
  final String id;
  final String shipperId;
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final Shipper? shipper; // Related shipper object

  double get remainingWeightKg => availableWeightKg - reservedWeightKg;
  double get utilizationPercent => (reservedWeightKg / availableWeightKg) * 100;
  bool get isFull => remainingWeightKg <= 0;
  bool get isActive =>
      status == 'active' && arrivalDate.isAfter(DateTime.now());

  Shipment({
    required this.id,
    required this.shipperId,
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
    required this.createdAt,
    required this.updatedAt,
    this.shipper,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      id: json['id'] as String,
      shipperId: json['shipper_id'] as String,
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
  final String productName;
  final String productDescription;
  final List<String>? productPhotosUrl;
  final double requestedWeightKg;
  final double allocatedWeightKg;
  final double totalPrice;
  final String status; // pending, confirmed, shipped, delivered, cancelled
  final String paymentStatus; // pending, paid, refunded
  final String? trackingNumber;
  final String? deliveryPhotoUrl;
  final String? receiptPhotoUrl;
  final DateTime? receiptConfirmedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Shipment? shipment;
  final User? client;

  Booking({
    required this.id,
    required this.shipmentId,
    required this.clientId,
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
          ? DateTime.parse(json['receipt_confirmed_at'] as String)
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isPaid => paymentStatus == 'paid';
  bool get isDelivered => status == 'delivered';
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
      status; // order_processed, collected, departed_origin, in_transit, arrived_destination, customs_cleared, out_for_delivery, delivered
  final DateTime timestamp;
  final String? notes;
  final String? location;

  ShipmentTracking({
    required this.id,
    required this.bookingId,
    this.latitude,
    this.longitude,
    required this.status,
    required this.timestamp,
    this.notes,
    this.location,
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
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.bookingId,
    required this.amount,
    this.currency = 'DZD',
    required this.status,
    this.paymentMethod,
    this.transactionId,
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
  final String bookingId;
  final String shipmentId;
  final String shipperId;
  final double amount;
  final String status; // pending, awaiting_confirmation, paid
  final DateTime? paidAt;
  final DateTime createdAt;
  final Shipment? shipment; // Related shipment (route + shipper) for admin lists

  PlatformFee({
    required this.id,
    required this.bookingId,
    required this.shipmentId,
    required this.shipperId,
    required this.amount,
    required this.status,
    this.paidAt,
    required this.createdAt,
    this.shipment,
  });

  factory PlatformFee.fromJson(Map<String, dynamic> json) {
    return PlatformFee(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      shipmentId: json['shipment_id'] as String,
      shipperId: json['shipper_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      shipment: json['shipments'] != null
          ? Shipment.fromJson(json['shipments'])
          : null,
    );
  }

  bool get isPaid => status == 'paid';

  bool get isAwaitingConfirmation => status == 'awaiting_confirmation';
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
    );
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
    );
  }
}
