import 'package:flutter_test/flutter_test.dart';
import 'package:novels_destiny/core/services/episode_reader_ad_placements.dart';
import 'package:novels_destiny/domain/entities/content_block_entity.dart';

void main() {
  group('EpisodeReaderAdPlacements', () {
    test('injects at least three banner slots for long text episodes', () {
      final paragraphs = List.generate(
        20,
        (i) => 'Paragraph ${i + 1} with enough prose to simulate a real chapter.',
      );

      final source = [
        ContentBlockEntity(
          id: 'text_main',
          episodeId: 'ep_1',
          type: ContentBlockType.text,
          order: 1,
          content: paragraphs.join('\n\n'),
        ),
      ];

      final withAds = EpisodeReaderAdPlacements.forReading(
        source,
        episodeId: 'ep_1',
      );

      final adCount =
          withAds.where((b) => b.type == ContentBlockType.ad).length;
      expect(adCount, greaterThanOrEqualTo(3));
      expect(adCount, lessThanOrEqualTo(4));
    });

    test('respects manually placed ad blocks when already sufficient', () {
      final source = <ContentBlockEntity>[
        ContentBlockEntity(
          id: 't1',
          episodeId: 'ep_2',
          type: ContentBlockType.text,
          order: 1,
          content: 'Opening paragraph.',
        ),
        for (var i = 0; i < 3; i++)
          ContentBlockEntity(
            id: 'ad_$i',
            episodeId: 'ep_2',
            type: ContentBlockType.ad,
            order: i + 2,
            placement: 'inline',
          ),
      ];

      final withAds = EpisodeReaderAdPlacements.forReading(
        source,
        episodeId: 'ep_2',
      );

      expect(
        withAds.where((b) => b.type == ContentBlockType.ad).length,
        3,
      );
    });
  });
}
