import 'package:flutter_test/flutter_test.dart';
import 'package:novels_destiny/data/models/novel_model.dart';
import 'package:novels_destiny/data/sources/app_data_source.dart';
import 'package:novels_destiny/domain/entities/novel_entity.dart';
import 'package:novels_destiny/domain/entities/reading_progress_entity.dart';
import 'package:novels_destiny/domain/repositories/novel_repository.dart';
import 'package:novels_destiny/domain/usecases/novel_usecases.dart';

void main() {
  group('Novel Platform Domain & Data Tests', () {
    late AppDataSource dataSource;
    late NovelUseCases novelUseCases;

    setUp(() {
      dataSource = AppDataSource();
      dataSource.resetForTesting();
      dataSource.loadNovels(_testNovels);
      novelUseCases = NovelUseCases(_InMemoryNovelRepository(dataSource));
    });

    test('Loads featured and trending novels from repository', () async {
      final featured = await novelUseCases.getFeaturedNovels();
      expect(featured.isNotEmpty, true);
      expect(featured.any((n) => n.title == 'The Clockwork Alchemist'), true);

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

/// In-memory repository for unit tests (no Firebase).
class _InMemoryNovelRepository implements INovelRepository {
  _InMemoryNovelRepository(this._dataSource);

  final AppDataSource _dataSource;

  @override
  Future<List<NovelEntity>> getFeaturedNovels() => _dataSource.getFeaturedNovels();

  @override
  Future<List<NovelEntity>> getTrendingNovels() => _dataSource.getTrendingNovels();

  @override
  Future<List<NovelEntity>> getNovelsByGenre(String genre) => _dataSource.getNovelsByGenre(genre);

  @override
  Future<List<NovelEntity>> searchNovels(String query, {String? genre, String? status}) =>
      _dataSource.searchNovels(query, genre: genre, status: status);

  @override
  Future<NovelEntity?> getNovelById(String id) => _dataSource.getNovelById(id);

  @override
  Future<List<NovelEntity>> getNovelsByWriter(String writerId) => _dataSource.getNovelsByWriter(writerId);

  @override
  Future<NovelEntity> createNovel(NovelEntity novel) => _dataSource.saveNovel(NovelModel.fromEntity(novel));

  @override
  Future<NovelEntity> updateNovel(NovelEntity novel) => _dataSource.saveNovel(NovelModel.fromEntity(novel));

  @override
  Future<void> deleteNovel(String id) => _dataSource.deleteNovel(id);

  @override
  Future<bool> isNovelLiked(String novelId, String userId) async => _dataSource.isNovelLiked(novelId, userId);

  @override
  Future<void> toggleLikeNovel(String novelId, String userId) async {
    _dataSource.toggleLikeNovel(novelId, userId);
  }

  @override
  Future<bool> isNovelSaved(String novelId, String userId) async => _dataSource.isNovelSaved(novelId, userId);

  @override
  Future<void> toggleSaveNovel(String novelId, String userId) async {
    _dataSource.toggleSaveNovel(novelId, userId);
  }

  @override
  Future<List<NovelEntity>> getSavedNovels(String userId) async => _dataSource.getSavedNovels(userId);

  @override
  Future<void> saveReadingProgress(String userId, ReadingProgressEntity progress) async {
    throw UnimplementedError();
  }

  @override
  Future<ReadingProgressEntity?> getReadingProgress(String userId, String novelId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ReadingProgressEntity>> getReadingHistory(String userId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> recordDownload(String userId, String novelId) async {
    _dataSource.recordDownload(userId, novelId);
  }

  @override
  Future<List<NovelEntity>> getDownloadedNovels(String userId) async => _dataSource.getDownloadedNovels(userId);
}

final _testNovels = [
  NovelModel(
    id: 'novel_1',
    writerId: 'writer_1',
    writerName: 'Test Writer',
    title: 'The Clockwork Alchemist',
    titleLowercase: 'the clockwork alchemist',
    description: 'A test novel for repository behavior.',
    coverUrl: 'https://example.com/cover.jpg',
    genreIds: const ['Romance', 'Fantasy'],
    tags: const ['clockwork', 'alchemy'],
    totalViews: 500,
    moderationStatus: ModerationStatus.approved,
    status: NovelStatus.ongoing,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  ),
  NovelModel(
    id: 'novel_2',
    writerId: 'writer_2',
    writerName: 'Other Writer',
    title: 'Harbor Lights',
    titleLowercase: 'harbor lights',
    description: 'Second test novel with lower view count.',
    coverUrl: 'https://example.com/cover2.jpg',
    genreIds: const ['Drama'],
    tags: const ['harbor'],
    totalViews: 120,
    moderationStatus: ModerationStatus.approved,
    status: NovelStatus.ongoing,
    createdAt: DateTime(2024, 2, 1),
    updatedAt: DateTime(2024, 2, 1),
  ),
];
