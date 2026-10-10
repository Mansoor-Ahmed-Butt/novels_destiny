import 'dart:math';

import '../../domain/entities/content_block_entity.dart';
import '../utils/novel_text_helper.dart';

/// Injects illustration images and inline banner ad slots between episode text
/// according to the manuscript length (English and Urdu supported).
class EpisodeReaderAdPlacements {
  EpisodeReaderAdPlacements._();

  /// Target: exactly 4 banner ads for every individual episode story.
  static const int targetBannerAds = 4;

  /// Default line intervals
  static const int defaultLinesPerImage = 5;
  static const int defaultLinesPerAd = 8;

  /// Builds the sequential blocks for reading:
  /// 1. Splits story prose into clean lines/paragraphs (English & Urdu).
  /// 2. Distributes illustration images evenly between the text (after every 4-5 lines).
  /// 3. Distributes exactly 4 banner ads between the text.
  /// 4. Ensures ads and illustration images are never back-to-back.
  /// 5. Ensures NO banner ads are placed at the top of an episode.
  static List<ContentBlockEntity> forReading(
    List<ContentBlockEntity> source, {
    required String episodeId,
    bool injectAds = true,
  }) {
    if (source.isEmpty) return const [];

    // 1. Separate content block types
    final textBlocks = <ContentBlockEntity>[];
    final imageBlocks = <ContentBlockEntity>[];
    final pdfBlocks = <ContentBlockEntity>[];
    final manualAdBlocks = <ContentBlockEntity>[];

    for (final block in source) {
      switch (block.type) {
        case ContentBlockType.text:
          if (block.content.trim().isNotEmpty) {
            textBlocks.add(block);
          }
          break;
        case ContentBlockType.image:
          final url = block.url ?? '';
          if (url.isNotEmpty) {
            imageBlocks.add(block);
          }
          break;
        case ContentBlockType.pdf:
          pdfBlocks.add(block);
          break;
        case ContentBlockType.ad:
          manualAdBlocks.add(block);
          break;
      }
    }

    // 2. Normalize text into reading lines/paragraphs (Urdu and English supported)
    final textLines = <ContentBlockEntity>[];
    var lineIndex = 1;

    for (final textBlock in textBlocks) {
      final segments = NovelTextHelper.splitProseIntoLines(textBlock.content);
      for (final segment in segments) {
        textLines.add(
          ContentBlockEntity(
            id: '${textBlock.id}_line_$lineIndex',
            episodeId: episodeId,
            type: ContentBlockType.text,
            order: lineIndex,
            content: segment,
          ),
        );
        lineIndex++;
      }
    }

    // If there is no prose text, return images and other media
    if (textLines.isEmpty) {
      return _reindex([...imageBlocks, ...pdfBlocks]);
    }

    final totalLines = textLines.length;
    final totalImages = imageBlocks.length;

    // 3. Compute illustration image placement positions (after line at index 0..totalLines-1)
    // The user requested: after 4 to 5 lines display one image, divided depending on episode text length.
    final imageSlots = <int, ContentBlockEntity>{};
    if (totalImages > 0) {
      final assignedSlots = _calculateImagePositions(
        totalLines: totalLines,
        imageCount: totalImages,
      );

      for (var i = 0; i < totalImages && i < assignedSlots.length; i++) {
        final lineIndex = assignedSlots[i];
        imageSlots[lineIndex] = imageBlocks[i];
      }
    }

    // 4. Compute banner ad placement positions (strictly between story text)
    // The user requested: every individual episode story contains 4 banner ads distributed between the text.
    // NEVER placed at the top of the episode (requires reading prose first).
    final adSlots = <int>{};
    if (injectAds && totalLines >= 4) {
      final neededAds = (targetBannerAds - manualAdBlocks.length).clamp(1, targetBannerAds);
      final assignedAdSlots = _calculateAdPositions(
        totalLines: totalLines,
        adCount: neededAds,
        occupiedImageSlots: imageSlots.keys.toSet(),
      );
      adSlots.addAll(assignedAdSlots);
    }

    // 5. Interweave text lines, illustration images, and banner ads
    final result = <ContentBlockEntity>[];
    final remainingImages = List<ContentBlockEntity>.from(imageBlocks);
    var adSlotCounter = 1;

    for (var i = 0; i < totalLines; i++) {
      // Add the story text line first
      result.add(textLines[i]);

      // Check for illustration image after this line
      if (imageSlots.containsKey(i)) {
        final img = imageSlots[i]!;
        result.add(img);
        remainingImages.remove(img);
      }

      // Check for banner ad after this line (only between story text, never on top)
      if (adSlots.contains(i) && !imageSlots.containsKey(i)) {
        result.add(
          ContentBlockEntity(
            id: 'auto_ad_${episodeId}_slot_$adSlotCounter',
            episodeId: episodeId,
            type: ContentBlockType.ad,
            order: 0,
            placement: 'inline_auto',
          ),
        );
        adSlotCounter++;
      }
    }

    // Append any leftover illustration images that couldn't fit in the text
    for (final leftover in remainingImages) {
      result.add(leftover);
    }

    // Append any manual ad blocks
    result.addAll(manualAdBlocks);

    // Append any PDF documents
    result.addAll(pdfBlocks);

    return _reindex(result);
  }

