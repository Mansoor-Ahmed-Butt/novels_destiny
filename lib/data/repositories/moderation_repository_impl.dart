import 'package:uuid/uuid.dart';
import '../../domain/entities/novel_entity.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/moderation_repository.dart';
import '../sources/app_data_source.dart';
import '../sources/firestore_data_source.dart';
import '../models/report_model.dart';
import '../../core/errors/failures.dart';

class ModerationRepositoryImpl implements IModerationRepository {
  final AppDataSource _dataSource;
  final FirestoreDataSource _firestore = FirestoreDataSource();

  ModerationRepositoryImpl(this._dataSource);

  @override
  Future<List<NovelEntity>> getPendingNovels() async {
    try {
      // Fetch pending novels from Firestore (real data)
      final remote = await _firestore.getPendingNovels();
      _dataSource.loadNovels(remote);
      return remote;
    } catch (e) {
      // Fallback to in-memory cache
      return _dataSource.getPendingNovels();
    }
  }

  @override
  Future<void> updateNovelModerationStatus(String novelId, ModerationStatus status) async {
    try {
      // Update Firestore first
      await _firestore.updateNovelModerationStatus(novelId, status.name);
      // Then update local cache
      _dataSource.updateNovelModerationStatus(novelId, status);
    } catch (e) {
      throw UnknownFailure('Failed to update novel moderation status: $e');
    }
  }

  @override
  Future<List<ReportEntity>> getReports({ReportStatus? status}) async {
    try {
      // Fetch from Firestore for real reports
      final remote = await _firestore.getAllReports();
      for (final report in remote) {
        _dataSource.saveReport(report);
      }
      if (status != null) {
        return remote.where((r) => r.status == status).toList();
      }
      return remote;
    } catch (e) {
      // Fallback to in-memory cache
      return _dataSource.getReports(status: status);
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
      // Save to Firestore and local cache
      await _firestore.saveReport(model);
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
      await _firestore.saveReport(updated);
      _dataSource.saveReport(updated);
    } catch (e) {
      throw UnknownFailure('Failed to resolve report: $e');
    }
  }
}
