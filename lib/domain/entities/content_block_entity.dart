enum ContentBlockType {
  text,
  image,
  pdf,
  ad;

  String get label {
    switch (this) {
      case ContentBlockType.text:
        return 'Text';
      case ContentBlockType.image:
        return 'Image';
      case ContentBlockType.pdf:
        return 'PDF';
      case ContentBlockType.ad:
        return 'Advertisement';
    }
  }
}

class ContentBlockEntity {
  final String id;
  final String episodeId;
  final ContentBlockType type;
  final int order;
  final String content;
  final String? storagePath;
  final String? url;
  final String? caption;
  final String? fileName;
  final String? placement;

  const ContentBlockEntity({
    required this.id,
    required this.episodeId,
    required this.type,
    required this.order,
    this.content = '',
    this.storagePath,
    this.url,
    this.caption,
    this.fileName,
    this.placement,
  });

  ContentBlockEntity copyWith({
    String? id,
    String? episodeId,
    ContentBlockType? type,
    int? order,
    String? content,
    String? storagePath,
    String? url,
    String? caption,
    String? fileName,
    String? placement,
  }) {
    return ContentBlockEntity(
      id: id ?? this.id,
      episodeId: episodeId ?? this.episodeId,
      type: type ?? this.type,
      order: order ?? this.order,
      content: content ?? this.content,
      storagePath: storagePath ?? this.storagePath,
      url: url ?? this.url,
      caption: caption ?? this.caption,
      fileName: fileName ?? this.fileName,
      placement: placement ?? this.placement,
    );
  }
}
