import '../../domain/entities/novel_entity.dart';

class NovelModel extends NovelEntity {
  const NovelModel({
    required super.id,
    required super.writerId,
    required super.writerName,
    super.writerAvatarUrl,
    required super.title,
    required super.titleLowercase,
    required super.description,
    required super.coverUrl,
    super.coverStoragePath,
    required super.genreIds,
    required super.tags,
    super.language = 'en',
    super.status = NovelStatus.ongoing,
    super.moderationStatus = ModerationStatus.approved,
    super.isDownloadEnabled = false,
    super.fullNovelStoragePath,
    super.publishedEpisodeCount = 0,
    super.totalViews = 0,
    super.totalLikes = 0,
    super.totalDownloads = 0,
    super.rating = 4.8,
    required super.createdAt,
    required super.updatedAt,
    super.publishedAt,
    super.completedAt,
  });

  factory NovelModel.fromJson(Map<String, dynamic> json) {
    return NovelModel(
      id: json['id'] as String? ?? '',
      writerId: json['writerId'] as String? ?? '',
      writerName: json['writerName'] as String? ?? 'Author',
      writerAvatarUrl: json['writerAvatarUrl'] as String?,
      title: json['title'] as String? ?? '',
      titleLowercase: json['titleLowercase'] as String? ?? '',
      description: json['description'] as String? ?? '',
      coverUrl: json['coverUrl'] as String? ?? '',
      coverStoragePath: json['coverStoragePath'] as String?,
      genreIds: (json['genreIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      language: json['language'] as String? ?? 'en',
      status: NovelStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String?),
        orElse: () => NovelStatus.ongoing,
      ),
      moderationStatus: ModerationStatus.values.firstWhere(
        (m) => m.name == (json['moderationStatus'] as String?),
        orElse: () => ModerationStatus.approved,
      ),
      isDownloadEnabled: json['isDownloadEnabled'] as bool? ?? false,
      fullNovelStoragePath: json['fullNovelStoragePath'] as String?,
      publishedEpisodeCount: json['publishedEpisodeCount'] as int? ?? 0,
      totalViews: json['totalViews'] as int? ?? 0,
      totalLikes: json['totalLikes'] as int? ?? 0,
      totalDownloads: json['totalDownloads'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'writerId': writerId,
      'writerName': writerName,
      'writerAvatarUrl': writerAvatarUrl,
      'title': title,
      'titleLowercase': titleLowercase,
      'description': description,
      'coverUrl': coverUrl,
      'coverStoragePath': coverStoragePath,
      'genreIds': genreIds,
      'tags': tags,
      'language': language,
      'status': status.name,
      'moderationStatus': moderationStatus.name,
      'isDownloadEnabled': isDownloadEnabled,
      'fullNovelStoragePath': fullNovelStoragePath,
      'publishedEpisodeCount': publishedEpisodeCount,
      'totalViews': totalViews,
      'totalLikes': totalLikes,
      'totalDownloads': totalDownloads,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'publishedAt': publishedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory NovelModel.fromEntity(NovelEntity entity) {
    return NovelModel(
      id: entity.id,
      writerId: entity.writerId,
      writerName: entity.writerName,
      writerAvatarUrl: entity.writerAvatarUrl,
      title: entity.title,
      titleLowercase: entity.titleLowercase,
      description: entity.description,
      coverUrl: entity.coverUrl,
      coverStoragePath: entity.coverStoragePath,
      genreIds: entity.genreIds,
      tags: entity.tags,
      language: entity.language,
      status: entity.status,
      moderationStatus: entity.moderationStatus,
      isDownloadEnabled: entity.isDownloadEnabled,
      fullNovelStoragePath: entity.fullNovelStoragePath,
      publishedEpisodeCount: entity.publishedEpisodeCount,
      totalViews: entity.totalViews,
      totalLikes: entity.totalLikes,
      totalDownloads: entity.totalDownloads,
      rating: entity.rating,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      publishedAt: entity.publishedAt,
      completedAt: entity.completedAt,
    );
  }
}
