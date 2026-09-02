import '../../../domain/entities/novel_entity.dart';
import '../../../domain/entities/episode_entity.dart';
import '../../../domain/entities/reading_progress_entity.dart';

sealed class NovelDetailsState {
  const NovelDetailsState();
}

class NovelDetailsLoading extends NovelDetailsState {
  const NovelDetailsLoading();
}

class NovelDetailsFailure extends NovelDetailsState {
  final String message;
  const NovelDetailsFailure(this.message);
}

class NovelDetailsReady extends NovelDetailsState {
  final NovelEntity novel;
  final List<EpisodeEntity> episodes;
  final bool isLiked;
  final bool isSaved;
  final ReadingProgressEntity? readingProgress;

  const NovelDetailsReady({
    required this.novel,
    required this.episodes,
    required this.isLiked,
    required this.isSaved,
    this.readingProgress,
  });

  NovelDetailsReady copyWith({
    NovelEntity? novel,
    List<EpisodeEntity>? episodes,
    bool? isLiked,
    bool? isSaved,
    ReadingProgressEntity? readingProgress,
  }) {
    return NovelDetailsReady(
      novel: novel ?? this.novel,
      episodes: episodes ?? this.episodes,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      readingProgress: readingProgress ?? this.readingProgress,
    );
  }
}
