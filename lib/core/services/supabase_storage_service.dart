import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../errors/failures.dart';

class SupabaseStorageService {
  static const String bucketName = 'novel-files';
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxPdfSizeBytes = 50 * 1024 * 1024;   // 50 MB

  SupabaseClient? get _client => SupabaseService().client;

  /// Validates an image file before upload
  void validateImageFile({required int sizeBytes, required String fileName}) {
    if (sizeBytes > maxImageSizeBytes) {
      throw const ValidationFailure('Image exceeds maximum allowed size of 10 MB.');
    }
    final ext = fileName.split('.').last.toLowerCase();
    const validExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    if (!validExtensions.contains(ext)) {
      throw const ValidationFailure('Invalid image format. Supported formats: JPG, PNG, WEBP.');
    }
  }

  /// Validates a PDF file before upload
  void validatePdfFile({required int sizeBytes, required String fileName}) {
    if (sizeBytes > maxPdfSizeBytes) {
      throw const ValidationFailure('PDF exceeds maximum allowed size of 50 MB.');
    }
    final ext = fileName.split('.').last.toLowerCase();
    if (ext != 'pdf') {
      throw const ValidationFailure('File must be a valid PDF document.');
    }
  }

  /// Uploads a novel cover image.
  /// Storage path: novels/{novelId}/cover.jpg
  Future<String> uploadNovelCover({
    required String novelId,
    required String filePath,
    Uint8List? fileBytes,
  }) async {
    final client = _client;
    if (client == null) {
      debugPrint('SupabaseStorageService: Supabase not initialized, skipping cover upload.');
      return '';
    }

    final fileName = filePath.split(Platform.isWindows ? '\\' : '/').last;
    final ext = fileName.split('.').last.toLowerCase();
    final deterministicPath = 'novels/$novelId/cover.$ext';

    Uint8List bytes;
    if (fileBytes != null) {
      bytes = fileBytes;
    } else {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const NotFoundFailure('Cover image file does not exist.');
      }
      bytes = await file.readAsBytes();
    }

    validateImageFile(sizeBytes: bytes.length, fileName: fileName);

    try {
      await client.storage.from(bucketName).uploadBinary(
            deterministicPath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _resolveContentType(ext),
            ),
          );

      return getPublicUrl(deterministicPath);
    } catch (e) {
      debugPrint('Supabase upload cover error: $e');
      throw UnknownFailure('Failed to upload cover image. Please check your connection and try again.');
    }
  }

  /// Uploads an episode inline image.
  /// Storage path: novels/{novelId}/episodes/{episodeId}/image_{timestamp}.jpg
  Future<Map<String, String>> uploadEpisodeImage({
    required String novelId,
    required String episodeId,
    required String filePath,
    Uint8List? fileBytes,
  }) async {
    final client = _client;
    if (client == null) {
      debugPrint('SupabaseStorageService: Supabase not initialized, skipping image upload.');
      return {};
    }

    final fileName = filePath.split(Platform.isWindows ? '\\' : '/').last;
    final ext = fileName.split('.').last.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final deterministicPath = 'novels/$novelId/episodes/$episodeId/image_$timestamp.$ext';

    Uint8List bytes;
    if (fileBytes != null) {
      bytes = fileBytes;
    } else {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const NotFoundFailure('Selected image file does not exist.');
      }
      bytes = await file.readAsBytes();
    }

    validateImageFile(sizeBytes: bytes.length, fileName: fileName);

    try {
      await client.storage.from(bucketName).uploadBinary(
            deterministicPath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _resolveContentType(ext),
            ),
          );

      final url = getPublicUrl(deterministicPath);
      return {
        'storagePath': deterministicPath,
        'url': url,
      };
    } catch (e) {
      debugPrint('Supabase upload episode image error: $e');
      throw UnknownFailure('Failed to upload episode image. Please try again.');
    }
  }

  /// Uploads an episode PDF document.
  /// Storage path: novels/{novelId}/episodes/{episodeId}/episode.pdf
  Future<Map<String, String>> uploadEpisodePdf({
    required String novelId,
    required String episodeId,
    required String filePath,
    required String originalFileName,
    Uint8List? fileBytes,
  }) async {
    final client = _client;
    if (client == null) {
      debugPrint('SupabaseStorageService: Supabase not initialized, skipping PDF upload.');
      return {};
    }

    final safeFileName = originalFileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final deterministicPath = 'novels/$novelId/episodes/$episodeId/$safeFileName';

    Uint8List bytes;
    if (fileBytes != null) {
      bytes = fileBytes;
    } else {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const NotFoundFailure('Selected PDF file does not exist.');
      }
      bytes = await file.readAsBytes();
    }

    validatePdfFile(sizeBytes: bytes.length, fileName: originalFileName);

    try {
      await client.storage.from(bucketName).uploadBinary(
            deterministicPath,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'application/pdf',
            ),
          );

      final url = getPublicUrl(deterministicPath);
      return {
        'storagePath': deterministicPath,
        'url': url,
        'fileName': originalFileName,
      };
    } catch (e) {
      debugPrint('Supabase upload PDF error: $e');
      throw UnknownFailure('Failed to upload PDF episode. Please check connection and try again.');
    }
  }

  /// Returns public URL for a given storage path
  String getPublicUrl(String storagePath) {
    final client = _client;
    if (client == null) return '';
    return client.storage.from(bucketName).getPublicUrl(storagePath);
  }

  /// Deletes a file from Supabase storage (useful for rollbacks & cleanup)
  Future<void> deleteFile(String storagePath) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.storage.from(bucketName).remove([storagePath]);
    } catch (e) {
      debugPrint('Supabase delete file warning: $e');
    }
  }

  String _resolveContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
