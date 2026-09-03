import 'package:flutter/material.dart';

import 'models.dart';

/// Palier du programme de parrainage.
///
/// Chaque palier augmente la récompense par filleul qualifié et se débloque
/// automatiquement au fil des filleuls (colis livré + payé). Le parrain n'est
/// JAMAIS bloqué : il peut toujours partager son code.
enum ReferralTier {
  bronze('bronze', 'Bronze', 50, 0, Icons.emoji_events_outlined),
  argent('argent', 'Argent', 75, 3, Icons.emoji_events_rounded),
  or('or', 'Or', 100, 10, Icons.military_tech_rounded),
  platine('platine', 'Platine', 150, 25, Icons.workspace_premium_rounded);

  final String value;
  final String label;
  final int rewardPerQualified; // DZD par filleul qualifié
  final int minQualified; // nombre de filleuls qualifiés requis
  final IconData icon;

  const ReferralTier(
    this.value,
    this.label,
    this.rewardPerQualified,
    this.minQualified,
    this.icon,
  );

  static ReferralTier fromValue(String? v) {
    for (final t in ReferralTier.values) {
      if (t.value == v) return t;
    }
    return ReferralTier.bronze;
  }

  /// Le palier suivant (null si on est au plus haut).
  ReferralTier? get next =>
      ReferralTier.values.asMap()[ReferralTier.values.indexOf(this) + 1];
}

/// Statistiques de parrainage d'un utilisateur.
class ReferralStats {
  final String code;
  final int filleulsCount;
  final int qualifiedFilleuls; // avec ≥ 1 colis livré et payé
  final double totalPaid;
  final double totalPending;
  final ReferralTier tier;
  final String? lastBatchStatus; // pour l'historique des lots vidéos

  /// Récompense actuelle par filleul qualifié (selon le palier).
  int get rewardPerQualified => tier.rewardPerQualified;

  /// Nombre de filleuls qualifiés manquants pour passer au palier suivant.
  int get nextTierProgress {
    final n = tier.next;
    if (n == null) return 0;
    return n.minQualified - qualifiedFilleuls;
  }

  /// 0..1 — progression vers le palier suivant.
  double get nextTierFraction {
    final n = tier.next;
    if (n == null) return 1.0;
    final prevMin = tier.minQualified;
    final span = n.minQualified - prevMin;
    if (span <= 0) return 1.0;
    return ((qualifiedFilleuls - prevMin).clamp(0, span)) / span;
  }

  /// True si le parrain a suffisamment de filleuls qualifiés pour atteindre
  /// le niveau supérieur (le palier évolue automatiquement).
  bool get hasNextTier => tier.next != null;

  const ReferralStats({
    required this.code,
    required this.filleulsCount,
    required this.qualifiedFilleuls,
    required this.totalPaid,
    required this.totalPending,
    required this.tier,
    this.lastBatchStatus,
  });
}

/// Un filleul du parrain.
class ReferralFilleul {
  final User? user;
  final DateTime joinedAt;
  final double earned; // total généré par ce filleul
  final int completedBookings;

  String get name => user?.fullName ?? 'Client';
  String get email => user?.email ?? '';

  const ReferralFilleul({
    required this.user,
    required this.joinedAt,
    required this.earned,
    required this.completedBookings,
  });

  factory ReferralFilleul.fromJson(Map<String, dynamic> json) {
    return ReferralFilleul(
      user: json['users'] != null ? User.fromJson(json['users']) : null,
      joinedAt: DateTime.parse(json['created_at'] as String),
      earned: (json['earned'] as num?)?.toDouble() ?? 0,
      completedBookings: (json['completed_bookings'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Un gain de parrainage.
class ReferralEarning {
  final String id;
  final String parrainId;
  final String bookingId;
  final double amount;
  final String status; // pending, paid, cancelled
  final DateTime createdAt;
  final DateTime? paidAt;

  const ReferralEarning({
    required this.id,
    required this.parrainId,
    required this.bookingId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });

  factory ReferralEarning.fromJson(Map<String, dynamic> json) {
    return ReferralEarning(
      id: json['id'] as String,
      parrainId: json['parrain_id'] as String,
      bookingId: json['booking_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'] as String)
          : null,
    );
  }
}

/// Lot de vidéos témoignages (bonus optionnel Platine).
class ReferralBatch {
  final String id;
  final String parrainId;
  final int batchNumber;
  final List<String> videoUrls;
  final String status; // pending, approved, rejected, suspended
  final String? reviewNote;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  const ReferralBatch({
    required this.id,
    required this.parrainId,
    required this.batchNumber,
    required this.videoUrls,
    required this.status,
    this.reviewNote,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
  });

  factory ReferralBatch.fromJson(Map<String, dynamic> json) {
    return ReferralBatch(
      id: json['id'] as String,
      parrainId: json['parrain_id'] as String,
      batchNumber: (json['batch_number'] as num).toInt(),
      videoUrls: [
        if (json['video_url_1'] != null) json['video_url_1'] as String,
        if (json['video_url_2'] != null) json['video_url_2'] as String,
        if (json['video_url_3'] != null) json['video_url_3'] as String,
      ],
      status: json['status'] as String,
      reviewNote: json['review_note'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] == null
          ? null
          : DateTime.tryParse(json['reviewed_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Vue fondateur : un parrain et son wallet détaillé.
class ParrainOverview {
  final User? user;
  final String code;
  final int filleulsCount;
  final int qualifiedFilleuls;
  final double totalPending;
  final double totalPaid;
  final int pendingBatches;
  final String? lastBatchStatus;

  const ParrainOverview({
    required this.user,
    required this.code,
    required this.filleulsCount,
    required this.qualifiedFilleuls,
    required this.totalPending,
    required this.totalPaid,
    required this.pendingBatches,
    this.lastBatchStatus,
  });

  String get name => user?.fullName ?? '—';
  String get email => user?.email ?? '—';
  ReferralTier get tier => user?.referralTier != null
      ? ReferralTier.fromValue(user!.referralTier)
      : ReferralTier.bronze;
}
