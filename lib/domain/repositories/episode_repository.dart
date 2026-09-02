import '../entities/episode_entity.dart';

abstract class IEpisodeRepository {
  Future<List<EpisodeEntity>> getEpisodesForNovel(String novelId, {bool publishedOnly = true});
  Future<EpisodeEntity?> getEpisodeById(String novelId, String episodeId);
  Future<EpisodeEntity> createEpisode(EpisodeEntity episode);
  Future<EpisodeEntity> updateEpisode(EpisodeEntity episode);
  Future<void> deleteEpisode(String novelId, String episodeId);
  Future<void> incrementEpisodeView(String novelId, String episodeId);
}