  /// Calculates positions (0-indexed line after which to insert an illustration)
  /// ensuring images are spaced after every ~4 to 5 lines proportionally.
  static List<int> _calculateImagePositions({
    required int totalLines,
    required int imageCount,
  }) {
    final positions = <int>[];
    if (imageCount <= 0 || totalLines <= 0) return positions;

    if (totalLines <= imageCount) {
      for (var i = 0; i < imageCount; i++) {
        positions.add(min(i, totalLines - 1));
      }
      return positions;
    }

    // Calculate ideal step (typically 4 to 5 lines)
    for (var i = 0; i < imageCount; i++) {
      final proportionalTarget =
          ((i + 1) * totalLines / (imageCount + 1)).round() - 1;
      final minPosition = positions.isEmpty
          ? min(3, totalLines - 1)
          : positions.last + 1;
      final pos = max(minPosition, proportionalTarget).clamp(0, totalLines - 1);
      positions.add(pos);
    }

    return positions;
  }

  /// Calculates positions for 4 banner ads, strictly between story text.
  /// Never placed on top of the episode (line 0) and never trailing after the last line.
  static List<int> _calculateAdPositions({
    required int totalLines,
    int adCount = targetBannerAds,
    required Set<int> occupiedImageSlots,
  }) {
    final positions = <int>[];
    if (adCount <= 0 || totalLines <= 1) return positions;

    final actualAdCount = min(adCount, totalLines - 1);

    // The first ad can NEVER appear on top of the episode (line 0).
    // Ensure story prose is read before the first ad.
    // If long manuscript, start around line 4-6, if shorter, at least line 1.
    final firstAdMinIndex = totalLines >= 16 ? 4 : (totalLines >= 8 ? 2 : 1);

    for (var i = 0; i < actualAdCount; i++) {
      // Proportional spacing across the text: 1/5, 2/5, 3/5, 4/5
      final proportionalTarget =
          ((i + 1) * totalLines / (actualAdCount + 1)).round() - 1;

      final minPos = positions.isEmpty ? firstAdMinIndex : positions.last + 1;
      var candidate = max(minPos, proportionalTarget).clamp(minPos, totalLines - 1);

      // Collision avoidance with illustration images
      if (occupiedImageSlots.contains(candidate)) {
        if (candidate + 1 < totalLines &&
            !occupiedImageSlots.contains(candidate + 1) &&
            !positions.contains(candidate + 1)) {
          candidate = candidate + 1;
        } else if (candidate - 1 >= minPos &&
            !occupiedImageSlots.contains(candidate - 1) &&
            !positions.contains(candidate - 1)) {
          candidate = candidate - 1;
        }
      }

      // Ensure each ad has its own unique slot between story text
      while (positions.contains(candidate) && candidate + 1 < totalLines) {
        candidate++;
      }

      if (candidate < totalLines && !positions.contains(candidate)) {
        positions.add(candidate);
      }
    }

    return positions;
  }

  static List<ContentBlockEntity> _reindex(List<ContentBlockEntity> blocks) {
    return [
      for (var i = 0; i < blocks.length; i++) blocks[i].copyWith(order: i + 1),
    ];
  }
}
