import '../../domain/entities/report_entity.dart';

class ReportModel extends ReportEntity {
  const ReportModel({
    required super.id,
    required super.reporterId,
    required super.reporterName,
    required super.targetType,
    required super.targetId,
    required super.targetTitle,
    required super.reason,
    super.status = ReportStatus.pending,
    required super.createdAt,
    super.resolutionNote,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String? ?? '',
      reporterId: json['reporterId'] as String? ?? '',
      reporterName: json['reporterName'] as String? ?? '',
      targetType: json['targetType'] as String? ?? 'novel',
      targetId: json['targetId'] as String? ?? '',
      targetTitle: json['targetTitle'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      status: ReportStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String?),
        orElse: () => ReportStatus.pending,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      resolutionNote: json['resolutionNote'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'targetType': targetType,
      'targetId': targetId,
      'targetTitle': targetTitle,
      'reason': reason,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'resolutionNote': resolutionNote,
    };
  }

  factory ReportModel.fromEntity(ReportEntity entity) {
    return ReportModel(
      id: entity.id,
      reporterId: entity.reporterId,
      reporterName: entity.reporterName,
      targetType: entity.targetType,
      targetId: entity.targetId,
      targetTitle: entity.targetTitle,
      reason: entity.reason,
      status: entity.status,
      createdAt: entity.createdAt,
      resolutionNote: entity.resolutionNote,
    );
  }
}
