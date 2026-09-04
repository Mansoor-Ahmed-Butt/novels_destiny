import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/episode_entity.dart';
import '../../domain/repositories/episode_repository.dart';
import '../sources/app_data_source.dart';
import '../sources/firestore_data_source.dart';
import '../models/episode_model.dart';
import '../../core/errors/failures.dart';

class EpisodeRepositoryImpl implements IEpisodeRepository {
  final AppDataSource _dataSource;
  final FirestoreDataSource _firestore = FirestoreDataSource();

  EpisodeRepositoryImpl(this._dataSource);

  @override
  Future<List<EpisodeEntity>> getEpisodesForNovel(String novelId, {bool publishedOnly = true}) async {
    try {
      final local = await _dataSource.getEpisodesForNovel(novelId, publishedOnly: publishedOnly);
      if (local.isNotEmpty) return local;

      // Try Firestore
      final remote = await _firestore.getEpisodesForNovel(novelId);
      if (remote.isNotEmpty) {
        for (final ep in remote) {
          _dataSource.saveEpisode(ep);
        }
        return publishedOnly ? remote.where((e) => e.isPublished).toList() : remote;
      }
      return local;
    } catch (e) {
      throw UnknownFailure('Failed to fetch chapters: $e');
    }
  }

  @override
  Future<EpisodeEntity?> getEpisodeById(String novelId, String episodeId) async {
    try {
      final local = await _dataSource.getEpisodeById(novelId, episodeId);
      if (local != null) return local;

      final remote = await _firestore.getEpisode(episodeId);
      if (remote != null) {
        _dataSource.saveEpisode(remote);
        return remote;
      }
      return null;
    } catch (e) {
      throw UnknownFailure('Failed to fetch chapter: $e');
    }
  }

  @override
  Future<EpisodeEntity> createEpisode(EpisodeEntity episode) async {
    try {
      final id = episode.id.isEmpty ? const Uuid().v4() : episode.id;
      final isPublished = episode.status == EpisodeStatus.published;
      final model = EpisodeModel.fromEntity(episode.copyWith(
        id: id,
        titleLowercase: episode.title.toLowerCase(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        publishedAt: isPublished ? DateTime.now() : null,
      ));

      final saved = await _dataSource.saveEpisode(model);
      await _firestore.saveEpisode(model);

      if (isPublished) {
        _notifyFollowers(model);
      }

      return saved;
    } catch (e) {
      throw UnknownFailure('Failed to save episode: $e');
    }
  }

  @override
  Future<EpisodeEntity> updateEpisode(EpisodeEntity episode) async {
    try {
      final isPublished = episode.status == EpisodeStatus.published;
      final model = EpisodeModel.fromEntity(episode.copyWith(
        titleLowercase: episode.title.toLowerCase(),
        updatedAt: DateTime.now(),
        publishedAt: isPublished && episode.publishedAt == null
            ? DateTime.now()
            : episode.publishedAt,
      ));

      final saved = await _dataSource.saveEpisode(model);
      await _firestore.saveEpisode(model);

      if (isPublished && episode.publishedAt == null) {
        _notifyFollowers(model);
      }

      return saved;
    } catch (e) {
      throw UnknownFailure('Failed to update episode: $e');
    }
  }

  @override
  Future<void> deleteEpisode(String novelId, String episodeId) async {
    try {
      await _dataSource.deleteEpisode(novelId, episodeId);
    } catch (e) {
      throw UnknownFailure('Failed to delete episode: $e');
    }
  }

  @override
  Future<void> incrementEpisodeView(String novelId, String episodeId) async {
    final ep = await _dataSource.getEpisodeById(novelId, episodeId);
    if (ep != null) {
      await _dataSource.saveEpisode(EpisodeModel.fromEntity(ep.copyWith(totalViews: ep.totalViews + 1)));
    }
    _firestore.incrementEpisodeViews(episodeId);
  }

  void _notifyFollowers(EpisodeModel episode) async {
    try {
      final followers = await _firestore.getNovelFollowerUserIds(episode.novelId);
      for (final uid in followers) {
        await _firestore.createNotification(
          userId: uid,
          type: 'new_episode',
          title: 'New Chapter Available!',
          body: 'Chapter ${episode.episodeNumber}: ${episode.title} has just been released.',
          novelId: episode.novelId,
          episodeId: episode.id,
        );
      }
    } catch (e) {
      debugPrint('Error creating follower notifications: $e');
    }
  }
}
