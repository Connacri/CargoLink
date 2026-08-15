import '../models/models.dart';
import '../../core/config/supabase_config.dart';
import 'package:logger/logger.dart';

// ============================================================================
// INVENTORY SERVICE — Dépôts (magasins de collecte) + inventaire de colis
// Géré par les rôles admin / super_admin (RLS). Les autres utilisateurs
// peuvent lire les dépôts (points de collecte) mais pas l'inventaire.
// ============================================================================

class InventoryService {
  final _logger = Logger();

  // --- Dépôts -------------------------------------------------------------

  Future<List<Depot>> getDepots({int limit = 200, int offset = 0}) async {
    try {
      final response = await SupabaseConfig.client
          .from('depots')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (response as List)
          .map((item) => Depot.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting depots: $e');
      return [];
    }
  }

  Future<Depot?> getDepotById(String depotId) async {
    try {
      final response = await SupabaseConfig.client
          .from('depots')
          .select()
          .eq('id', depotId)
          .single();
      return Depot.fromJson(response);
    } catch (e) {
      _logger.e('Error getting depot $depotId: $e');
      return null;
    }
  }

  /// Create a depot. Only admin / super_admin can (RLS).
  Future<Depot> createDepot({
    required String name,
    String? address,
    String? city,
    String? phone,
  }) async {
    try {
      final response = await SupabaseConfig.client
          .from('depots')
          .insert({
            'name': name,
            'address': address,
            'city': city,
            'phone': phone,
          })
          .select()
          .single();
      _logger.i('Depot created');
      return Depot.fromJson(response);
    } catch (e) {
      _logger.e('Error creating depot: $e');
      rethrow;
    }
  }

  Future<Depot> updateDepot({
    required String depotId,
    String? name,
    String? address,
    String? city,
    String? phone,
  }) async {
    try {
      final response = await SupabaseConfig.client
          .from('depots')
          .update({
            'name': name,
            'address': address,
            'city': city,
            'phone': phone,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', depotId)
          .select()
          .single();
      _logger.i('Depot updated: $depotId');
      return Depot.fromJson(response);
    } catch (e) {
      _logger.e('Error updating depot: $e');
      rethrow;
    }
  }

  Future<void> deleteDepot(String depotId) async {
    try {
      await SupabaseConfig.client.from('depots').delete().eq('id', depotId);
      _logger.i('Depot deleted: $depotId');
    } catch (e) {
      _logger.e('Error deleting depot: $e');
      rethrow;
    }
  }

  // --- Inventaire de colis --------------------------------------------------

  Future<List<DepotItem>> getDepotItems(
    String depotId, {
    int limit = 500,
    int offset = 0,
  }) async {
    try {
      final response = await SupabaseConfig.client
          .from('depot_items')
          .select()
          .eq('depot_id', depotId)
          .order('received_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (response as List)
          .map((item) => DepotItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting depot items: $e');
      return [];
    }
  }

  Future<DepotItem> addDepotItem({
    required String depotId,
    String? reference,
    String? description,
    double weightKg = 0,
    String? recipientName,
    String? recipientPhone,
    String? notes,
  }) async {
    try {
      final response = await SupabaseConfig.client.from('depot_items').insert({
        'depot_id': depotId,
        'reference': reference,
        'description': description,
        'weight_kg': weightKg,
        'recipient_name': recipientName,
        'recipient_phone': recipientPhone,
        'notes': notes,
      }).select().single();
      _logger.i('Depot item added');
      return DepotItem.fromJson(response);
    } catch (e) {
      _logger.e('Error adding depot item: $e');
      rethrow;
    }
  }

  Future<DepotItem> updateDepotItem({
    required String itemId,
    String? reference,
    String? description,
    double? weightKg,
    String? recipientName,
    String? recipientPhone,
    String? status,
    String? notes,
  }) async {
    try {
      final response = await SupabaseConfig.client
          .from('depot_items')
          .update({
            'reference': reference,
            'description': description,
            'weight_kg': weightKg,
            'recipient_name': recipientName,
            'recipient_phone': recipientPhone,
            'status': status,
            'notes': notes,
            'dispatched_at': status == 'dispatched'
                ? DateTime.now().toIso8601String()
                : status == 'stored'
                    ? null
                    : null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', itemId)
          .select()
          .single();
      _logger.i('Depot item updated: $itemId');
      return DepotItem.fromJson(response);
    } catch (e) {
      _logger.e('Error updating depot item: $e');
      rethrow;
    }
  }

  Future<void> deleteDepotItem(String itemId) async {
    try {
      await SupabaseConfig.client
          .from('depot_items')
          .delete()
          .eq('id', itemId);
      _logger.i('Depot item deleted: $itemId');
    } catch (e) {
      _logger.e('Error deleting depot item: $e');
      rethrow;
    }
  }

  /// Small stats for one depot: total items, stored/dispatched counts, total
  /// weight of stored parcels.
  Future<Map<String, dynamic>?> getDepotStats(String depotId) async {
    try {
      final items = await getDepotItems(depotId, limit: 1000);
      var stored = 0;
      var dispatched = 0;
      var returned = 0;
      var storedWeight = 0.0;
      for (final item in items) {
        switch (item.status) {
          case 'stored':
            stored++;
            storedWeight += item.weightKg;
          case 'dispatched':
            dispatched++;
          default:
            if (item.status == 'returned') returned++;
        }
      }
      return {
        'total': items.length,
        'stored': stored,
        'dispatched': dispatched,
        'returned': returned,
        'stored_weight_kg': storedWeight,
      };
    } catch (e) {
      _logger.e('Error getting depot stats: $e');
      return null;
    }
  }
}