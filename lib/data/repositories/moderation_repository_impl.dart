import 'package:uuid/uuid.dart';
import '../../domain/entities/novel_entity.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/moderation_repository.dart';
import '../sources/app_data_source.dart';
import '../models/report_model.dart';
import '../../core/errors/failures.dart';

class ModerationRepositoryImpl implements IModerationRepository {
  final AppDataSource _dataSource;

  ModerationRepositoryImpl(this._dataSource);

  @override
  Future<List<NovelEntity>> getPendingNovels() async {
    try {
      return _dataSource.getPendingNovels();
    } catch (e) {
      throw UnknownFailure('Failed to list pending novels: $e');
    }
  }

  @override
  Future<void> updateNovelModerationStatus(String novelId, ModerationStatus status) async {
    try {
      _dataSource.updateNovelModerationStatus(novelId, status);
    } catch (e) {
      throw UnknownFailure('Failed to update novel moderation status: $e');
    }
  }

  @override
  Future<List<ReportEntity>> getReports({ReportStatus? status}) async {
    try {
      return _dataSource.getReports(status: status);
    } catch (e) {
      throw UnknownFailure('Failed to fetch reports: $e');
    }
  }

  @override
  Future<ReportEntity> submitReport(ReportEntity report) async {
    try {
      final id = report.id.isEmpty ? const Uuid().v4() : report.id;
      final model = ReportModel.fromEntity(report.copyWith(
        id: id,
        createdAt: DateTime.now(),
      ));
      _dataSource.saveReport(model);
      return model;
    } catch (e) {
      throw UnknownFailure('Failed to submit report: $e');
    }
  }

  @override
  Future<void> resolveReport(String reportId, String note, ReportStatus resolution) async {
    try {
      final reports = _dataSource.getReports();
      final target = reports.firstWhere((r) => r.id == reportId);
      final updated = target.copyWith(
        status: resolution,
        resolutionNote: note,
      ) as ReportModel;
      _dataSource.saveReport(updated);
    } catch (e) {
      throw UnknownFailure('Failed to resolve report: $e');
    }
  }
}
