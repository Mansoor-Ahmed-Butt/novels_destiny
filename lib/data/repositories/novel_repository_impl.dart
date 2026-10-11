import 'package:uuid/uuid.dart';
import '../../domain/entities/novel_entity.dart';
import '../../domain/entities/reading_progress_entity.dart';
import '../../domain/repositories/novel_repository.dart';
import '../sources/app_data_source.dart';
import '../sources/firestore_data_source.dart';
import '../models/novel_model.dart';
import '../models/reading_progress_model.dart';
import '../../core/errors/failures.dart';
import '../../core/services/supabase_storage_service.dart';

class NovelRepositoryImpl implements INovelRepository {
  final AppDataSource _dataSource;
  final FirestoreDataSource _firestore = FirestoreDataSource();

  NovelRepositoryImpl(this._dataSource);

  /// Refresh the local cache from Firestore and return published novels.
  Future<List<NovelModel>> _fetchAndCachePublished() async {
    final novels = await _firestore.getPublishedNovels();
    _dataSource.loadNovels(novels);
    return novels;
  }

  @override
  Future<List<NovelEntity>> getFeaturedNovels() async {
    try {
      // Always fetch fresh from Firestore so readers see real uploads
      final novels = await _fetchAndCachePublished();
      return novels.where((n) => n.isPubliclyVisible).toList();
    } catch (e) {
      throw UnknownFailure('Failed to fetch featured novels: $e');
    }
  }

  @override
  Future<List<NovelEntity>> getTrendingNovels() async {
    try {
      final novels = await _fetchAndCachePublished();
      final list = novels.where((n) => n.isPubliclyVisible).toList();
      list.sort((a, b) => b.totalViews.compareTo(a.totalViews));
      return list;
    } catch (e) {
      throw UnknownFailure('Failed to fetch trending novels: $e');
    }
  }

  @override
  Future<List<NovelEntity>> getNovelsByGenre(String genre) async {
    try {
      var novels = await _fetchAndCachePublished();
      if (novels.isEmpty) {
        novels = await _dataSource.getFeaturedNovels();
      }
      final cleanGenre = genre.trim().toLowerCase();
      return novels.where((n) {
        if (!n.isPubliclyVisible) return false;
        final hasGenreId = n.genreIds.any((g) {
          final cleanG = g.trim().toLowerCase();
          return cleanG == cleanGenre || cleanG.contains(cleanGenre) || cleanGenre.contains(cleanG);
        });
        final hasTag = n.tags.any((t) {
          final cleanT = t.trim().toLowerCase();
          return cleanT == cleanGenre || cleanT.contains(cleanGenre) || cleanGenre.contains(cleanT);
        });
        return hasGenreId || hasTag;
      }).toList();
    } catch (e) {
      throw UnknownFailure('Failed to fetch novels for genre $genre: $e');
    }
  }

  @override
  Future<List<NovelEntity>> searchNovels(String query, {String? genre, String? status}) async {
    try {
      // Ensure cache is populated before searching
      await _fetchAndCachePublished();
      return await _dataSource.searchNovels(query, genre: genre, status: status);
    } catch (e) {
      throw UnknownFailure('Search query failed: $e');
    }
  }

  @override
  Future<NovelEntity?> getNovelById(String id) async {
    try {
      // Try local cache first (fast path)
      final local = await _dataSource.getNovelById(id);
      if (local != null) return local;

      // Fallback to Firestore
      final remote = await _firestore.getNovel(id);
      if (remote != null) {
        _dataSource.saveNovel(remote);
        return remote;
      }
      return null;
    } catch (e) {
      throw UnknownFailure('Failed to get novel details: $e');
    }
  }

  @override
  Future<List<NovelEntity>> getNovelsByWriter(String writerId) async {
    try {
      // Always fetch fresh writer novels from Firestore
      final novels = await _firestore.getNovelsByWriter(writerId);
      _dataSource.loadNovels(novels);
      return novels;
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
      // Save to Firestore first (source of truth)
      await _firestore.saveNovel(model);
      // Then cache locally
      await _dataSource.saveNovel(model);
      return model;
    } catch (e) {
      throw UnknownFailure('Failed to create novel: $e');
    }
  }

  @override
  Future<NovelEntity> updateNovel(NovelEntity novel) async {
    try {
      final model = NovelModel.fromEntity(novel.copyWith(
        titleLowercase: novel.title.toLowerCase(),
        updatedAt: DateTime.now(),
      ));
      // Save to Firestore first (source of truth)
      await _firestore.saveNovel(model);
      // Then update local cache
      final saved = await _dataSource.saveNovel(model);
      return saved;
    } catch (e) {
      throw UnknownFailure('Failed to update novel: $e');
    }
  }

