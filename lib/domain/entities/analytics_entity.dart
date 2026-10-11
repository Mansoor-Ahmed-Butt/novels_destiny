class PlatformAnalyticsEntity {
  final int totalUsers;
  final int totalReaders;
  final int totalWriters;
  final int totalNovels;
  final int totalPublishedEpisodes;
  final int totalReads;
  final int totalLikes;
  final int totalDownloads;
  final int pendingModerations;
  final int openReports;
  final List<DailyMetricPoint> dailyReadsTrend;
  final List<DailyMetricPoint> dailyUsersTrend;
  final List<NovelRatingMetric> novelRatings;
  final List<EpisodeRatingMetric> episodeMetrics;
  final Map<int, int> ratingDistribution; // 1 to 5 star counts

  const PlatformAnalyticsEntity({
    required this.totalUsers,
    required this.totalReaders,
    required this.totalWriters,
    required this.totalNovels,
    required this.totalPublishedEpisodes,
    required this.totalReads,
    required this.totalLikes,
    required this.totalDownloads,
    required this.pendingModerations,
    required this.openReports,
    required this.dailyReadsTrend,
    required this.dailyUsersTrend,
    this.novelRatings = const [],
    this.episodeMetrics = const [],
    this.ratingDistribution = const {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
  });
}

class NovelRatingMetric {
  final String novelId;
  final String title;
  final double rating;
  final int ratingCount;
  final int totalViews;

  const NovelRatingMetric({
    required this.novelId,
    required this.title,
    required this.rating,
    required this.ratingCount,
    required this.totalViews,
  });
}

class EpisodeRatingMetric {
  final String episodeId;
  final String episodeTitle;
  final String novelTitle;
  final int episodeNumber;
  final int views;
  final double rating;

  const EpisodeRatingMetric({
    required this.episodeId,
    required this.episodeTitle,
    required this.novelTitle,
    required this.episodeNumber,
    required this.views,
    this.rating = 0.0,
  });
}

class WriterAnalyticsEntity {
  final String writerId;
  final int totalNovels;
  final int publishedEpisodes;
  final int totalReads;
  final int totalLikes;
  final int totalDownloads;
  final List<DailyMetricPoint> dailyReadsTrend;

  const WriterAnalyticsEntity({
    required this.writerId,
    required this.totalNovels,
    required this.publishedEpisodes,
    required this.totalReads,
    required this.totalLikes,
    required this.totalDownloads,
    required this.dailyReadsTrend,
  });
}

class DailyMetricPoint {
  final String dateLabel; // 'Mon', 'Tue' or '09/01'
  final double value;

  const DailyMetricPoint({
    required this.dateLabel,
    required this.value,
  });
}
