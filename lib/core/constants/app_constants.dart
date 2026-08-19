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
  static const List<String> supportedCurrencies = ['DZD', 'EUR', 'USD', 'CNY'];
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

  // Android APK download link (public GitHub Release artifact).
  static const String androidApkUrl =
      'https://github.com/Connacri/CargoLink/releases/latest/download/app-release.apk';
}