  @override
  Future<void> deleteNovel(String id) async {
    try {
      // 1. Fetch novel and episodes to identify Supabase files
      var novel = await _dataSource.getNovelById(id);
      novel ??= await _firestore.getNovel(id);

      var episodes = await _dataSource.getEpisodesForNovel(id, publishedOnly: false);
      if (episodes.isEmpty) {
        episodes = await _firestore.getEpisodesForNovel(id);
      }
      final storageService = SupabaseStorageService();

      // 2. Delete all episode PDF and attachment files from Supabase
      for (final ep in episodes) {
        var blocks = ep.blocks;
        if (blocks.isEmpty) {
          blocks = await _firestore.getEpisodeBlocks(ep.id);
        }
        for (final block in blocks) {
          if (block.storagePath != null && block.storagePath!.isNotEmpty) {
            await storageService.deleteFile(block.storagePath!);
          } else if (block.url != null && block.url!.isNotEmpty && block.url!.contains('novel-files')) {
            await storageService.deleteFile(block.url!);
          }
        }
      }

      // 3. Delete novel PDF and cover from Supabase if present
      if (novel?.pdfStoragePath != null && novel!.pdfStoragePath!.isNotEmpty) {
        await storageService.deleteFile(novel.pdfStoragePath!);
      }
      if (novel?.coverStoragePath != null && novel!.coverStoragePath!.isNotEmpty) {
        await storageService.deleteFile(novel.coverStoragePath!);
      }

      // 4. Clean up any remaining novel folder files in Supabase
      await storageService.deleteNovelFolder(id);

      // 5. Delete from Firestore and local cache
      await _firestore.deleteNovel(id);
      await _dataSource.deleteNovel(id);
    } catch (e) {
      throw UnknownFailure('Failed to delete novel: $e');
    }
  }

  @override
  Future<NovelEntity> rateNovel(String novelId, String userId, double rating) async {
    try {
      final updated = _dataSource.rateNovel(novelId, userId, rating);
      await _firestore.saveUserRating(
        novelId: novelId,
        userId: userId,
        rating: rating,
        newAverageRating: updated.rating,
        newRatingCount: updated.ratingCount,
      );
      return updated;
    } catch (e) {
      throw UnknownFailure('Failed to submit rating: $e');
    }
  }

  @override
  Future<double?> getUserRating(String novelId, String userId) async {
    try {
      final cached = _dataSource.getUserRating(novelId, userId);
      if (cached != null) return cached;
      return await _firestore.getUserRating(novelId, userId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> isNovelLiked(String novelId, String userId) async {
    return _dataSource.isNovelLiked(novelId, userId);
  }

  @override
  Future<void> toggleLikeNovel(String novelId, String userId) async {
    _dataSource.toggleLikeNovel(novelId, userId);
    _firestore.incrementNovelLikes(novelId);
  }

  @override
  Future<bool> isNovelSaved(String novelId, String userId) async {
    return _dataSource.isNovelSaved(novelId, userId);
  }

  @override
  Future<void> toggleSaveNovel(String novelId, String userId) async {
    final wasSaved = await isNovelSaved(novelId, userId);
    _dataSource.toggleSaveNovel(novelId, userId);
    _firestore.toggleBookmark(
      userId: userId,
      novelId: novelId,
      isBookmarked: !wasSaved,
    );
  }

  @override
  Future<List<NovelEntity>> getSavedNovels(String userId) async {
    try {
      // Get bookmarked IDs from Firestore
      final bookmarkedIds = await _firestore.getBookmarkedNovelIds(userId);
      if (bookmarkedIds.isEmpty) return [];

      // Mark them saved in local cache
      for (final id in bookmarkedIds) {
        if (!_dataSource.isNovelSaved(id, userId)) {
          _dataSource.toggleSaveNovel(id, userId);
        }
      }

      // Fetch each novel (from cache or Firestore)
      final novels = <NovelEntity>[];
      for (final id in bookmarkedIds) {
        final novel = await getNovelById(id);
        if (novel != null) novels.add(novel);
      }
      return novels;
    } catch (e) {
      // Fallback to in-memory
      return _dataSource.getSavedNovels(userId);
    }
  }

  @override
  Future<void> saveReadingProgress(String userId, ReadingProgressEntity progress) async {
    final model = ReadingProgressModel.fromEntity(progress);
    _dataSource.saveReadingProgress(userId, model);
    _firestore.saveReadingProgress(userId: userId, progress: model);
  }

  @override
  Future<ReadingProgressEntity?> getReadingProgress(String userId, String novelId) async {
    final local = _dataSource.getReadingProgress(userId, novelId);
    if (local != null) return local;
    return _firestore.getReadingProgress(userId: userId, novelId: novelId);
  }

  @override
  Future<List<ReadingProgressEntity>> getReadingHistory(String userId) async {
    try {
      // Fetch from Firestore for persistence across sessions
      final remote = await _firestore.getReadingHistory(userId);
      if (remote.isNotEmpty) {
        for (final p in remote) {
          _dataSource.saveReadingProgress(userId, p);
        }
        return remote;
      }
      return _dataSource.getReadingHistory(userId);
    } catch (e) {
      return _dataSource.getReadingHistory(userId);
    }
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
