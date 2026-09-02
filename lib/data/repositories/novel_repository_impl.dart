import 'package:uuid/uuid.dart';
import '../../domain/entities/novel_entity.dart';
import '../../domain/entities/reading_progress_entity.dart';
import '../../domain/repositories/novel_repository.dart';
import '../sources/app_data_source.dart';
import '../models/novel_model.dart';
import '../models/reading_progress_model.dart';
import '../../core/errors/failures.dart';

class NovelRepositoryImpl implements INovelRepository {
  final AppDataSource _dataSource;

  NovelRepositoryImpl(this._dataSource);

  @override
  Future<List<NovelEntity>> getFeaturedNovels() async {
    try {
      return await _dataSource.getFeaturedNovels();
    } catch (e) {
      throw UnknownFailure('Failed to fetch featured novels: $e');
    }
  }

  @override
  Future<List<NovelEntity>> getTrendingNovels() async {
    try {
      return await _dataSource.getTrendingNovels();
    } catch (e) {
      throw UnknownFailure('Failed to fetch trending novels: $e');
    }
  }

  @override
  Future<List<NovelEntity>> getNovelsByGenre(String genre) async {
    try {
      return await _dataSource.getNovelsByGenre(genre);
    } catch (e) {
      throw UnknownFailure('Failed to fetch novels for genre $genre: $e');
    }
  }

  @override
  Future<List<NovelEntity>> searchNovels(String query, {String? genre, String? status}) async {
    try {
      return await _dataSource.searchNovels(query, genre: genre, status: status);
    } catch (e) {
      throw UnknownFailure('Search query failed: $e');
    }
  }

  @override
  Future<NovelEntity?> getNovelById(String id) async {
    try {
      return await _dataSource.getNovelById(id);
    } catch (e) {
      throw UnknownFailure('Failed to get novel details: $e');
    }
  }

  @override
  Future<List<NovelEntity>> getNovelsByWriter(String writerId) async {
    try {
      return await _dataSource.getNovelsByWriter(writerId);
    } catch (e) {
      throw UnknownFailure('Failed to fetch author novels: $e');
    }
  }

  @override
  Future<NovelEntity> createNovel(NovelEntity novel) async {
    try {
      final id = novel.id.isEmpty ? const Uuid().v4() : novel.id;
      final model = NovelModel.fromEntity(novel.copyWith(
        id: id,
        titleLowercase: novel.title.toLowerCase(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      return await _dataSource.saveNovel(model);
    } catch (e) {
      throw UnknownFailure('Failed to create novel draft: $e');
    }
  }

  @override
  Future<NovelEntity> updateNovel(NovelEntity novel) async {
    try {
      final model = NovelModel.fromEntity(novel.copyWith(
        titleLowercase: novel.title.toLowerCase(),
        updatedAt: DateTime.now(),
      ));
      return await _dataSource.saveNovel(model);
    } catch (e) {
      throw UnknownFailure('Failed to update novel: $e');
    }
  }

  @override
  Future<void> deleteNovel(String id) async {
    try {
      await _dataSource.deleteNovel(id);
    } catch (e) {
      throw UnknownFailure('Failed to delete novel: $e');
    }
  }

  @override
  Future<bool> isNovelLiked(String novelId, String userId) async {
    return _dataSource.isNovelLiked(novelId, userId);
  }

  @override
  Future<void> toggleLikeNovel(String novelId, String userId) async {
    _dataSource.toggleLikeNovel(novelId, userId);
  }

  @override
  Future<bool> isNovelSaved(String novelId, String userId) async {
    return _dataSource.isNovelSaved(novelId, userId);
  }

  @override
  Future<void> toggleSaveNovel(String novelId, String userId) async {
    _dataSource.toggleSaveNovel(novelId, userId);
  }

  @override
  Future<List<NovelEntity>> getSavedNovels(String userId) async {
    return _dataSource.getSavedNovels(userId);
  }

  @override
  Future<void> saveReadingProgress(String userId, ReadingProgressEntity progress) async {
    _dataSource.saveReadingProgress(userId, ReadingProgressModel.fromEntity(progress));
  }

  @override
  Future<ReadingProgressEntity?> getReadingProgress(String userId, String novelId) async {
    return _dataSource.getReadingProgress(userId, novelId);
  }

  @override
  Future<List<ReadingProgressEntity>> getReadingHistory(String userId) async {
    return _dataSource.getReadingHistory(userId);
  }

  @override
  Future<void> recordDownload(String userId, String novelId) async {
    _dataSource.recordDownload(userId, novelId);
  }

  @override
  Future<List<NovelEntity>> getDownloadedNovels(String userId) async {
    return _dataSource.getDownloadedNovels(userId);
  }
}
