import '../../domain/entities/content_block_entity.dart';
import '../services/supabase_storage_service.dart';

/// Resolves Supabase public URLs for episode content blocks (images, PDFs).
class ContentBlockUrlResolver {
  ContentBlockUrlResolver._();

  /// Prefer an existing https URL; otherwise build one from [storagePath].
  ///
  /// This is the synchronous fast path used during build. It only generates
  /// public URLs. For buckets that are not publicly readable, use
  /// [resolveUrl] (async) which falls back to a signed URL.
  static String resolvePublicUrl({String? url, String? storagePath}) {
    final trimmed = (url ?? '').trim();
    final path = (storagePath ?? '').trim();

    if (path.isNotEmpty) {
      final public = SupabaseStorageService().getPublicUrl(path);
      if (public.isNotEmpty) return public;
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    return trimmed;
  }

  /// Resolves an accessible URL for a block.
  ///
  /// If the block already carries a network URL it is returned as-is. Otherwise
  /// a signed URL is generated from [storagePath]. Signed URLs work for both
  /// public and private buckets, so content always renders regardless of the
  /// bucket visibility policy.
  static Future<String> resolveUrl({String? url, String? storagePath}) async {
    final trimmed = (url ?? '').trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final path = (storagePath ?? '').trim();
    if (path.isEmpty) return trimmed;

    final signed = await SupabaseStorageService().getSignedUrl(path);
    if (signed.isNotEmpty) return signed;

    // Last-resort public URL (works only when the bucket is public).
    final public = SupabaseStorageService().getPublicUrl(path);
    return public.isNotEmpty ? public : trimmed;
  }

  static bool hasNetworkImage(ContentBlockEntity block) {
    if (block.type != ContentBlockType.image) return false;
    final resolved = resolvePublicUrl(url: block.url, storagePath: block.storagePath);
    return resolved.startsWith('http://') || resolved.startsWith('https://');
  }

  static ContentBlockEntity withResolvedUrls(ContentBlockEntity block) {
    if (block.type != ContentBlockType.image && block.type != ContentBlockType.pdf) {
      return block;
    }
    final resolved = resolvePublicUrl(url: block.url, storagePath: block.storagePath);
    if (resolved.isEmpty || resolved == block.url) return block;
    return block.copyWith(url: resolved);
  }

  /// Async variant of [withResolvedUrls] that also tries signed URLs for
  /// storage paths whose public URL is not accessible.
  static Future<ContentBlockEntity> withResolvedUrlsAsync(ContentBlockEntity block) async {
    if (block.type != ContentBlockType.image && block.type != ContentBlockType.pdf) {
      return block;
    }
    final resolved = await resolveUrl(url: block.url, storagePath: block.storagePath);
    if (resolved.isEmpty || resolved == block.url) return block;
    return block.copyWith(url: resolved);
  }

  static List<ContentBlockEntity> hydrateBlocks(List<ContentBlockEntity> blocks) {
    return blocks.map(withResolvedUrls).toList();
  }

  static Future<List<ContentBlockEntity>> hydrateBlocksAsync(List<ContentBlockEntity> blocks) async {
    final result = <ContentBlockEntity>[];
    for (final block in blocks) {
      result.add(await withResolvedUrlsAsync(block));
    }
    return result;
  }
}
