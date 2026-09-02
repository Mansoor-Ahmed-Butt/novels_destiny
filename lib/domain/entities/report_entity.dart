enum ReportStatus { pending, resolved, dismissed }

class ReportEntity {
  final String id;
  final String reporterId;
  final String reporterName;
  final String targetType; // 'novel' or 'episode' or 'user'
  final String targetId;
  final String targetTitle;
  final String reason;
  final ReportStatus status;
  final DateTime createdAt;
  final String? resolutionNote;

  const ReportEntity({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.targetType,
    required this.targetId,
    required this.targetTitle,
    required this.reason,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.resolutionNote,
  });

  ReportEntity copyWith({
    String? id,
    String? reporterId,
    String? reporterName,
    String? targetType,
    String? targetId,
    String? targetTitle,
    String? reason,
    ReportStatus? status,
    DateTime? createdAt,
    String? resolutionNote,
  }) {
    return ReportEntity(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      targetTitle: targetTitle ?? this.targetTitle,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolutionNote: resolutionNote ?? this.resolutionNote,
    );
  }
}
