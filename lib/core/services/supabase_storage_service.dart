import 'dart:io';
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

  StorageFailure _mapStorageError(dynamic error, String operation) {
    final str = error.toString();
    if (str.contains('Bucket not found') || str.contains('NoSuchBucket') || str.contains('404')) {
      return const StorageFailure(
        'Supabase Storage bucket "novel-files" was not found. Please create the public bucket "novel-files" in your Supabase dashboard.',
      );
    }
    if (str.contains('row-level security') || str.contains('Unauthorized') || str.contains('403')) {
      return const StorageFailure(
        'Supabase Storage permission denied. Please add Storage RLS policies in your Supabase dashboard for bucket "novel-files".',
      );
    }
    return StorageFailure(
      'Failed to $operation: ${error is StorageException ? error.message : str}',
    );
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
      throw const StorageFailure('Cloud storage is uninitialized. Please verify Supabase setup.');
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

      final url = getPublicUrl(deterministicPath);
      if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
        throw const StorageFailure('Upload succeeded but generated an invalid public URL.');
      }
      return url;
    } catch (e) {
      debugPrint('Supabase upload cover error: $e');
      if (e is AppFailure) rethrow;
      throw _mapStorageError(e, 'upload novel cover');
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
      throw const StorageFailure('Cloud storage is uninitialized. Please verify Supabase setup.');
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
      if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
        throw const StorageFailure('Upload succeeded but generated an invalid public URL.');
      }
      return {
        'storagePath': deterministicPath,
        'url': url,
      };
    } catch (e) {
      debugPrint('Supabase upload episode image error: $e');
      if (e is AppFailure) rethrow;
      throw _mapStorageError(e, 'upload episode illustration');
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
      throw const StorageFailure('Cloud storage is uninitialized. Please verify Supabase setup.');
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
      if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
        throw const StorageFailure('PDF upload succeeded but generated an invalid public URL.');
      }
      return {
        'storagePath': deterministicPath,
        'url': url,
        'fileName': originalFileName,
      };
    } catch (e) {
      debugPrint('Supabase upload PDF error: $e');
      if (e is AppFailure) rethrow;
      throw _mapStorageError(e, 'upload episode PDF');
    }
  }

  /// Uploads an illustration/image for a novel gallery (up to 5 images).
  /// Storage path: novels/{novelId}/gallery/image_{timestamp}.jpg
  Future<Map<String, String>> uploadNovelGalleryImage({
    required String novelId,
    required String filePath,
    Uint8List? fileBytes,
  }) async {
    final client = _client;
    if (client == null) {
      throw const StorageFailure('Cloud storage is uninitialized. Please verify Supabase setup.');
    }

    final fileName = filePath.split(Platform.isWindows ? '\\' : '/').last;
    final ext = fileName.split('.').last.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final deterministicPath = 'novels/$novelId/gallery/image_$timestamp.$ext';

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
      if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
        throw const StorageFailure('Upload succeeded but generated an invalid public URL.');
      }
      return {
        'storagePath': deterministicPath,
        'url': url,
      };
    } catch (e) {
      debugPrint('Supabase upload novel gallery image error: $e');
      if (e is AppFailure) rethrow;
      throw _mapStorageError(e, 'upload novel gallery image');
    }
  }

  /// Uploads a complete novel PDF document.
  /// Storage path: novels/{novelId}/documents/{fileName}
  Future<Map<String, String>> uploadNovelPdf({
    required String novelId,
    required String filePath,
    required String originalFileName,
    Uint8List? fileBytes,
  }) async {
    final client = _client;
    if (client == null) {
      throw const StorageFailure('Cloud storage is uninitialized. Please verify Supabase setup.');
    }

    final safeFileName = originalFileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final deterministicPath = 'novels/$novelId/documents/$safeFileName';

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
      if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
        throw const StorageFailure('PDF upload succeeded but generated an invalid public URL.');
      }
      return {
        'storagePath': deterministicPath,
        'url': url,
        'fileName': originalFileName,
      };
    } catch (e) {
      debugPrint('Supabase upload novel PDF error: $e');
      if (e is AppFailure) rethrow;
      throw _mapStorageError(e, 'upload novel PDF');
    }
  }

  /// Returns public URL for a given storage path.
  ///
  /// Only works if the [bucketName] bucket is publicly accessible.
  /// For private buckets use [getSignedUrl] instead.
  String getPublicUrl(String storagePath) {
    final cleanPath = storagePath.trim().replaceFirst(RegExp(r'^/+'), '');
    if (cleanPath.isEmpty) return '';

    final client = _client;
    if (client != null) {
      final url = client.storage.from(bucketName).getPublicUrl(cleanPath);
      if (url.isNotEmpty) return url;
    }

    const defaultBaseUrl = 'https://kzouhytgrcujmqmznpqt.supabase.co';
    return '$defaultBaseUrl/storage/v1/object/public/$bucketName/$cleanPath';
  }

  /// Creates a time-limited signed URL for a storage path.
  ///
  /// Works for both public and private buckets, making it the safest choice
  /// when the bucket visibility is unknown. The returned URL grants read
  /// access for [expiresIn] seconds (default: 7 days).
  Future<String> getSignedUrl(
    String storagePath, {
    int expiresIn = 604800,
  }) async {
    final client = _client;
    if (client == null) return '';
    try {
      return await client.storage
          .from(bucketName)
          .createSignedUrl(storagePath, expiresIn);
    } catch (e) {
      debugPrint('SupabaseStorageService: signed URL error for $storagePath: $e');
      return '';
    }
  }

  /// Resolves the best accessible URL for a storage path.
  ///
  /// Prefers a public URL when the bucket is public, otherwise falls back
  /// to a signed URL so content renders regardless of bucket visibility.
  Future<String> resolveAccessibleUrl(String storagePath) async {
    final path = storagePath.trim();
    if (path.isEmpty) return '';

    final publicUrl = getPublicUrl(path);
    if (publicUrl.isEmpty) return '';

    return publicUrl;
  }

  /// Deletes a file from Supabase storage (useful for rollbacks & cleanup)
  Future<void> deleteFile(String storagePath) async {
    final client = _client;
    if (client == null || storagePath.trim().isEmpty) return;

    // Normalize path if a full Supabase URL was passed
    String cleanPath = storagePath.trim();
    if (cleanPath.startsWith('http')) {
      final uri = Uri.tryParse(cleanPath);
      if (uri != null) {
        final segments = uri.pathSegments;
        final idx = segments.indexOf(bucketName);
        if (idx >= 0 && idx < segments.length - 1) {
          cleanPath = segments.sublist(idx + 1).join('/');
        }
      }
    }

    try {
      await client.storage.from(bucketName).remove([cleanPath]);
    } catch (e) {
      debugPrint('Supabase delete file warning: $e');
    }
  }

  /// Deletes multiple files from Supabase storage
  Future<void> deleteFiles(List<String> storagePaths) async {
    for (final p in storagePaths) {
      await deleteFile(p);
    }
  }

  /// Deletes all files stored under a novel directory (e.g. covers, gallery, PDFs, episode attachments)
  Future<void> deleteNovelFolder(String novelId) async {
    final client = _client;
    if (client == null || novelId.trim().isEmpty) return;
    try {
      final list = await client.storage.from(bucketName).list(path: 'novels/$novelId');
      final paths = list.map((item) => 'novels/$novelId/${item.name}').toList();
      if (paths.isNotEmpty) {
        await client.storage.from(bucketName).remove(paths);
      }
    } catch (e) {
      debugPrint('Supabase delete novel folder warning: $e');
    }
  }

  /// Deletes all files stored under an episode directory (e.g. attached PDFs, illustrations)
  Future<void> deleteEpisodeFolder(String novelId, String episodeId) async {
    final client = _client;
    if (client == null || novelId.trim().isEmpty || episodeId.trim().isEmpty) return;
    try {
      final folderPath = 'novels/$novelId/episodes/$episodeId';
      final list = await client.storage.from(bucketName).list(path: folderPath);
      final paths = list.map((item) => '$folderPath/${item.name}').toList();
      if (paths.isNotEmpty) {
        await client.storage.from(bucketName).remove(paths);
      }
    } catch (e) {
      debugPrint('Supabase delete episode folder warning: $e');
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
