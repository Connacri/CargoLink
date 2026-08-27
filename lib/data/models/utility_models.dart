// ============================================================================
// UTILITY MODELS — Tables auxiliaires (flags, tokens, logs, settings, etc.)
// ============================================================================

// ----------------------------------------------------------------------------
// SHIPPER FLAG — Signalement admin d'un expéditeur
// ----------------------------------------------------------------------------

class ShipperFlag {
  final String id;
  final String shipperId;
  final String reason;
  final DateTime createdAt;

  ShipperFlag({
    required this.id,
    required this.shipperId,
    required this.reason,
    required this.createdAt,
  });

  factory ShipperFlag.fromJson(Map<String, dynamic> json) {
    return ShipperFlag(
      id: json['id'] as String,
      shipperId: json['shipper_id'] as String,
      reason: json['reason'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipper_id': shipperId,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ----------------------------------------------------------------------------
// DEVICE TOKEN — Push notification token FCM
// ----------------------------------------------------------------------------

class DeviceToken {
  final String id;
  final String userId;
  final String token;
  final String platform; // android, ios, web
  final DateTime createdAt;
  final DateTime updatedAt;

  DeviceToken({
    required this.id,
    required this.userId,
    required this.token,
    required this.platform,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeviceToken.fromJson(Map<String, dynamic> json) {
    return DeviceToken(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      token: json['token'] as String,
      platform: json['platform'] as String? ?? 'android',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'token': token,
      'platform': platform,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// ----------------------------------------------------------------------------
// TRANSFER TOKEN — Token QR/OTP pour vérification de transfert de garde
// ----------------------------------------------------------------------------

class TransferToken {
  final String id;
  final String custodyTransferId;
  final String tokenType; // QR, OTP
  final String tokenHash;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final DateTime createdAt;

  TransferToken({
    required this.id,
    required this.custodyTransferId,
    required this.tokenType,
    required this.tokenHash,
    required this.expiresAt,
    this.usedAt,
    required this.createdAt,
  });

  factory TransferToken.fromJson(Map<String, dynamic> json) {
    return TransferToken(
      id: json['id'] as String,
      custodyTransferId: json['custody_transfer_id'] as String,
      tokenType: json['token_type'] as String? ?? 'QR',
      tokenHash: json['token_hash'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      usedAt: json['used_at'] != null
          ? DateTime.tryParse(json['used_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'custody_transfer_id': custodyTransferId,
      'token_type': tokenType,
      'token_hash': tokenHash,
      'expires_at': expiresAt.toIso8601String(),
      'used_at': usedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isUsed => usedAt != null;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

// ----------------------------------------------------------------------------
// DELIVERY ATTEMPT — Tentative de livraison enregistrée
// ----------------------------------------------------------------------------

class DeliveryAttempt {
  final String id;
  final String shipmentId;
  final String? packageId;
  final String? legId;
  final String? shipperId;
  final DateTime attemptedAt;
  final String result; // success, failed, refused, rescheduled
  final String? reason;
  final String? notes;

  DeliveryAttempt({
    required this.id,
    required this.shipmentId,
    this.packageId,
    this.legId,
    this.shipperId,
    required this.attemptedAt,
    required this.result,
    this.reason,
    this.notes,
  });

  factory DeliveryAttempt.fromJson(Map<String, dynamic> json) {
    return DeliveryAttempt(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String,
      packageId: json['package_id'] as String?,
      legId: json['leg_id'] as String?,
      shipperId: json['shipper_id'] as String?,
      attemptedAt: DateTime.parse(json['attempted_at'] as String),
      result: json['result'] as String,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'package_id': packageId,
      'leg_id': legId,
      'shipper_id': shipperId,
      'attempted_at': attemptedAt.toIso8601String(),
      'result': result,
      'reason': reason,
      'notes': notes,
    };
  }

  bool get isSuccess => result == 'success';
  bool get isFailed => result == 'failed';
}

// ----------------------------------------------------------------------------
// AUDIT LOG — Journal d'audit append-only
// ----------------------------------------------------------------------------

class AuditLog {
  final String id;
  final String? actorId;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic>? beforeData;
  final Map<String, dynamic>? afterData;
  final String? device;
  final String? ip;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    this.actorId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.beforeData,
    this.afterData,
    this.device,
    this.ip,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      actorId: json['actor_id'] as String?,
      action: json['action'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String?,
      beforeData: (json['before_data'] as Map?)?.cast<String, dynamic>(),
      afterData: (json['after_data'] as Map?)?.cast<String, dynamic>(),
      device: json['device'] as String?,
      ip: json['ip'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actor_id': actorId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'before_data': beforeData,
      'after_data': afterData,
      'device': device,
      'ip': ip,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ----------------------------------------------------------------------------
// DEVICE KEY — Clé publique cryptographique d'un appareil
// ----------------------------------------------------------------------------

class DeviceKey {
  final String id;
  final String userId;
  final String publicKey;
  final String keyType; // ed25519
  final DateTime createdAt;
  final DateTime updatedAt;

  DeviceKey({
    required this.id,
    required this.userId,
    required this.publicKey,
    required this.keyType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeviceKey.fromJson(Map<String, dynamic> json) {
    return DeviceKey(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      publicKey: json['public_key'] as String,
      keyType: json['key_type'] as String? ?? 'ed25519',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'public_key': publicKey,
      'key_type': keyType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// ----------------------------------------------------------------------------
// PLATFORM SETTING — Paramètre global de la plateforme (clé → valeur)
// ----------------------------------------------------------------------------

class PlatformSetting {
  final String key;
  final String value;
  final String? description;
  final DateTime updatedAt;

  PlatformSetting({
    required this.key,
    required this.value,
    this.description,
    required this.updatedAt,
  });

  factory PlatformSetting.fromJson(Map<String, dynamic> json) {
    return PlatformSetting(
      key: json['key'] as String,
      value: json['value'] as String,
      description: json['description'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'description': description,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Cast value to bool (accepte 'true', '1', 'false', '0').
  bool get boolValue =>
      value.toLowerCase() == 'true' || value == '1';

  /// Cast value to double.
  double? get doubleValue => double.tryParse(value);

  /// Cast value to int.
  int? get intValue => int.tryParse(value);
}

// ----------------------------------------------------------------------------
// REFERRAL CODE — Code de parrainage unique par utilisateur
// ----------------------------------------------------------------------------

class ReferralCode {
  final String userId;
  final String code;
  final DateTime createdAt;

  ReferralCode({
    required this.userId,
    required this.code,
    required this.createdAt,
  });

  factory ReferralCode.fromJson(Map<String, dynamic> json) {
    return ReferralCode(
      userId: json['user_id'] as String,
      code: json['code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'code': code,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ----------------------------------------------------------------------------
// REFERRAL (referrals) — Lien parrain ↔ filleul
// ----------------------------------------------------------------------------

class Referral {
  final String id;
  final String parrainId;
  final String filleulId;
  final DateTime createdAt;

  Referral({
    required this.id,
    required this.parrainId,
    required this.filleulId,
    required this.createdAt,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['id'] as String,
      parrainId: json['parrain_id'] as String,
      filleulId: json['filleul_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parrain_id': parrainId,
      'filleul_id': filleulId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ----------------------------------------------------------------------------
// FEEDBACK — Signalement / feedback utilisateur
// ----------------------------------------------------------------------------

class Feedback {
  final String id;
  final String userId;
  final String role;
  final String message;
  final String? screenshotUrl;
  final bool isRead;
  final DateTime createdAt;

  Feedback({
    required this.id,
    required this.userId,
    required this.role,
    required this.message,
    this.screenshotUrl,
    this.isRead = false,
    required this.createdAt,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      message: json['message'] as String,
      screenshotUrl: json['screenshot_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'role': role,
      'message': message,
      'screenshot_url': screenshotUrl,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
