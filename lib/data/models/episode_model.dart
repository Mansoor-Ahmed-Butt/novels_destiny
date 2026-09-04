import '../../domain/entities/episode_entity.dart';
import '../../domain/entities/content_block_entity.dart';
import 'content_block_model.dart';

class EpisodeModel extends EpisodeEntity {
  const EpisodeModel({
    required super.id,
    required super.novelId,
    required super.writerId,
    required super.episodeNumber,
    required super.title,
    required super.titleLowercase,
    super.summary,
    required super.content,
    super.blocks = const [],
    required super.wordCount,
    super.status = EpisodeStatus.published,
    super.publishedAt,
    required super.createdAt,
    required super.updatedAt,
    super.totalViews = 0,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json, {List<ContentBlockEntity>? blocks}) {
    final parsedBlocks = blocks ??
        (json['blocks'] as List<dynamic>?)
            ?.map((b) => ContentBlockModel.fromJson(Map<String, dynamic>.from(b as Map)))
            .toList() ??
        [];

    return EpisodeModel(
      id: json['id'] as String? ?? '',
      novelId: json['novelId'] as String? ?? '',
      writerId: json['writerId'] as String? ?? '',
      episodeNumber: json['episodeNumber'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      titleLowercase: json['titleLowercase'] as String? ?? '',
      summary: json['summary'] as String?,
      content: json['content'] as String? ?? '',
      blocks: parsedBlocks,
      wordCount: json['wordCount'] as int? ?? 0,
      status: EpisodeStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String?),
        orElse: () => EpisodeStatus.published,
      ),
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      totalViews: json['totalViews'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'novelId': novelId,
      'writerId': writerId,
      'episodeNumber': episodeNumber,
      'title': title,
      'titleLowercase': titleLowercase,
      'summary': summary,
      'content': content,
      'blocks': blocks.map((b) => ContentBlockModel.fromEntity(b).toJson()).toList(),
      'wordCount': wordCount,
      'status': status.name,
      'publishedAt': publishedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'totalViews': totalViews,
    };
  }

  factory EpisodeModel.fromEntity(EpisodeEntity entity) {
    return EpisodeModel(
      id: entity.id,
      novelId: entity.novelId,
      writerId: entity.writerId,
      episodeNumber: entity.episodeNumber,
      title: entity.title,
      titleLowercase: entity.titleLowercase,
      summary: entity.summary,
      content: entity.content,
      blocks: entity.blocks,
      wordCount: entity.wordCount,
      status: entity.status,
      publishedAt: entity.publishedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      totalViews: entity.totalViews,
    );
  }
}
