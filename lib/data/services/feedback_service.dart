// ============================================================================
// FEEDBACK SERVICE — any authenticated user (all roles) can send feedback
// (annotated screenshot + text) to the founder.
// ============================================================================

import 'dart:typed_data';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

class FeedbackItem {
  final String id;
  final String userId;
  final String role;
  final String message;
  final String? screenshotUrl;
  final String? senderName;
  final String? senderEmail;
  final bool isRead;
  final DateTime createdAt;

  const FeedbackItem({
    required this.id,
    required this.userId,
    required this.role,
    required this.message,
    this.screenshotUrl,
    this.senderName,
    this.senderEmail,
    required this.isRead,
    required this.createdAt,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    final sender = json['users'] as Map<String, dynamic>?;
    return FeedbackItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'client',
      message: json['message'] as String? ?? '',
      screenshotUrl: json['screenshot_url'] as String?,
      senderName: sender?['full_name'] as String?,
      senderEmail: sender?['email'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class FeedbackService {
  SupabaseClient get _supabase => SupabaseConfig.client;
  final _logger = Logger();

  static const String bucket = 'feedbacks';

  /// Upload the annotated screenshot (bytes) and store the feedback row.
  /// Returns the persisted feedback id.
  Future<String> submit({
    required String userId,
    required String role,
    required String message,
    Uint8List? screenshotBytes,
  }) async {
    try {
      String? screenshotUrl;
      if (screenshotBytes != null && screenshotBytes.isNotEmpty) {
        final fileName =
            'feedback_${DateTime.now().millisecondsSinceEpoch}.png';
        final fullPath = '$userId/$fileName';
        await _supabase.storage.from(bucket).uploadBinary(
              fullPath,
              screenshotBytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
                contentType: 'image/png',
              ),
            );
        screenshotUrl =
            _supabase.storage.from(bucket).getPublicUrl(fullPath);
      }

      final response = await _supabase
          .from('feedbacks')
          .insert({
            'user_id': userId,
            'role': role,
            'message': message,
            'screenshot_url': screenshotUrl,
          })
          .select('id')
          .single();

      _logger.i('Feedback submitted (${response['id']})');
      return response['id'] as String;
    } catch (e) {
      _logger.e('Error submitting feedback: $e');
      rethrow;
    }
  }

  /// All feedback sent by everyone (founder/admin only — RLS enforced).
  Future<List<FeedbackItem>> getAll({int limit = 100, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('feedbacks')
          .select(
              '*, users!feedbacks_user_id_fkey(full_name, email, role)')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((e) => FeedbackItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      _logger.e('Error getting feedback: $e');
      return [];
    }
  }

  /// Count unread feedback (founder notification badge).
  Future<int> countUnread() async {
    try {
      final response = await _supabase
          .from('feedbacks')
          .select('id')
          .eq('is_read', false);
      return (response as List).length;
    } catch (e) {
      _logger.e('Error counting unread feedback: $e');
      return 0;
    }
  }

  /// Mark a feedback as read (founder/admin only).
  Future<void> markRead(String feedbackId) async {
    try {
      await _supabase
          .from('feedbacks')
          .update({'is_read': true}).eq('id', feedbackId);
    } catch (e) {
      _logger.e('Error marking feedback read: $e');
      rethrow;
    }
  }
}
