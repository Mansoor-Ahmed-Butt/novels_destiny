import '../../domain/entities/reading_progress_entity.dart';

class ReadingProgressModel extends ReadingProgressEntity {
  const ReadingProgressModel({
    required super.novelId,
    required super.episodeId,
    required super.episodeNumber,
    super.scrollOffset = 0.0,
    super.progressPercent = 0.0,
    required super.updatedAt,
  });

  factory ReadingProgressModel.fromJson(Map<String, dynamic> json) {
    return ReadingProgressModel(
      novelId: json['novelId'] as String? ?? '',
      episodeId: json['episodeId'] as String? ?? '',
      episodeNumber: json['episodeNumber'] as int? ?? 1,
      scrollOffset: (json['scrollOffset'] as num?)?.toDouble() ?? 0.0,
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'novelId': novelId,
      'episodeId': episodeId,
      'episodeNumber': episodeNumber,
      'scrollOffset': scrollOffset,
      'progressPercent': progressPercent,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ReadingProgressModel.fromEntity(ReadingProgressEntity entity) {
    return ReadingProgressModel(
      novelId: entity.novelId,
      episodeId: entity.episodeId,
      episodeNumber: entity.episodeNumber,
      scrollOffset: entity.scrollOffset,
      progressPercent: entity.progressPercent,
      updatedAt: entity.updatedAt,
    );
  }
}
