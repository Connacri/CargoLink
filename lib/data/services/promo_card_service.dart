// ============================================================================
// PROMO CARD SERVICE (Carte « Guide CabaLink » — configurable par le fondateur)
//
// La carte de promo affichée sur l'écran de connexion est pilotée par une ligne
// de la table `promo_cards` (slot « guide ») : image de fond (bucket « promos »),
// textes et padding LTRB. Lecture publique (la carte s'affiche même non
// connecté) ; écriture réservée admins/super_admin via RLS.
// ============================================================================

import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../../core/config/supabase_config.dart';

class PromoCardService {
  /// Bucket public hébergeant l'image de fond de la carte.
  static const String bucketName = 'promos';

  SupabaseClient get _supabase => SupabaseConfig.client;
  final _logger = Logger();

  /// Configuration de la carte pour un [slot] (« guide » par défaut).
  /// Retourne [PromoCardConfig.fallback] en cas d'absence de ligne ou d'erreur
  /// (ex. hors-ligne) pour ne jamais casser l'écran de connexion.
  Future<PromoCardConfig> getPromoCard({String slot = PromoCardConfig.slotGuide}) async {
    try {
      final response = await _supabase
          .from('promo_cards')
          .select()
          .eq('slot', slot)
          .limit(1);
      if (response.isEmpty) {
        return PromoCardConfig.fallback;
      }
      return PromoCardConfig.fromJson(
          Map<String, dynamic>.from(response.first as Map));
    } catch (e) {
      _logger.e('Error getting promo card: $e');
      return PromoCardConfig.fallback;
    }
  }

  /// Enregistre la configuration du slot (insert si absent, sinon update).
  Future<void> savePromoCard(PromoCardConfig config,
      {String slot = PromoCardConfig.slotGuide}) async {
    try {
      await _supabase.from('promo_cards').upsert({
        ...config.toJson(),
        'slot': slot,
      });
      _logger.i('Promo card saved (slot=$slot)');
    } catch (e) {
      _logger.e('Error saving promo card: $e');
      rethrow;
    }
  }
}