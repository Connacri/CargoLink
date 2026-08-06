import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// SUPABASE CONFIGURATION
// ============================================================================

class SupabaseConfig {
  // Project URL (public, safe to commit)
  static const String supabaseUrl = 'https://mxhomeuraxnmjtfhzhvz.supabase.co';

  // Loaded at build time via --dart-define=SUPABASE_ANON_KEY=...
  // (never hardcode a key; get yours from Supabase -> Settings -> API)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'PASTE_YOUR_SUPABASE_ANON_KEY_HERE',
  );

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authFlowType: AuthFlowType.implicit,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}

// ============================================================================
// FIREBASE CONFIGURATION
// ============================================================================

Future<void> initializeFirebase() async {
  // Firebase init is optional and configured separately.
  // Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

// ============================================================================
// APP CONSTANTS
// ============================================================================

class AppConstants {
  // API Endpoints
  static const String baseUrl = 'https://api.cargolink.local/v1';
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 20);
  
  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  static const int maxProfileImageSize = 2 * 1024 * 1024; // 2MB
  
  // Weight calculations
  static const double minWeightKg = 0.1;
  static const double maxWeightKg = 50.0;
  static const int roundingPrecision = 1; // Round to nearest 1kg
  
  // Pricing
  static const String defaultCurrency = 'DZD';
  static const double platformCommissionPercent = 5.0;
  static const double minPricePerKg = 500.0; // DZD
  
  // Locations (Algerian cities)
  static const List<String> majorCities = [
    'Alger',
    'Oran',
    'Annaba',
    'Constantine',
    'Tlemcen',
    'Sidi Bel Abbès',
    'Béjaïa',
    'Tizi Ouzou',
    'Batna',
    'Blida',
  ];
  
  // International destinations for shippers
  static const List<String> populateOrigins = [
    'Turquie',
    'Chine',
    'Dubaï',
    'France',
    'Italie',
    'Espagne',
  ];
  
  // Notification limits
  static const int maxNotificationsPerDay = 50;
  
  // Pagination
  static const int defaultPageSize = 20;
}

// ============================================================================
// APP THEME
// ============================================================================

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xE0E7FF);
  
  // Accent Colors
  static const Color accentColor = Color(0xFF10B981); // Green
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color errorColor = Color(0xEF4444); // Red
  
  // Neutral Colors
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textPrimaryColor = Color(0xFF1F2937);
  static const Color textSecondaryColor = Color(0xFF6B7280);
  static const Color dividerColor = Color(0xFFE5E7EB);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}

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
