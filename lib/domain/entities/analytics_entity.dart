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
