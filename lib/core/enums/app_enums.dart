import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// ============================================================================
// USER ROLES
// ============================================================================

enum UserRole {
  client,
  shipper,
  admin,
}

extension UserRoleExt on UserRole {
  String get value {
    switch (this) {
      case UserRole.client:
        return 'client';
      case UserRole.shipper:
        return 'shipper';
      case UserRole.admin:
        return 'admin';
    }
  }
  
  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'client':
        return UserRole.client;
      case 'shipper':
        return UserRole.shipper;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.client;
    }
  }
}

// ============================================================================
// SHIPMENT STATUS
// ============================================================================

enum ShipmentStatus {
  active,
  completed,
  cancelled,
}

extension ShipmentStatusExt on ShipmentStatus {
  String get value {
    switch (this) {
      case ShipmentStatus.active:
        return 'active';
      case ShipmentStatus.completed:
        return 'completed';
      case ShipmentStatus.cancelled:
        return 'cancelled';
    }
  }
}

// ============================================================================
// BOOKING STATUS
// ============================================================================

enum BookingStatus {
  pending,
  confirmed,
  collected,
  verifying,
  accepted,
  shipped,
  arrived,
  outForDelivery,
  delivered,
  cancelled,
}

extension BookingStatusExt on BookingStatus {
  String get value {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.collected:
        return 'collected';
      case BookingStatus.verifying:
        return 'verifying';
      case BookingStatus.accepted:
        return 'accepted';
      case BookingStatus.shipped:
        return 'shipped';
      case BookingStatus.arrived:
        return 'arrived';
      case BookingStatus.outForDelivery:
        return 'out_for_delivery';
      case BookingStatus.delivered:
        return 'delivered';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }

  static BookingStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'collected':
        return BookingStatus.collected;
      case 'verifying':
        return BookingStatus.verifying;
      case 'accepted':
        return BookingStatus.accepted;
      case 'shipped':
        return BookingStatus.shipped;
      case 'arrived':
        return BookingStatus.arrived;
      case 'out_for_delivery':
        return BookingStatus.outForDelivery;
      case 'delivered':
        return BookingStatus.delivered;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'En attente';
      case BookingStatus.confirmed:
        return 'Confirmé';
      case BookingStatus.collected:
        return 'Colis récupéré';
      case BookingStatus.verifying:
        return 'En vérification';
      case BookingStatus.accepted:
        return 'Accepté';
      case BookingStatus.shipped:
        return 'Expédié';
      case BookingStatus.arrived:
        return 'Arrivé à destination';
      case BookingStatus.outForDelivery:
        return 'En cours de livraison';
      case BookingStatus.delivered:
        return 'Livré';
      case BookingStatus.cancelled:
        return 'Annulé';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.pending:
        return AppTheme.warningColor;
      case BookingStatus.confirmed:
      case BookingStatus.accepted:
        return AppTheme.primaryColor;
      case BookingStatus.collected:
      case BookingStatus.verifying:
        return AppTheme.infoColor;
      case BookingStatus.shipped:
      case BookingStatus.arrived:
        return AppTheme.primaryColor;
      case BookingStatus.outForDelivery:
        return AppTheme.warningColor;
      case BookingStatus.delivered:
        return AppTheme.accentColor;
      case BookingStatus.cancelled:
        return AppTheme.errorColor;
    }
  }
}

// ============================================================================
// SHIPPER TYPE (voyageur ordinaire / micro-importateur)
// ============================================================================

enum ShipperType {
  voyageurOrdinaire,
  microImportateur,
}

extension ShipperTypeExt on ShipperType {
  String get value {
    switch (this) {
      case ShipperType.voyageurOrdinaire:
        return 'voyageur_ordinaire';
      case ShipperType.microImportateur:
        return 'micro_importateur';
    }
  }

  static ShipperType fromString(String value) {
    switch (value) {
      case 'micro_importateur':
        return ShipperType.microImportateur;
      default:
        return ShipperType.voyageurOrdinaire;
    }
  }

  String get displayName {
    switch (this) {
      case ShipperType.voyageurOrdinaire:
        return 'Voyageur ordinaire';
      case ShipperType.microImportateur:
        return 'Micro-Importateur';
    }
  }
}

// ============================================================================
// VERIFICATION STATUS
// ============================================================================

enum VerificationStatus {
  pending,
  verified,
  rejected,
}

extension VerificationStatusExt on VerificationStatus {
  String get value {
    switch (this) {
      case VerificationStatus.pending:
        return 'pending';
      case VerificationStatus.verified:
        return 'verified';
      case VerificationStatus.rejected:
        return 'rejected';
    }
  }
}

// ============================================================================
// DISPUTE TYPE
// ============================================================================

enum DisputeType {
  fraud,
  customsSeizure,
  damage,
  nonDelivery,
  other,
}

extension DisputeTypeExt on DisputeType {
  String get value {
    switch (this) {
      case DisputeType.fraud:
        return 'fraud';
      case DisputeType.customsSeizure:
        return 'customs_seizure';
      case DisputeType.damage:
        return 'damage';
      case DisputeType.nonDelivery:
        return 'non_delivery';
      case DisputeType.other:
        return 'other';
    }
  }
  
  String get displayName {
    switch (this) {
      case DisputeType.fraud:
        return 'Fraude';
      case DisputeType.customsSeizure:
        return 'Saisie Douane';
      case DisputeType.damage:
        return 'Endommagé';
      case DisputeType.nonDelivery:
        return 'Non Livré';
      case DisputeType.other:
        return 'Autre';
    }
  }
}
