import '../entities/episode_entity.dart';
import '../repositories/episode_repository.dart';

class EpisodeUseCases {
  final IEpisodeRepository _episodeRepository;

  EpisodeUseCases(this._episodeRepository);

  Future<List<EpisodeEntity>> getEpisodesForNovel(String novelId, {bool publishedOnly = true}) =>
      _episodeRepository.getEpisodesForNovel(novelId, publishedOnly: publishedOnly);

  Future<EpisodeEntity?> getEpisodeById(String novelId, String episodeId) =>
      _episodeRepository.getEpisodeById(novelId, episodeId);

  Future<EpisodeEntity> createEpisode(EpisodeEntity episode) =>
      _episodeRepository.createEpisode(episode);

  Future<EpisodeEntity> updateEpisode(EpisodeEntity episode) =>
      _episodeRepository.updateEpisode(episode);

  Future<void> deleteEpisode(String novelId, String episodeId) =>
      _episodeRepository.deleteEpisode(novelId, episodeId);

  Future<void> incrementEpisodeView(String novelId, String episodeId) =>
      _episodeRepository.incrementEpisodeView(novelId, episodeId);
}
