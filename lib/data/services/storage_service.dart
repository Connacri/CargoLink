import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../../core/config/supabase_config.dart';
import '../../core/constants/app_constants.dart';
import 'package:path/path.dart' as p;

class StorageService {
  SupabaseClient get _supabase => SupabaseConfig.client;
  final _logger = Logger();

  // Buckets
  static const String profileBucket = 'profiles';
  static const String documentsBucket = 'documents';
  static const String bookingsBucket = 'bookings';

  // ============================================================================
  // UPLOAD METHODS
  // ============================================================================

  /// Supabase Storage n'accepte que des clés « sûres » : ASCII, sans espaces,
  /// accents ni parenthèses. Les sélecteurs de fichiers (surtout Windows)
  /// renvoient souvent des noms comme « scaled_télécharger (3).jfif » → on
  /// assainit systématiquement avant de construire la clé finale.
  String _sanitizeFileName(String fileName) {
    final ext =
        p.extension(fileName).toLowerCase().replaceAll(RegExp(r'[^a-z0-9.]'), '');
    var base = p.basenameWithoutExtension(fileName)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (base.isEmpty) base = 'file';
    return '${DateTime.now().millisecondsSinceEpoch}_$base$ext';
  }

  /// Upload image file
  Future<String> uploadImage({
    required File file,
    required String path,
    String bucket = bookingsBucket,
  }) async {
    try {
      _logger.i('Uploading image to $bucket/$path');

      final fileName = _sanitizeFileName(p.basename(file.path));
      final fullPath = '$path/$fileName';

      await _supabase.storage.from(bucket).uploadBinary(
            fullPath,
            await file.readAsBytes(),
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final url = _supabase.storage.from(bucket).getPublicUrl(fullPath);

      _logger.i('Image uploaded successfully');
      return url;
    } catch (e) {
      _logger.e('Error uploading image: $e');
      rethrow;
    }
  }

  /// Upload image bytes (cross-platform : mobile et web). Sur le web, l'XFile
  /// renvoyé par image_picker pointe vers un blob URL illisible par `dart:io`,
  /// donc on upload directement les octets récupérés via `xfile.readAsBytes()`.
  Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String path,
    required String fileName,
    String bucket = bookingsBucket,
  }) async {
    try {
      _logger.i('Uploading image bytes to $bucket/$path');

      final safeName = _sanitizeFileName(fileName);
      final fullPath = '$path/$safeName';

      await _supabase.storage.from(bucket).uploadBinary(
            fullPath,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final url = _supabase.storage.from(bucket).getPublicUrl(fullPath);

      _logger.i('Image uploaded successfully');
      return url;
    } catch (e) {
      _logger.e('Error uploading image bytes: $e');
      rethrow;
    }
  }

  /// Upload passport document
  Future<String> uploadPassportDocument({
    required File file,
    required String userId,
  }) async {
    try {
      _logger.i('Uploading passport document');

      final fileName = 'passport_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final fullPath = 'passports/$userId/$fileName';

      await _supabase.storage.from(documentsBucket).uploadBinary(
            fullPath,
            await file.readAsBytes(),
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final url = _supabase.storage.from(documentsBucket).getPublicUrl(fullPath);

      _logger.i('Passport document uploaded');
      return url;
    } catch (e) {
      _logger.e('Error uploading passport: $e');
      rethrow;
    }
  }

  /// Upload profile picture
  Future<String> uploadProfilePicture({
    required File file,
    required String userId,
  }) async {
    try {
      _logger.i('Uploading profile picture');

      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fullPath = 'avatars/$userId/$fileName';

      await _supabase.storage.from(profileBucket).uploadBinary(
            fullPath,
            await file.readAsBytes(),
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final url = _supabase.storage.from(profileBucket).getPublicUrl(fullPath);

      _logger.i('Profile picture uploaded');
      return url;
    } catch (e) {
      _logger.e('Error uploading profile picture: $e');
      rethrow;
    }
  }

  /// Upload dispute evidence photos
  Future<List<String>> uploadDisputePhotos({
    required List<File> files,
    required String disputeId,
  }) async {
    try {
      _logger.i('Uploading ${files.length} dispute evidence photos');

      List<String> urls = [];

      for (var file in files) {
        final fileName =
            'evidence_${DateTime.now().millisecondsSinceEpoch}_${files.indexOf(file)}.jpg';
        final fullPath = 'disputes/$disputeId/$fileName';

        await _supabase.storage.from(bookingsBucket).uploadBinary(
              fullPath,
              await file.readAsBytes(),
              fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
            );

        final url = _supabase.storage.from(bookingsBucket).getPublicUrl(fullPath);
        urls.add(url);
      }

      _logger.i('Dispute photos uploaded');
      return urls;
    } catch (e) {
      _logger.e('Error uploading dispute photos: $e');
      rethrow;
    }
  }

  /// Upload a delivery / receipt proof photo linked to a booking.
  Future<String> uploadBookingProofPhoto({
    required File file,
    required String bookingId,
    required String type, // 'delivery' or 'receipt'
  }) async {
    try {
      _logger.i('Uploading $type proof photo for booking $bookingId');

      final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fullPath = 'proofs/$bookingId/$fileName';

      await _supabase.storage.from(bookingsBucket).uploadBinary(
            fullPath,
            await file.readAsBytes(),
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final url =
          _supabase.storage.from(bookingsBucket).getPublicUrl(fullPath);

      _logger.i('Proof photo uploaded');
      return url;
    } catch (e) {
      _logger.e('Error uploading proof photo: $e');
      rethrow;
    }
  }

  // ============================================================================
  // DELETE METHODS
  // ============================================================================

  /// Delete file
  Future<void> deleteFile({
    required String path,
    String bucket = bookingsBucket,
  }) async {
    try {
      _logger.i('Deleting file from $bucket/$path');

      await _supabase.storage.from(bucket).remove([path]);

      _logger.i('File deleted successfully');
    } catch (e) {
      _logger.e('Error deleting file: $e');
      rethrow;
    }
  }

  /// Delete folder
  Future<void> deleteFolder({
    required String path,
    String bucket = bookingsBucket,
  }) async {
    try {
      _logger.i('Deleting folder from $bucket/$path');

      final files = await _supabase.storage.from(bucket).list(path: path);

      for (var file in files) {
        await deleteFile(path: '$path/${file.name}', bucket: bucket);
      }

      _logger.i('Folder deleted successfully');
    } catch (e) {
      _logger.e('Error deleting folder: $e');
      rethrow;
    }
  }

  // ============================================================================
  // GET METHODS
  // ============================================================================

  /// Get public URL
  String getPublicUrl({
    required String path,
    String bucket = bookingsBucket,
  }) {
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  /// Get signed URL (for private files)
  Future<String> getSignedUrl({
    required String path,
    String bucket = bookingsBucket,
    Duration expiresIn = const Duration(hours: 24),
  }) async {
    try {
      final url = await _supabase.storage
          .from(bucket)
          .createSignedUrl(path, expiresIn.inSeconds);

      return url;
    } catch (e) {
      _logger.e('Error getting signed URL: $e');
      rethrow;
    }
  }

  /// List files in directory
  Future<List<FileObject>> listFiles({
    required String path,
    String bucket = bookingsBucket,
  }) async {
    try {
      final files = await _supabase.storage.from(bucket).list(path: path);
      return files;
    } catch (e) {
      _logger.e('Error listing files: $e');
      return [];
    }
  }

  // ============================================================================
  // UTILITIES
  // ============================================================================

  /// Validate image file
  bool isValidImageFile(File file) {
    final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    final extension = p.extension(file.path).toLowerCase().replaceFirst('.', '');

    return validExtensions.contains(extension) &&
        file.lengthSync() <= AppConstants.maxFileSize;
  }

  /// Validate PDF file
  bool isValidPdfFile(File file) {
    final extension = p.extension(file.path).toLowerCase().replaceFirst('.', '');
    return extension == 'pdf' && file.lengthSync() <= AppConstants.maxFileSize;
  }

  /// Get file size in MB
  double getFileSizeInMB(File file) {
    return file.lengthSync() / (1024 * 1024);
  }

  /// Create unique file name
  String createUniqueFileName(String originalFileName) {
    final extension = p.extension(originalFileName);
    return '${DateTime.now().millisecondsSinceEpoch}$extension';
  }
}
