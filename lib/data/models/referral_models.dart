import 'models.dart';

/// Statistiques de parrainage d'un utilisateur.
class ReferralStats {
  final String code;
  final int filleulsCount;
  final int qualifiedFilleuls; // avec ≥ 1 colis livré et payé
  final double totalPaid;
  final double totalPending;
  final int nextBatchNumber;
  final String? lastBatchStatus; // pending/approved/rejected/suspended/null

  /// Le parrain peut soumettre un nouveau lot de vidéos :
  /// programme actif, pas de lot en attente, et assez de filleuls qualifiés
  /// (3 par lot) — sauf si le dernier lot a été suspendu/rejeté
  /// (il recommence : nouvelle soumission autorisée).
  bool get canSubmitBatch =>
      (lastBatchStatus == null || lastBatchStatus == 'approved') &&
      qualifiedFilleuls >= nextBatchNumber * 3;

  /// Bouton « Demander le parrainage suivant » : 3 clients + colis payés.
  bool get canRequestNextBatch => canSubmitBatch;

  const ReferralStats({
    required this.code,
    required this.filleulsCount,
    required this.qualifiedFilleuls,
    required this.totalPaid,
    required this.totalPending,
    required this.nextBatchNumber,
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
  final double amount;
  final String status; // pending, paid, cancelled
  final DateTime createdAt;
  final DateTime? paidAt;

  const ReferralEarning({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });

  factory ReferralEarning.fromJson(Map<String, dynamic> json) {
    return ReferralEarning(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'] as String)
          : null,
    );
  }
}

/// Lot de vidéos témoignages soumises à validation admin.
class ReferralBatch {
  final String id;
  final int batchNumber;
  final List<String> videoUrls;
  final String status; // pending, approved, rejected, suspended
  final String? reviewNote;
  final DateTime createdAt;

  const ReferralBatch({
    required this.id,
    required this.batchNumber,
    required this.videoUrls,
    required this.status,
    this.reviewNote,
    required this.createdAt,
  });

  factory ReferralBatch.fromJson(Map<String, dynamic> json) {
    return ReferralBatch(
      id: json['id'] as String,
      batchNumber: (json['batch_number'] as num).toInt(),
      videoUrls: [
        if (json['video_url_1'] != null) json['video_url_1'] as String,
        if (json['video_url_2'] != null) json['video_url_2'] as String,
        if (json['video_url_3'] != null) json['video_url_3'] as String,
      ],
      status: json['status'] as String,
      reviewNote: json['review_note'] as String?,
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
}
