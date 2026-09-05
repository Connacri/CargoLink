// ============================================================================
// PLATFORM SETTINGS SERVICE (paramétrage Fondateur)
// ============================================================================

import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

/// Typed, founder-configurable platform settings backed by the
/// `platform_settings` key/value table. Falls back to sensible defaults so the
/// app keeps working even before the table is seeded (or a key is missing).
class PlatformSettings {
  final double commissionPercent;
  final double minPricePerKg;
  final double maxWeightKg;
  final double minWeightKg;
  final int roundingPrecision;
  final String defaultCurrency;

  /// Tarification des durées publicitaires HORS grille (choix libre de
  /// l'expéditeur) : prix = fixe + variable × jours, dès que l'un des deux
  /// est > 0. Sinon, interpolation automatique entre paliers.
  final double adCustomFixedPrice;
  final double adCustomVariablePrice;

  /// Part des gains du parrain : pourcentage de la commission plateforme
  /// reversé au parrain pour chaque colis livré et payé par un filleul.
  /// Doit rester synchronisé avec le trigger SQL
  /// `apply_referral_on_booking_delivery` (table `referral_earnings`).
  final double referralCommissionPercent;

  /// Le programme de parrainage est-il actif ? Lorsqu'il est désactivé, la
  /// section parrainage est masquée dans l'app (même si un code existe).
  final bool referralProgramActive;

  /// Visibilité par rôle des bannières / cartes / boutons des écrans d'accueil
  /// et du profil — pilotée par le Fondateur depuis « Paramètres d'affichage »
  /// (boutons radio). Défaut : masqué.
  final bool showClientHomeDeliveryRequest;
  final bool showClientHomeSubscription;
  final bool showShipperHomeSubscription;
  final bool showShipperHomePublishAd;
  final bool showShipperHomeDeliveryRequests;
  final bool showProfileSubscription;
  final bool showProfileReferral;

  const PlatformSettings({
    this.commissionPercent = 5.0,
    this.minPricePerKg = 500.0,
    this.maxWeightKg = 50.0,
    this.minWeightKg = 0.1,
    this.roundingPrecision = 1,
    this.defaultCurrency = 'DZD',
    this.adCustomFixedPrice = 0.0,
    this.adCustomVariablePrice = 0.0,
    this.referralCommissionPercent = 50.0,
    this.referralProgramActive = false,
    this.showClientHomeDeliveryRequest = false,
    this.showClientHomeSubscription = false,
    this.showShipperHomeSubscription = false,
    this.showShipperHomePublishAd = false,
    this.showShipperHomeDeliveryRequests = false,
    this.showProfileSubscription = false,
    this.showProfileReferral = false,
  });

  static const List<String> _keys = [
    'platform_commission_percent',
    'min_price_per_kg',
    'max_weight_kg',
    'min_weight_kg',
    'rounding_precision',
    'default_currency',
    'ad_custom_fixed_price',
    'ad_custom_variable_price',
    'referral_commission_percent',
    'referral_program_active',
    'show_client_home_delivery_request',
    'show_client_home_subscription',
    'show_shipper_home_subscription',
    'show_shipper_home_publish_ad',
    'show_shipper_home_delivery_requests',
    'show_profile_subscription',
    'show_profile_referral',
  ];

  factory PlatformSettings.fromRows(List<Map<String, dynamic>> rows) {
    final map = <String, String>{};
    for (final row in rows) {
      final key = row['key'] as String?;
      final value = row['value'] as String?;
      if (key != null && value != null) map[key] = value;
    }
    return PlatformSettings.fromMap(map);
  }

  factory PlatformSettings.fromMap(Map<String, String> map) {
    double d(String key, double fallback) =>
        double.tryParse(map[key] ?? '') ?? fallback;
    int i(String key, int fallback) => int.tryParse(map[key] ?? '') ?? fallback;
    bool b(String key, bool fallback) {
      final raw = map[key]?.trim().toLowerCase();
      if (raw == 'true' || raw == '1') return true;
      if (raw == 'false' || raw == '0') return false;
      return fallback;
    }

    return PlatformSettings(
      commissionPercent: d('platform_commission_percent', 5.0),
      minPricePerKg: d('min_price_per_kg', 500.0),
      maxWeightKg: d('max_weight_kg', 50.0),
      minWeightKg: d('min_weight_kg', 0.1),
      roundingPrecision: i('rounding_precision', 1),
      defaultCurrency: map['default_currency'] ?? 'DZD',
      adCustomFixedPrice: d('ad_custom_fixed_price', 0.0),
      adCustomVariablePrice: d('ad_custom_variable_price', 0.0),
      referralCommissionPercent: d('referral_commission_percent', 50.0),
      referralProgramActive: b('referral_program_active', false),
      showClientHomeDeliveryRequest:
          b('show_client_home_delivery_request', false),
      showClientHomeSubscription: b('show_client_home_subscription', false),
      showShipperHomeSubscription: b('show_shipper_home_subscription', false),
      showShipperHomePublishAd: b('show_shipper_home_publish_ad', false),
      showShipperHomeDeliveryRequests:
          b('show_shipper_home_delivery_requests', false),
      showProfileSubscription: b('show_profile_subscription', false),
      showProfileReferral: b('show_profile_referral', false),
    );
  }

  /// Key/value map ready to be persisted via upsert.
  Map<String, String> toUpdateMap() {
    return {
      'platform_commission_percent': commissionPercent.toString(),
      'min_price_per_kg': minPricePerKg.toString(),
      'max_weight_kg': maxWeightKg.toString(),
      'min_weight_kg': minWeightKg.toString(),
      'rounding_precision': roundingPrecision.toString(),
      'default_currency': defaultCurrency,
      'ad_custom_fixed_price': adCustomFixedPrice.toString(),
      'ad_custom_variable_price': adCustomVariablePrice.toString(),
      'referral_commission_percent': referralCommissionPercent.toString(),
      'referral_program_active': referralProgramActive.toString(),
      'show_client_home_delivery_request':
          showClientHomeDeliveryRequest.toString(),
      'show_client_home_subscription': showClientHomeSubscription.toString(),
      'show_shipper_home_subscription': showShipperHomeSubscription.toString(),
      'show_shipper_home_publish_ad': showShipperHomePublishAd.toString(),
      'show_shipper_home_delivery_requests':
          showShipperHomeDeliveryRequests.toString(),
      'show_profile_subscription': showProfileSubscription.toString(),
      'show_profile_referral': showProfileReferral.toString(),
    };
  }

  static List<String> get keys => _keys;
}

class SettingsService {
  SupabaseClient get _supabase => SupabaseConfig.client;
  final _logger = Logger();

  /// Load every platform setting.
  Future<PlatformSettings> getSettings() async {
    try {
      final response = await _supabase
          .from('platform_settings')
          .select('key,value');
      final rows = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return PlatformSettings.fromRows(rows);
    } catch (e) {
      _logger.e('Error getting platform settings: $e');
      return const PlatformSettings();
    }
  }

  /// Persist the given key/value pairs (admin/super_admin only — RLS).
  Future<void> updateSettings(Map<String, String> values) async {
    try {
      final now = DateTime.now().toIso8601String();
      for (final entry in values.entries) {
        await _supabase.from('platform_settings').upsert({
          'key': entry.key,
          'value': entry.value,
          'updated_at': now,
        });
      }
      _logger.i('Platform settings updated');
    } catch (e) {
      _logger.e('Error updating platform settings: $e');
      rethrow;
    }
  }
}