import 'package:uuid/uuid.dart';
import '../../domain/entities/episode_entity.dart';
import '../../domain/repositories/episode_repository.dart';
import '../sources/app_data_source.dart';
import '../models/episode_model.dart';
import '../../core/errors/failures.dart';

class EpisodeRepositoryImpl implements IEpisodeRepository {
  final AppDataSource _dataSource;

  EpisodeRepositoryImpl(this._dataSource);

  @override
  Future<List<EpisodeEntity>> getEpisodesForNovel(String novelId, {bool publishedOnly = true}) async {
    try {
      return await _dataSource.getEpisodesForNovel(novelId, publishedOnly: publishedOnly);
    } catch (e) {
      throw UnknownFailure('Failed to fetch chapters: $e');
    }
  }

  @override
  Future<EpisodeEntity?> getEpisodeById(String novelId, String episodeId) async {
    try {
      return await _dataSource.getEpisodeById(novelId, episodeId);
    } catch (e) {
      throw UnknownFailure('Failed to fetch chapter: $e');
    }
  }

  @override
  Future<EpisodeEntity> createEpisode(EpisodeEntity episode) async {
    try {
      final id = episode.id.isEmpty ? const Uuid().v4() : episode.id;
      final model = EpisodeModel.fromEntity(episode.copyWith(
        id: id,
        titleLowercase: episode.title.toLowerCase(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        publishedAt: episode.status == EpisodeStatus.published ? DateTime.now() : null,
      ));
      return await _dataSource.saveEpisode(model);
    } catch (e) {
      throw UnknownFailure('Failed to save episode: $e');
    }
  }

  @override
  Future<EpisodeEntity> updateEpisode(EpisodeEntity episode) async {
    try {
      final model = EpisodeModel.fromEntity(episode.copyWith(
        titleLowercase: episode.title.toLowerCase(),
        updatedAt: DateTime.now(),
        publishedAt: episode.status == EpisodeStatus.published && episode.publishedAt == null
            ? DateTime.now()
            : episode.publishedAt,
      ));
      return await _dataSource.saveEpisode(model);
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
  }
}
