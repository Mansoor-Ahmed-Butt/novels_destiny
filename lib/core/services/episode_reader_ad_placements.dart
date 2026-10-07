import 'package:uuid/uuid.dart';

import '../../domain/entities/content_block_entity.dart';

/// Injects inline banner ad slots while reading — not persisted to Firestore.
class EpisodeReaderAdPlacements {
  EpisodeReaderAdPlacements._();

  static const int minBannerAds = 3;
  static const int maxBannerAds = 4;

  /// Default spacing: one banner after every N text paragraphs.
  static const int defaultParagraphsPerAd = 5;

  static List<ContentBlockEntity> forReading(
    List<ContentBlockEntity> source, {
    required String episodeId,
    bool injectAds = true,
  }) {
    if (source.isEmpty) return source;

    final normalized = _normalizeBlocks(source, episodeId);
    if (!injectAds) return _reindex(normalized);
    final existingAds =
        normalized.where((b) => b.type == ContentBlockType.ad).length;
    if (existingAds >= minBannerAds) {
      return _reindex(normalized);
    }

    final targetTotal = _resolveTargetAdCount(normalized);
    final adsToInsert = (targetTotal - existingAds).clamp(0, maxBannerAds);
    if (adsToInsert == 0) return _reindex(normalized);

    return _reindex(_injectInlineAds(normalized, episodeId, adsToInsert));
  }

  static int _resolveTargetAdCount(List<ContentBlockEntity> blocks) {
    final paragraphCount = blocks
        .where((b) =>
            b.type == ContentBlockType.text && b.content.trim().isNotEmpty)
        .length;

    if (paragraphCount <= 3) return minBannerAds;
    if (paragraphCount <= 10) return 3;
    return maxBannerAds;
  }

  static List<ContentBlockEntity> _normalizeBlocks(
    List<ContentBlockEntity> source,
    String episodeId,
  ) {
    final result = <ContentBlockEntity>[];
    var order = 1;

    for (final block in source) {
      if (block.type == ContentBlockType.text) {
        final paragraphs = block.content
            .split(RegExp(r'\n\s*\n'))
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty);
        for (final paragraph in paragraphs) {
          result.add(
            ContentBlockEntity(
              id: '${block.id}_p_$order',
              episodeId: episodeId,
              type: ContentBlockType.text,
              order: order,
              content: paragraph,
            ),
          );
          order++;
        }
      } else {
        result.add(block.copyWith(order: order));
        order++;
      }
    }

    return result;
  }

  static List<ContentBlockEntity> _injectInlineAds(
    List<ContentBlockEntity> blocks,
    String episodeId,
    int adsToInsert,
  ) {
    final result = List<ContentBlockEntity>.from(blocks);
    final textPositions = <int>[];
    for (var i = 0; i < result.length; i++) {
      if (result[i].type == ContentBlockType.text &&
          result[i].content.trim().isNotEmpty) {
        textPositions.add(i);
      }
    }

    if (textPositions.isEmpty) {
      return _appendTrailingAds(result, episodeId, adsToInsert);
    }

    final interval = _paragraphInterval(textPositions.length, adsToInsert);
    var inserted = 0;
    var paragraphsRead = 0;
    var offset = 0;

    for (var t = 0; t < textPositions.length && inserted < adsToInsert; t++) {
      paragraphsRead++;
      if (paragraphsRead < interval) continue;

      final insertAt = textPositions[t] + 1 + offset;
      result.insert(
        insertAt,
        ContentBlockEntity(
          id: 'auto_ad_${episodeId}_${const Uuid().v4()}',
          episodeId: episodeId,
          type: ContentBlockType.ad,
          order: 0,
          placement: 'inline_auto',
        ),
      );
      inserted++;
      paragraphsRead = 0;
      offset++;
    }

    if (inserted < adsToInsert) {
      return _appendTrailingAds(result, episodeId, adsToInsert - inserted);
    }

    return result;
  }

  static int _paragraphInterval(int paragraphCount, int adCount) {
    if (adCount <= 0) return defaultParagraphsPerAd;
    final computed = (paragraphCount / (adCount + 1)).floor();
    return computed.clamp(2, defaultParagraphsPerAd);
  }

  static List<ContentBlockEntity> _appendTrailingAds(
    List<ContentBlockEntity> blocks,
    String episodeId,
    int count,
  ) {
    final result = List<ContentBlockEntity>.from(blocks);
    for (var i = 0; i < count; i++) {
      result.add(
        ContentBlockEntity(
          id: 'auto_ad_tail_${episodeId}_${const Uuid().v4()}',
          episodeId: episodeId,
          type: ContentBlockType.ad,
          order: 0,
          placement: 'inline_auto',
        ),
      );
    }
    return result;
  }

  static List<ContentBlockEntity> _reindex(List<ContentBlockEntity> blocks) {
    return [
      for (var i = 0; i < blocks.length; i++) blocks[i].copyWith(order: i + 1),
    ];
  }
}
