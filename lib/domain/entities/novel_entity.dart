enum NovelStatus {
  draft,
  ongoing,
  completed,
  paused,
  archived;

  String get label {
    switch (this) {
      case NovelStatus.draft:
        return 'Draft';
      case NovelStatus.ongoing:
        return 'Ongoing';
      case NovelStatus.completed:
        return 'Completed';
      case NovelStatus.paused:
        return 'Paused';
      case NovelStatus.archived:
        return 'Archived';
    }
  }
}

enum ModerationStatus {
  pending,
  approved,
  rejected,
  hidden;

  String get label {
    switch (this) {
      case ModerationStatus.pending:
        return 'Pending Review';
      case ModerationStatus.approved:
        return 'Approved';
      case ModerationStatus.rejected:
        return 'Rejected';
      case ModerationStatus.hidden:
        return 'Hidden';
    }
  }
}

class NovelEntity {
  final String id;
  final String writerId;
  final String writerName;
  final String? writerAvatarUrl;
  final String title;
  final String titleLowercase;
  final String description;
  final String coverUrl;
  final String? coverStoragePath;
  final List<String> genreIds;
  final List<String> tags;
  final String language;
  final NovelStatus status;
  final ModerationStatus moderationStatus;
  final bool isDownloadEnabled;
  final String? fullNovelStoragePath;
  final int publishedEpisodeCount;
  final int totalViews;
  final int totalLikes;
  final int totalDownloads;
  final double rating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final DateTime? completedAt;

  const NovelEntity({
    required this.id,
    required this.writerId,
    required this.writerName,
    this.writerAvatarUrl,
    required this.title,
    required this.titleLowercase,
    required this.description,
    required this.coverUrl,
    this.coverStoragePath,
    required this.genreIds,
    required this.tags,
    this.language = 'en',
    this.status = NovelStatus.ongoing,
    this.moderationStatus = ModerationStatus.approved,
    this.isDownloadEnabled = false,
    this.fullNovelStoragePath,
    this.publishedEpisodeCount = 0,
    this.totalViews = 0,
    this.totalLikes = 0,
    this.totalDownloads = 0,
    this.rating = 4.8,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.completedAt,
  });

  bool get isCompleted => status == NovelStatus.completed;
  bool get isApproved => moderationStatus == ModerationStatus.approved;
  bool get isPubliclyVisible => isApproved && status != NovelStatus.draft && status != NovelStatus.archived;

  NovelEntity copyWith({
    String? id,
    String? writerId,
    String? writerName,
    String? writerAvatarUrl,
    String? title,
    String? titleLowercase,
    String? description,
    String? coverUrl,
    String? coverStoragePath,
    List<String>? genreIds,
    List<String>? tags,
    String? language,
    NovelStatus? status,
    ModerationStatus? moderationStatus,
    bool? isDownloadEnabled,
    String? fullNovelStoragePath,
    int? publishedEpisodeCount,
    int? totalViews,
    int? totalLikes,
    int? totalDownloads,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    DateTime? completedAt,
  }) {
    return NovelEntity(
      id: id ?? this.id,
      writerId: writerId ?? this.writerId,
      writerName: writerName ?? this.writerName,
      writerAvatarUrl: writerAvatarUrl ?? this.writerAvatarUrl,
      title: title ?? this.title,
      titleLowercase: titleLowercase ?? this.titleLowercase,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      coverStoragePath: coverStoragePath ?? this.coverStoragePath,
      genreIds: genreIds ?? this.genreIds,
      tags: tags ?? this.tags,
      language: language ?? this.language,
      status: status ?? this.status,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      isDownloadEnabled: isDownloadEnabled ?? this.isDownloadEnabled,
      fullNovelStoragePath: fullNovelStoragePath ?? this.fullNovelStoragePath,
      publishedEpisodeCount: publishedEpisodeCount ?? this.publishedEpisodeCount,
      totalViews: totalViews ?? this.totalViews,
      totalLikes: totalLikes ?? this.totalLikes,
      totalDownloads: totalDownloads ?? this.totalDownloads,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
