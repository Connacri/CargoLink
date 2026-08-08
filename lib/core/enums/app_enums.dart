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
  shipped,
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
      case BookingStatus.shipped:
        return 'shipped';
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
      case 'shipped':
        return BookingStatus.shipped;
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
      case BookingStatus.shipped:
        return 'Expédié';
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
        return AppTheme.primaryColor;
      case BookingStatus.shipped:
        return AppTheme.primaryColor;
      case BookingStatus.delivered:
        return AppTheme.accentColor;
      case BookingStatus.cancelled:
        return AppTheme.errorColor;
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
