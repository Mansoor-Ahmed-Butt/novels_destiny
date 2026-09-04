import '../../domain/entities/content_block_entity.dart';

class ContentBlockModel extends ContentBlockEntity {
  const ContentBlockModel({
    required super.id,
    required super.episodeId,
    required super.type,
    required super.order,
    super.content = '',
    super.storagePath,
    super.url,
    super.caption,
    super.fileName,
    super.placement,
  });

  factory ContentBlockModel.fromJson(Map<String, dynamic> json) {
    return ContentBlockModel(
      id: json['id'] as String? ?? '',
      episodeId: json['episodeId'] as String? ?? '',
      type: ContentBlockType.values.firstWhere(
        (t) => t.name == (json['type'] as String?),
        orElse: () => ContentBlockType.text,
      ),
      order: json['order'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      storagePath: json['storagePath'] as String?,
      url: json['url'] as String?,
      caption: json['caption'] as String?,
      fileName: json['fileName'] as String?,
      placement: json['placement'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'episodeId': episodeId,
      'type': type.name,
      'order': order,
      'content': content,
      'storagePath': storagePath,
      'url': url,
      'caption': caption,
      'fileName': fileName,
      'placement': placement,
    };
  }

  factory ContentBlockModel.fromEntity(ContentBlockEntity entity) {
    return ContentBlockModel(
      id: entity.id,
      episodeId: entity.episodeId,
      type: entity.type,
      order: entity.order,
      content: entity.content,
      storagePath: entity.storagePath,
      url: entity.url,
      caption: entity.caption,
      fileName: entity.fileName,
      placement: entity.placement,
    );
  }
}
