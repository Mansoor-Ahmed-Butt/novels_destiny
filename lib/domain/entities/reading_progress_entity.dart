class ReadingProgressEntity {
  final String novelId;
  final String episodeId;
  final int episodeNumber;
  final double scrollOffset;
  final double progressPercent; // 0.0 to 1.0
  final DateTime updatedAt;

  const ReadingProgressEntity({
    required this.novelId,
    required this.episodeId,
    required this.episodeNumber,
    this.scrollOffset = 0.0,
    this.progressPercent = 0.0,
    required this.updatedAt,
  });

  ReadingProgressEntity copyWith({
    String? novelId,
    String? episodeId,
    int? episodeNumber,
    double? scrollOffset,
    double? progressPercent,
    DateTime? updatedAt,
  }) {
    return ReadingProgressEntity(
      novelId: novelId ?? this.novelId,
      episodeId: episodeId ?? this.episodeId,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      progressPercent: progressPercent ?? this.progressPercent,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
