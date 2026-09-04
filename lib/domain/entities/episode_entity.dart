import 'content_block_entity.dart';

enum EpisodeStatus {
  draft,
  scheduled,
  published,
  archived;

  String get label {
    switch (this) {
      case EpisodeStatus.draft:
        return 'Draft';
      case EpisodeStatus.scheduled:
        return 'Scheduled';
      case EpisodeStatus.published:
        return 'Published';
      case EpisodeStatus.archived:
        return 'Archived';
    }
  }
}

class EpisodeEntity {
  final String id;
  final String novelId;
  final String writerId;
  final int episodeNumber;
  final String title;
  final String titleLowercase;
  final String? summary;
  final String content;
  final List<ContentBlockEntity> blocks;
  final int wordCount;
  final EpisodeStatus status;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalViews;

  const EpisodeEntity({
    required this.id,
    required this.novelId,
    required this.writerId,
    required this.episodeNumber,
    required this.title,
    required this.titleLowercase,
    this.summary,
    required this.content,
    this.blocks = const [],
    required this.wordCount,
    this.status = EpisodeStatus.published,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.totalViews = 0,
  });

  bool get isPublished => status == EpisodeStatus.published;

  List<ContentBlockEntity> get effectiveBlocks {
    if (blocks.isNotEmpty) return blocks;
    if (content.isNotEmpty) {
      return [
        ContentBlockEntity(
          id: '${id}_block_1',
          episodeId: id,
          type: ContentBlockType.text,
          order: 1,
          content: content,
        ),
      ];
    }
    return const [];
  }

  EpisodeEntity copyWith({
    String? id,
    String? novelId,
    String? writerId,
    int? episodeNumber,
    String? title,
    String? titleLowercase,
    String? summary,
    String? content,
    List<ContentBlockEntity>? blocks,
    int? wordCount,
    EpisodeStatus? status,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalViews,
  }) {
    return EpisodeEntity(
      id: id ?? this.id,
      novelId: novelId ?? this.novelId,
      writerId: writerId ?? this.writerId,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      titleLowercase: titleLowercase ?? this.titleLowercase,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      blocks: blocks ?? this.blocks,
      wordCount: wordCount ?? this.wordCount,
      status: status ?? this.status,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalViews: totalViews ?? this.totalViews,
    );
  }
}
