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

  const PlatformSettings({
    this.commissionPercent = 5.0,
    this.minPricePerKg = 500.0,
    this.maxWeightKg = 50.0,
    this.minWeightKg = 0.1,
    this.roundingPrecision = 1,
    this.defaultCurrency = 'DZD',
    this.adCustomFixedPrice = 0.0,
    this.adCustomVariablePrice = 0.0,
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
    return PlatformSettings(
      commissionPercent: d('platform_commission_percent', 5.0),
      minPricePerKg: d('min_price_per_kg', 500.0),
      maxWeightKg: d('max_weight_kg', 50.0),
      minWeightKg: d('min_weight_kg', 0.1),
      roundingPrecision: i('rounding_precision', 1),
      defaultCurrency: map['default_currency'] ?? 'DZD',
      adCustomFixedPrice: d('ad_custom_fixed_price', 0.0),
      adCustomVariablePrice: d('ad_custom_variable_price', 0.0),
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