// ============================================================================
// FORBIDDEN ITEM SERVICE (Articles interdits — configuration par le fondateur)
// ============================================================================

import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/delivery_models.dart';
import '../../core/config/supabase_config.dart';

/// Gestion des articles interdits vérifiés lors du contrôle colis ("interdits").
/// Lecture publique (items actifs) + écriture réservée au fondateur via RLS.
class ForbiddenItemService {
  SupabaseClient get _supabase => SupabaseConfig.client;
  final _logger = Logger();

  /// Items actifs affichés dans la feuille de vérification colis (expéditeur),
  /// ordonnés par [sortOrder].
  Future<List<ForbiddenItem>> getActiveItems() async {
    try {
      final response = await _supabase
          .from('forbidden_items')
          .select()
          .eq('active', true)
          .order('sort_order', ascending: true);
      return (response as List)
          .map((r) =>
              ForbiddenItem.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      _logger.e('Error getting active forbidden items: $e');
      return [];
    }
  }

  /// Tous les items (actifs et inactifs) — vue de gestion du fondateur.
  Future<List<ForbiddenItem>> getAllItems() async {
    try {
      final response = await _supabase
          .from('forbidden_items')
          .select()
          .order('sort_order', ascending: true);
      return (response as List)
          .map((r) =>
              ForbiddenItem.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      _logger.e('Error getting all forbidden items: $e');
      return [];
    }
  }

  /// Créer un article interdit (fondateur, via formulaire) — [sortOrder] placé
  /// en fin de liste si non fourni.
  Future<void> createItem({
    required String name,
    required String category,
    int? sortOrder,
  }) async {
    final maxOrder = await _maxSortOrder();
    await _supabase.from('forbidden_items').insert({
      'name': name,
      'category': category,
      'sort_order': sortOrder ?? maxOrder + 1,
      'active': true,
    });
  }

  /// Mettre à jour nom/catégorie (fondateur, via formulaire).
  Future<void> updateItem(
    String itemId, {
    required String name,
    required String category,
  }) async {
    await _supabase.from('forbidden_items').update({
      'name': name,
      'category': category,
    }).eq('id', itemId);
  }

  /// Activer/désactiver un item (fondateur). Un item inactif n'est plus affiché
  /// dans la feuille de vérification.
  Future<void> toggleItem(String itemId, bool active) async {
    await _supabase
        .from('forbidden_items')
        .update({'active': active}).eq('id', itemId);
  }

  /// Supprimer un item (fondateur).
  Future<void> deleteItem(String itemId) async {
    await _supabase.from('forbidden_items').delete().eq('id', itemId);
  }

  /// Réordonner la liste après un drag & drop : les [orderedIds] (du plus haut
  /// au plus bas) reçoivent les sort_order 1..N.
  Future<void> reorderItems(List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      await _supabase
          .from('forbidden_items')
          .update({'sort_order': i + 1}).eq('id', orderedIds[i]);
    }
  }

  Future<int> _maxSortOrder() async {
    try {
      final res = await _supabase
          .from('forbidden_items')
          .select('sort_order')
          .order('sort_order', ascending: false)
          .limit(1);
      if (res.isNotEmpty) {
        return (res.first as Map)['sort_order'] as int? ?? 0;
      }
    } catch (_) {}
    return 0;
  }
}
