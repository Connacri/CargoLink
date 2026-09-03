import 'dart:math';

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../core/config/supabase_config.dart';
import '../models/models.dart';
import '../models/referral_models.dart';

/// Service du programme de parrainage CargoLink — version paliers.
///
/// Règles (v2) :
/// - Tout utilisateur (client ou expéditeur) devient parrain en générant son
///   code depuis son profil (si le programme est actif).
/// - Un filleul = un compte qui s'inscrit avec ce code (un seul parrain).
/// - Un filleul « qualifié » = il a au moins 1 colis livré ET payé.
/// - Gain automatique (trigger SQL) = % de la commission plateforme reversé
///   dès que le colis du filleul est livré et payé.
/// - Le palier (Bronze/Argent/Or/Platine) évolue AUTOMATIQUEMENT selon le
///   nombre de filleuls qualifiés. Il n'est JAMAIS bloquant : le parrain peut
///   toujours parrainer et retirer ses gains.
/// - Les vidéos témoignages deviennent un BONUS optionnel (sans gating).
class ReferralService {
  SupabaseClient get _supabase => SupabaseConfig.client;
  final _logger = Logger();

  static const _alphabet =
      'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sans 0/O/1/I ambigus

  /// Code saisi à l'inscription, appliqué à la première session authentifiée.
  static const _pendingCodeKey = 'pending_referral_code';

