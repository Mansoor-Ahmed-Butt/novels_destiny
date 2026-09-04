import 'package:flutter_test/flutter_test.dart';
import 'package:novels_destiny/data/sources/app_data_source.dart';
import 'package:novels_destiny/data/repositories/novel_repository_impl.dart';
import 'package:novels_destiny/domain/usecases/novel_usecases.dart';

void main() {
  group('Novel Platform Domain & Data Tests', () {
    late AppDataSource dataSource;
    late NovelRepositoryImpl novelRepo;
    late NovelUseCases novelUseCases;

    setUp(() {
      dataSource = AppDataSource();
      novelRepo = NovelRepositoryImpl(dataSource);
      novelUseCases = NovelUseCases(novelRepo);
    });

    test('Loads featured and trending novels from repository', () async {
      final featured = await novelUseCases.getFeaturedNovels();
      expect(featured.isNotEmpty, true);
      expect(featured.first.title, 'The Clockwork Alchemist');

      final trending = await novelUseCases.getTrendingNovels();
      expect(trending.isNotEmpty, true);
      expect(trending.first.totalViews, greaterThanOrEqualTo(trending.last.totalViews));
    });

    test('Searches novels by query and genre accurately', () async {
      final queryResults = await novelUseCases.searchNovels('clockwork');
      expect(queryResults.length, 1);
      expect(queryResults.first.title, 'The Clockwork Alchemist');

      final genreResults = await novelUseCases.getNovelsByGenre('Romance');
      expect(genreResults.isNotEmpty, true);
      expect(genreResults.first.genreIds.contains('Romance'), true);
    });

    test('Reader can like and bookmark novels', () async {
      const testUserId = 'test_user_99';
      final isLikedInitial = await novelUseCases.isNovelLiked('novel_1', testUserId);
      expect(isLikedInitial, false);

      await novelUseCases.toggleLikeNovel('novel_1', testUserId);
      final isLikedAfter = await novelUseCases.isNovelLiked('novel_1', testUserId);
      expect(isLikedAfter, true);

      await novelUseCases.toggleSaveNovel('novel_1', testUserId);
      final saved = await novelUseCases.getSavedNovels(testUserId);
      expect(saved.any((n) => n.id == 'novel_1'), true);
    });

    // NOTE: The full-app widget test (NovelsDestinyApp) is intentionally omitted
    // from unit test suite because it requires real Firebase + Supabase initialization.
    // Integration tests (flutter drive) should be used instead for end-to-end UI testing.
  });
}
