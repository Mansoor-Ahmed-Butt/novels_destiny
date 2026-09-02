import '../entities/novel_entity.dart';
import '../entities/report_entity.dart';

abstract class IModerationRepository {
  Future<List<NovelEntity>> getPendingNovels();
  Future<void> updateNovelModerationStatus(String novelId, ModerationStatus status);
  Future<List<ReportEntity>> getReports({ReportStatus? status});
  Future<ReportEntity> submitReport(ReportEntity report);
  Future<void> resolveReport(String reportId, String note, ReportStatus resolution);
}