  /// Mémorise le code saisi au signup (avant même la vérification email).
  Future<void> savePendingCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingCodeKey, code.trim().toUpperCase());
  }

  /// Applique puis supprime le code en attente — appelé une fois par session
  /// authentifiée (hook dans [currentUserProvider]). Silencieux en cas d'échec.
  Future<void> consumePendingCode(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_pendingCodeKey);
    if (code == null || code.isEmpty) return;
    await prefs.remove(_pendingCodeKey);
    try {
      await applyReferralCode(filleulId: userId, code: code);
    } catch (_) {
      // Code invalide / déjà parrainé : on ignore silencieusement,
      // la clé est de toute façon consommée.
    }
  }

  /// Le programme est-il actif ? (interrupteur fondateur)
  Future<bool> isProgramActive() async {
    try {
      final row = await _supabase
          .from('platform_settings')
          .select('value')
          .eq('key', 'referral_program_active')
          .maybeSingle();
      return (row?['value'] as String?)?.toLowerCase() == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Code de parrainage de l'utilisateur — généré au premier appel.
  Future<String> getOrCreateMyCode(String userId) async {
    try {
      final existing = await _supabase
          .from('referral_codes')
          .select('code')
          .eq('user_id', userId)
          .maybeSingle();
      if (existing != null) return existing['code'] as String;

      for (var attempt = 0; attempt < 5; attempt++) {
        final code = _generateCode();
        try {
          await _supabase
              .from('referral_codes')
              .insert({'user_id': userId, 'code': code});
          return code;
        } catch (_) {
          // Collision rare sur le code unique → nouvel essai.
        }
      }
      throw Exception('Impossible de générer un code unique');
    } catch (e) {
      _logger.e('Error getOrCreateMyCode: $e');
      rethrow;
    }
  }

  String _generateCode() {
    final rnd = Random.secure();
    return List.generate(
        8, (_) => _alphabet[rnd.nextInt(_alphabet.length)]).join();
  }

  /// Applique un code de parrainage pour le compte courant (filleul).
  /// Idempotent : sans effet si déjà rattaché ou auto-parrainage.
  Future<bool> applyReferralCode({
    required String filleulId,
    required String code,
  }) async {
    try {
      final trimmed = code.trim().toUpperCase();
      if (trimmed.isEmpty) return false;

      // Le code DOIT exister. (RLS: code_sel)
      final owner = await _supabase
          .from('referral_codes')
          .select('user_id')
          .eq('code', trimmed)
          .maybeSingle();
      final parrainId = owner?['user_id'] as String?;
      if (parrainId == null || parrainId == filleulId) return false;

      final already = await _supabase
          .from('referrals')
          .select('id')
          .eq('filleul_id', filleulId)
          .maybeSingle();
      if (already != null) return false;

      await _supabase
          .from('referrals')
          .insert({'parrain_id': parrainId, 'filleul_id': filleulId});
      return true;
    } catch (e) {
      _logger.e('Error applyReferralCode: $e');
      return false;
    }
  }

  /// Statistiques complètes du parrain connecté.
  Future<ReferralStats> getMyStats(String userId) async {
    final code = await getOrCreateMyCode(userId);

    final filleuls = await _supabase
        .from('referrals')
        .select('id')
        .eq('parrain_id', userId);
    final filleulsCount = (filleuls as List).length;

    final earnings = await _supabase
        .from('referral_earnings')
        .select('amount,status,bookings(client_id)')
        .eq('parrain_id', userId);
    double paid = 0, pending = 0;
    final qualifiedClientIds = <String>{};
    for (final e in (earnings as List)) {
      final a = (e['amount'] as num).toDouble();
      if (e['status'] == 'paid') {
        paid += a;
      } else if (e['status'] == 'pending') {
        pending += a;
      }
      if (e['status'] != 'cancelled') {
        final clientId =
            (e['bookings'] as Map<String, dynamic>?)?['client_id'] as String?;
        if (clientId != null) qualifiedClientIds.add(clientId);
      }
    }

    // Le palier est stocké sur users (mis à jour par trigger SQL).
    final me = await _supabase
        .from('users')
        .select('referral_tier')
        .eq('id', userId)
        .maybeSingle();
    final tierValue = me?['referral_tier'] as String?;

    return ReferralStats(
      code: code,
      filleulsCount: filleulsCount,
      qualifiedFilleuls: qualifiedClientIds.length,
      totalPaid: paid,
      totalPending: pending,
      tier: ReferralTier.fromValue(tierValue),
      lastBatchStatus: null,
    );
  }

  /// Liste des filleuls avec leurs gains cumulés.
  Future<List<ReferralFilleul>> getMyFilleuls(String parrainId) async {
    try {
      final refs = await _supabase
          .from('referrals')
          .select('created_at, users!referrals_filleul_id_fkey(*)')
          .eq('parrain_id', parrainId)
          .order('created_at', ascending: false);

      // Gains regroupés par filleul via bookings.client_id.
      final earns = await _supabase
          .from('referral_earnings')
          .select('amount, status, bookings(client_id)')
          .eq('parrain_id', parrainId);
      final perFilleul = <String, ({double earned, int count})>{};
      for (final e in (earns as List)) {
        if (e['status'] == 'cancelled') continue;
        final clientId =
            (e['bookings'] as Map<String, dynamic>?)?['client_id'] as String?;
        if (clientId == null) continue;
        final cur = perFilleul[clientId] ?? (earned: 0.0, count: 0);
        perFilleul[clientId] = (
          earned: cur.earned + ((e['amount'] as num?)?.toDouble() ?? 0),
          count: cur.count + 1,
        );
      }

      return (refs as List).map((r) {
        final userJson = r['users'] as Map<String, dynamic>?;
        final uid = userJson?['id'] as String?;
        final stat = perFilleul[uid] ?? (earned: 0.0, count: 0);
        return ReferralFilleul(
          user: userJson != null ? User.fromJson(userJson) : null,
          joinedAt: DateTime.parse(r['created_at'] as String),
          earned: stat.earned,
          completedBookings: stat.count,
        );
      }).toList();
    } catch (e) {
      _logger.e('Error getMyFilleuls: $e');
      return [];
    }
  }

  /// Soumission d'un lot de 3 vidéos témoignages — BONUS optionnel.
  /// Ne bloque plus le parrainage : simplement soumet le lot pour bonus.
  Future<void> submitBatch({
    required String parrainId,
    required List<String> videoUrls,
  }) async {
    if (videoUrls.length < 3) {
      throw Exception('3 liens de vidéos sont requis');
    }
    final existingPending = await _supabase
        .from('referral_batches')
        .select('id')
        .eq('parrain_id', parrainId)
        .eq('status', 'pending')
        .maybeSingle();
    if (existingPending != null) {
      throw Exception('Un lot est déjà en attente de validation.');
    }
    final batches = await _supabase
        .from('referral_batches')
        .select('batch_number')
        .eq('parrain_id', parrainId)
        .order('batch_number', ascending: false)
        .limit(1);
    final nextNum =
        (batches as List).isNotEmpty ? ((batches[0]['batch_number'] as num).toInt() + 1) : 1;

    await _supabase.from('referral_batches').insert({
      'parrain_id': parrainId,
      'batch_number': nextNum,
      'video_url_1': videoUrls[0],
      'video_url_2': videoUrls[1],
      'video_url_3': videoUrls[2],
    });
  }

  /// Historique des lots du parrain.
  Future<List<ReferralBatch>> getMyBatches(String parrainId) async {
    try {
      final rows = await _supabase
          .from('referral_batches')
          .select()
          .eq('parrain_id', parrainId)
          .order('batch_number', ascending: false);
      return (rows as List)
          .map((r) => ReferralBatch.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getMyBatches: $e');
      return [];
    }
  }

  // ==========================================================================
  // CÔTÉ FONDATEUR
  // ==========================================================================

  /// Vue d'ensemble de TOUS les parrains avec wallets détaillés.
  Future<List<ParrainOverview>> getAllParrainsOverview() async {
    try {
      final codes = await _supabase.from('referral_codes').select('user_id,code');
      final referrals = await _supabase
          .from('referrals')
          .select('parrain_id,filleul_id');
      final earnings = await _supabase
          .from('referral_earnings')
          .select('parrain_id,amount,status');
      final batches = await _supabase
          .from('referral_batches')
          .select('parrain_id,batch_number,status');

      final userIds = <String>{
        for (final c in (codes as List)) c['user_id'] as String,
        for (final r in (referrals as List)) r['parrain_id'] as String,
      }.toList();

      Map<String, dynamic>? userOf(String id) => _userCache[id];
      final overviews = <ParrainOverview>[];
      for (final uid in userIds) {
        dynamic codeRow;
        for (final c in (codes as List)) {
          if (c['user_id'] == uid) {
            codeRow = c;
            break;
          }
        }
        if (codeRow == null) continue;
        final myReferrals = (referrals as List)
            .where((r) => r['parrain_id'] == uid)
            .toList();
        final myEarnings = (earnings as List)
            .where((e) => e['parrain_id'] == uid)
            .toList();
        final myBatches = (batches as List)
            .where((b) => b['parrain_id'] == uid)
            .toList()
          ..sort((a, b) => ((a['batch_number'] as num).toInt())
              .compareTo((b['batch_number'] as num).toInt()));

        double pend = 0, paid = 0;
        for (final e in myEarnings) {
          final a = (e['amount'] as num).toDouble();
          if (e['status'] == 'paid') {
            paid += a;
          } else if (e['status'] == 'pending') {
            pend += a;
          }
        }

        overviews.add(ParrainOverview(
          user: userOf(uid) != null ? User.fromJson(userOf(uid)!) : null,
          code: codeRow['code'] as String,
          filleulsCount: myReferrals.length,
          qualifiedFilleuls: myEarnings.length,
          totalPending: pend,
          totalPaid: paid,
          pendingBatches:
              myBatches.where((b) => b['status'] == 'pending').length,
          lastBatchStatus:
              myBatches.isNotEmpty ? myBatches.last['status'] as String : null,
        ));
      }
      overviews.sort((a, b) =>
          (b.totalPaid + b.totalPending).compareTo(a.totalPaid + a.totalPending));
      return overviews;
    } catch (e) {
      _logger.e('Error getAllParrainsOverview: $e');
      rethrow;
    }
  }

  static final Map<String, Map<String, dynamic>> _userCache = {};

  /// Charge les profils users nécessaires à la vue fondateur.
  Future<void> prefetchUsers(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      final rows = await _supabase
          .from('users')
          .select('id,email,full_name,role,profile_picture_url,referral_tier')
          .inFilter('id', ids);
      for (final r in (rows as List)) {
        _userCache[r['id'] as String] = r as Map<String, dynamic>;
      }
    } catch (_) {}
  }

  /// Lots de vidéos en attente de validation.
  Future<List<Map<String, dynamic>>> getPendingBatchesWithUsers() async {
    try {
      final rows = await _supabase
          .from('referral_batches')
          .select(
              '*, users!referral_batches_parrain_id_fkey(id,email,full_name)')
          .inFilter('status', ['pending', 'approved', 'rejected', 'suspended'])
          .order('created_at', ascending: false)
          .limit(100);
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.e('Error getPendingBatchesWithUsers: $e');
      return [];
    }
  }

  /// Validation / rejet / suspension d'un lot par le fondateur.
  Future<void> reviewBatch({
    required String batchId,
    required String status, // approved | rejected | suspended
    String? note,
  }) async {
    await _supabase.from('referral_batches').update({
      'status': status,
      'review_note': note,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', batchId);
  }

  /// Marque un gain comme payé (wallet parrain).
  Future<void> markEarningPaid(String earningId) async {
    await _supabase.from('referral_earnings').update({
      'status': 'paid',
      'paid_at': DateTime.now().toIso8601String(),
    }).eq('id', earningId);
  }

  /// Annule un gain (fraude, colis remboursé…).
  Future<void> cancelEarning(String earningId) async {
    await _supabase
        .from('referral_earnings')
        .update({'status': 'cancelled'}).eq('id', earningId);
  }

  /// Liste des gains avec infos parrain + booking (vue fondateur).
  Future<List<Map<String, dynamic>>> getEarningsWithDetails() async {
    try {
      final rows = await _supabase
          .from('referral_earnings')
          .select(
              '*, users!referral_earnings_parrain_id_fkey(email,full_name), bookings(total_price,tracking_number)')
          .order('created_at', ascending: false)
          .limit(200);
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.e('Error getEarningsWithDetails: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // SUIVI COLIS DES FILLEULS (lecture seule)
  // ==========================================================================

  /// Récupère les réservations en cours d'un filleul (client) — lecture seule
  /// pour que le parrain puisse suivre les livraisons sans y toucher.
  Future<List<Map<String, dynamic>>> getFilleulBookings(
      String clientId) async {
    try {
      final rows = await _supabase
          .from('bookings')
          .select(
              'id, product_name, status, payment_status, allocated_weight_kg, '
              'total_price, tracking_number, created_at, delivered_at, '
              'shipments(destination_city, origin_country, departure_date, '
              'arrival_date, shippers(user_id))')
          .eq('client_id', clientId)
          .neq('status', 'cancelled')
          .order('created_at', ascending: false)
          .limit(20);
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.e('Error getFilleulBookings: $e');
      return [];
    }
  }

  /// Demande de paiement des gains en attente d'un parrain — crée une
  /// notification pour le fondateur (ou les admins).
  Future<void> requestPayout({
    required String parrainId,
    required double amount,
  }) async {
    try {
      // Insérer une notification pour tous les admins/super_admins.
      final admins = await _supabase
          .from('users')
          .select('id')
          .inFilter('role', ['admin', 'super_admin']);

      final parrain = await _supabase
          .from('users')
          .select('full_name')
          .eq('id', parrainId)
          .maybeSingle();

      final parrainName =
          (parrain?['full_name'] as String?)?.trim();
      final displayName =
          parrainName != null && parrainName.isNotEmpty
              ? parrainName
              : 'Un parrain';

      for (final admin in admins as List) {
        await _supabase.from('notifications').insert({
          'user_id': admin['id'],
          'type': 'payout_request',
          'title': 'Demande de paiement parrain',
          'message':
              '$displayName demande le paiement de '
              '${amount.toStringAsFixed(0)} DZD de gains parrainage.',
          'related_booking_id': null,
        });
      }
    } catch (e) {
      _logger.e('Error requesting payout: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // PALIERS — lecture
  // ==========================================================================

  /// Historique des changements de palier d'un parrain.
  Future<List<Map<String, dynamic>>> getTierHistory(String userId) async {
    try {
      final rows = await _supabase
          .from('referral_tier_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.e('Error getTierHistory: $e');
      return [];
    }
  }

  /// Synchronise manuellement le palier d'un parrain (utile après import).
  Future<void> syncTier(String parrainId) async {
    await _supabase.rpc('sync_user_referral_tier', params: {
      'target_user_id': parrainId,
    });
  }
}
