import '../entities/novel_entity.dart';
import '../entities/reading_progress_entity.dart';
import '../repositories/novel_repository.dart';

class NovelUseCases {
  final INovelRepository _novelRepository;

  NovelUseCases(this._novelRepository);

  Future<List<NovelEntity>> getFeaturedNovels() => _novelRepository.getFeaturedNovels();
  Future<List<NovelEntity>> getTrendingNovels() => _novelRepository.getTrendingNovels();
  Future<List<NovelEntity>> getNovelsByGenre(String genre) => _novelRepository.getNovelsByGenre(genre);
  Future<List<NovelEntity>> searchNovels(String query, {String? genre, String? status}) =>
      _novelRepository.searchNovels(query, genre: genre, status: status);
  Future<NovelEntity?> getNovelById(String id) => _novelRepository.getNovelById(id);
  Future<List<NovelEntity>> getNovelsByWriter(String writerId) => _novelRepository.getNovelsByWriter(writerId);
  Future<NovelEntity> createNovel(NovelEntity novel) => _novelRepository.createNovel(novel);
  Future<NovelEntity> updateNovel(NovelEntity novel) => _novelRepository.updateNovel(novel);
  Future<void> deleteNovel(String id) => _novelRepository.deleteNovel(id);

  // Likes & Library
  Future<bool> isNovelLiked(String novelId, String userId) => _novelRepository.isNovelLiked(novelId, userId);
  Future<void> toggleLikeNovel(String novelId, String userId) => _novelRepository.toggleLikeNovel(novelId, userId);
  Future<bool> isNovelSaved(String novelId, String userId) => _novelRepository.isNovelSaved(novelId, userId);
  Future<void> toggleSaveNovel(String novelId, String userId) => _novelRepository.toggleSaveNovel(novelId, userId);
  Future<List<NovelEntity>> getSavedNovels(String userId) => _novelRepository.getSavedNovels(userId);

  // Progress & Downloads
  Future<void> saveReadingProgress(String userId, ReadingProgressEntity progress) =>
      _novelRepository.saveReadingProgress(userId, progress);
  Future<ReadingProgressEntity?> getReadingProgress(String userId, String novelId) =>
      _novelRepository.getReadingProgress(userId, novelId);
  Future<List<ReadingProgressEntity>> getReadingHistory(String userId) =>
      _novelRepository.getReadingHistory(userId);
  Future<void> recordDownload(String userId, String novelId) => _novelRepository.recordDownload(userId, novelId);
  Future<List<NovelEntity>> getDownloadedNovels(String userId) => _novelRepository.getDownloadedNovels(userId);
}
