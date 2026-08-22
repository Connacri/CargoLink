import '../models/models.dart';
import '../../core/config/supabase_config.dart';
import './auth_service.dart';
import 'package:logger/logger.dart';

// ============================================================================
// ADS SERVICE (bannières publicitaires en haut des accueil client/expéditeur)
//
// Deux parcours :
//  - Admin / fondateur : publie directement une pub active et gratuite.
//  - Expéditeur : soumet une pub (pending) -> l'admin approuve
//    (awaiting_payment) -> l'expéditeur déclare son paiement (RPC) ->
//    l'admin confirme (active). La base force ces transitions côté RLS.
// ============================================================================

class AdsService {
  final _logger = Logger();

  /// Public listing: live ads for a home feed. [audience] filtre par rôle
  /// ('clients' ou 'shippers') — les pubs 'all' sont toujours incluses.
  Future<List<Ad>> getActiveAds({String? audience, int limit = 10}) async {
    try {
      final audiences =
          (audience == null || audience == 'all') ? ['all'] : ['all', audience];
      var query = SupabaseConfig.client
          .from('ads')
          .select()
          .eq('status', Ad.statusActive)
          .eq('is_active', true)
          .inFilter('audience', audiences);
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      // Les pubs expirées (période dépassée) ne sont plus affichées.
      final now = DateTime.now();
      return (response as List)
          .map((item) => Ad.fromJson(item as Map<String, dynamic>))
          .where((ad) => ad.expiresAt == null || ad.expiresAt!.isAfter(now))
          .toList();
    } catch (e) {
      _logger.e('Error getting active ads: $e');
      return [];
    }
  }

  /// Admin / founder listing: every ad whatever its status, newest first.
  Future<List<Ad>> getAllAds({int limit = 100, int offset = 0}) async {
    try {
      final response = await SupabaseConfig.client
          .from('ads')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (response as List)
          .map((item) => Ad.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting all ads: $e');
      return [];
    }
  }

  /// Ads submitted by the current user (shipper "Mes publicités").
  Future<List<Ad>> getMyAds({int limit = 50}) async {
    try {
      final userId = AuthService().currentUserId;
      if (userId == null || userId.isEmpty) return [];
      final response = await SupabaseConfig.client
          .from('ads')
          .select()
          .eq('created_by', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((item) => Ad.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting my ads: $e');
      return [];
    }
  }

  /// Nombre de pubs expéditeur en attente de validation — alimente la carte
  /// « Publicités à valider » des dashboards admin et fondateur.
  Future<int> countPendingAds() async {
    try {
      final response = await SupabaseConfig.client
          .from('ads')
          .select('id')
          .eq('status', Ad.statusPending);
      return (response as List).length;
    } catch (e) {
      _logger.e('Error counting pending ads: $e');
      return 0;
    }
  }

  /// Upload-free creation: storage upload is handled by the caller.
  ///
  /// - Admin/super_admin : la pub naît [Ad.statusActive] et gratuite.
  /// - Expéditeur : la base force [Ad.statusPending] + prix recalculé par
  ///   trigger selon la durée choisie (7 j = 2000, 15 j = 3500, 30 j = 6000).
  Future<Ad> createAd({
    required String imageUrl,
    required String linkUrl,
    required String audience,
    String? title,
    int durationDays = 7,
    bool activateImmediately = false,
  }) async {
    try {
      // Le client Supabase est configuré avec l'option `accessToken` (pont
      // Firebase) : on récupère l'ID via Firebase, pas via supabase.auth.
      final userId = AuthService().currentUserId;
      final response = await SupabaseConfig.client.from('ads').insert({
        'image_url': imageUrl,
        'link_url': linkUrl,
        'audience': audience,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        'created_by': userId,
        'duration_days': durationDays,
        // Les admins demandent une pub en ligne directe ; pour un expéditeur
        // la base écrase ce statut en 'pending'.
        'status': activateImmediately ? Ad.statusActive : Ad.statusPending,
        'is_active': activateImmediately,
      }).select().single();

      _logger.i('Ad created: ${response['id']}');
      return Ad.fromJson(response);
    } catch (e) {
      _logger.e('Error creating ad: $e');
      rethrow;
    }
  }

  /// pending -> awaiting_payment (admin).
  Future<void> approveAd(String adId) async {
    try {
      await SupabaseConfig.client.from('ads').update({
        'status': Ad.statusAwaitingPayment,
        'reviewed_by': AuthService().currentUserId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'rejection_reason': null,
      }).eq('id', adId);
      _logger.i('Ad approved: $adId');
    } catch (e) {
      _logger.e('Error approving ad: $e');
      rethrow;
    }
  }

  /// pending/awaiting_payment -> rejected avec motif (admin).
  Future<void> rejectAd(String adId, String reason) async {
    try {
      await SupabaseConfig.client.from('ads').update({
        'status': Ad.statusRejected,
        'is_active': false,
        'reviewed_by': AuthService().currentUserId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'rejection_reason': reason,
      }).eq('id', adId);
      _logger.i('Ad rejected: $adId');
    } catch (e) {
      _logger.e('Error rejecting ad: $e');
      rethrow;
    }
  }

  /// awaiting_payment -> active : confirme la réception du paiement (admin).
  Future<void> confirmPayment(String adId) async {
    try {
      await SupabaseConfig.client.from('ads').update({
        'status': Ad.statusActive,
        'is_active': true,
      }).eq('id', adId);
      _logger.i('Ad payment confirmed: $adId');
    } catch (e) {
      _logger.e('Error confirming ad payment: $e');
      rethrow;
    }
  }

  /// Déclaration de paiement par l'expéditeur (RPC security definer).
  Future<void> declarePayment(String adId) async {
    try {
      await SupabaseConfig.client
          .rpc('declare_ad_payment', params: {'p_ad_id': adId});
      _logger.i('Ad payment declared by owner: $adId');
    } catch (e) {
      _logger.e('Error declaring ad payment: $e');
      rethrow;
    }
  }

  /// Toggle an ad's visibility flag (admin only, enforced by RLS).
  Future<void> setAdActive(String adId, bool active) async {
    try {
      await SupabaseConfig.client
          .from('ads')
          .update({'is_active': active}).eq('id', adId);
      _logger.i('Ad $adId active=$active');
    } catch (e) {
      _logger.e('Error updating ad: $e');
      rethrow;
    }
  }

  /// Delete an ad (admin, ou propriétaire tant que non active — via RLS).
  Future<void> deleteAd(String adId) async {
    try {
      await SupabaseConfig.client.from('ads').delete().eq('id', adId);
      _logger.i('Ad deleted: $adId');
    } catch (e) {
      _logger.e('Error deleting ad: $e');
      rethrow;
    }
  }
}
