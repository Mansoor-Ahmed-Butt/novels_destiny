import 'package:flutter_test/flutter_test.dart';
import 'package:novels_destiny/core/services/episode_reader_ad_placements.dart';
import 'package:novels_destiny/core/utils/novel_text_helper.dart';
import 'package:novels_destiny/domain/entities/content_block_entity.dart';

void main() {
  group('NovelTextHelper', () {
    test('detects Urdu text accurately', () {
      expect(
        NovelTextHelper.isUrduText('یہ ایک اردو ناول کی کہانی کا آغاز ہے'),
        isTrue,
      );
      expect(
        NovelTextHelper.isUrduText('This is an English novel chapter.'),
        isFalse,
      );
    });

    test('splits English and Urdu prose into clean reading lines', () {
      final englishProse = '''
      The evening shadows lengthened across the quiet mountain pass.
      Kael gripped the hilt of his starlight blade.
      A sudden rustle broke the silence of the pines.
      ''';
      final englishLines = NovelTextHelper.splitProseIntoLines(englishProse);
      expect(englishLines.length, 3);

      final urduProse = '''
      رات کی تاریکی چاروں طرف پھیل چکی تھی۔
      اس نے آہستہ سے کھڑکی کا پردہ سرکایا اور باہر دیکھا۔
      دور سڑک پر مدہم سی روشنی دکھائی دے رہی تھی۔
      ''';
      final urduLines = NovelTextHelper.splitProseIntoLines(urduProse);
      expect(urduLines.length, 3);
    });
  });

  group('EpisodeReaderAdPlacements', () {
    test(
      'distributes 5 illustration images between text lines instead of clustering at the top',
      () {
        // Simulate 25 lines of prose
        final paragraphs = List.generate(
          25,
          (i) =>
              'Line ${i + 1} of the story manuscript prose describing the adventure.',
        );

        // Admin uploaded 5 illustration images
        final images = List.generate(
          5,
          (i) => ContentBlockEntity(
            id: 'img_${i + 1}',
            episodeId: 'ep_1',
            type: ContentBlockType.image,
            order: i + 1,
            url: 'https://example.com/illustration_${i + 1}.jpg',
            caption: 'Illustration ${i + 1}',
          ),
        );

        final source = [
          ...images, // Note: even if images were at the front of source!
          ContentBlockEntity(
            id: 'text_main',
            episodeId: 'ep_1',
            type: ContentBlockType.text,
            order: 6,
            content: paragraphs.join('\n'),
          ),
        ];

        final blocks = EpisodeReaderAdPlacements.forReading(
          source,
          episodeId: 'ep_1',
          injectAds: true,
        );

        // 1. The very first block MUST BE STORY TEXT (not an illustration at the top!)
        expect(blocks.first.type, ContentBlockType.text);

        // 2. All 5 images must be present in the output
        final imageResults = blocks
            .where((b) => b.type == ContentBlockType.image)
            .toList();
        expect(imageResults.length, 5);

        // 3. Sequential order of illustrations is preserved
        for (var i = 0; i < 5; i++) {
          expect(imageResults[i].id, 'img_${i + 1}');
        }

        // 4. Images must not be directly adjacent to one another
        for (var i = 0; i < blocks.length - 1; i++) {
          if (blocks[i].type == ContentBlockType.image) {
            expect(blocks[i + 1].type, isNot(ContentBlockType.image));
          }
        }

        // 5. Exactly 4 banner ads are distributed
        final adCount = blocks
            .where((b) => b.type == ContentBlockType.ad)
            .length;
        expect(adCount, 4);

        // 6. Banner ads and illustrations must not be directly adjacent
        for (var i = 0; i < blocks.length - 1; i++) {
          if (blocks[i].type == ContentBlockType.ad) {
            expect(blocks[i + 1].type, isNot(ContentBlockType.image));
          }
          if (blocks[i].type == ContentBlockType.image) {
            expect(blocks[i + 1].type, isNot(ContentBlockType.ad));
          }
        }
      },
    );

    test('distributes ads and illustrations for Urdu novel chapters', () {
      final urduLines = List.generate(
        24,
        (i) =>
            'سطر نمبر ${i + 1}: یہ کہانی کے دلکش مناظر کا احوال بیان کرتی ہے۔',
      );

      final images = List.generate(
        3,
        (i) => ContentBlockEntity(
          id: 'urdu_img_$i',
          episodeId: 'urdu_ep',
          type: ContentBlockType.image,
          order: i + 1,
          url: 'https://example.com/urdu_$i.jpg',
        ),
      );

      final source = [
        ContentBlockEntity(
          id: 'urdu_text',
          episodeId: 'urdu_ep',
          type: ContentBlockType.text,
          order: 1,
          content: urduLines.join('\n'),
        ),
        ...images,
      ];

      final blocks = EpisodeReaderAdPlacements.forReading(
        source,
        episodeId: 'urdu_ep',
        injectAds: true,
      );

      expect(blocks.first.type, ContentBlockType.text);
      expect(blocks.where((b) => b.type == ContentBlockType.image).length, 3);
      expect(
        blocks.where((b) => b.type == ContentBlockType.ad).length,
        4,
      );
    });

    test(
      'never places banner ads at the top of an episode and distributes 4 banner ads across prose',
      () {
        // 1. Episode with only 3 lines (less than 4 lines) -> no ads placed
        final shortProse = List.generate(
          3,
          (i) => 'Line ${i + 1} of a short episode.',
        ).join('\n');
        final shortBlocks = EpisodeReaderAdPlacements.forReading(
          [
            ContentBlockEntity(
              id: 'short_t',
              episodeId: 'short_ep',
              type: ContentBlockType.text,
              order: 1,
              content: shortProse,
            ),
          ],
          episodeId: 'short_ep',
          injectAds: true,
        );
        expect(
          shortBlocks.where((b) => b.type == ContentBlockType.ad).length,
          0,
        );

        // 2. Episode with 24 lines -> first ad only appears after prose and exactly 4 banner ads exist
        final normalProse = List.generate(
          24,
          (i) => 'Line ${i + 1} of normal chapter prose.',
        ).join('\n');
        final normalBlocks = EpisodeReaderAdPlacements.forReading(
          [
            ContentBlockEntity(
              id: 'norm_t',
              episodeId: 'norm_ep',
              type: ContentBlockType.text,
              order: 1,
              content: normalProse,
            ),
          ],
          episodeId: 'norm_ep',
          injectAds: true,
        );

        expect(
          normalBlocks.where((b) => b.type == ContentBlockType.ad).length,
          4,
        );

        final firstAdIndex = normalBlocks.indexWhere(
          (b) => b.type == ContentBlockType.ad,
        );
        expect(firstAdIndex, greaterThanOrEqualTo(4)); // Never on top!
        expect(
          normalBlocks[firstAdIndex].id,
          'auto_ad_norm_ep_slot_1',
        ); // Deterministic slot ID
      },
    );
  });
}
