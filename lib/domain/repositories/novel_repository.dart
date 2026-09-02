import '../entities/novel_entity.dart';
import '../entities/reading_progress_entity.dart';

abstract class INovelRepository {
  Future<List<NovelEntity>> getFeaturedNovels();
  Future<List<NovelEntity>> getTrendingNovels();
  Future<List<NovelEntity>> getNovelsByGenre(String genre);
  Future<List<NovelEntity>> searchNovels(String query, {String? genre, String? status});
  Future<NovelEntity?> getNovelById(String id);
  Future<List<NovelEntity>> getNovelsByWriter(String writerId);
  Future<NovelEntity> createNovel(NovelEntity novel);
  Future<NovelEntity> updateNovel(NovelEntity novel);
  Future<void> deleteNovel(String id);

  // Reader interactions
  Future<bool> isNovelLiked(String novelId, String userId);
  Future<void> toggleLikeNovel(String novelId, String userId);
  Future<bool> isNovelSaved(String novelId, String userId);
  Future<void> toggleSaveNovel(String novelId, String userId);
  Future<List<NovelEntity>> getSavedNovels(String userId);

  // Reading progress & downloads
  Future<void> saveReadingProgress(String userId, ReadingProgressEntity progress);
  Future<ReadingProgressEntity?> getReadingProgress(String userId, String novelId);
  Future<List<ReadingProgressEntity>> getReadingHistory(String userId);
  Future<void> recordDownload(String userId, String novelId);
  Future<List<NovelEntity>> getDownloadedNovels(String userId);
}
