import '../entities/user_entity.dart';
import '../entities/novel_entity.dart';
import '../entities/report_entity.dart';
import '../entities/analytics_entity.dart';
import '../repositories/user_repository.dart';
import '../repositories/moderation_repository.dart';
import '../repositories/analytics_repository.dart';

class AdminUseCases {
  final IUserRepository _userRepository;
  final IModerationRepository _moderationRepository;
  final IAnalyticsRepository _analyticsRepository;

  AdminUseCases(
    this._userRepository,
    this._moderationRepository,
    this._analyticsRepository,
  );

  Future<List<UserEntity>> getAllUsers() => _userRepository.getAllUsers();
  Future<List<UserEntity>> getPendingWriters() => _userRepository.getPendingWriters();
  Future<void> approveWriter(String id) => _userRepository.approveWriter(id);
  Future<void> rejectWriter(String id) => _userRepository.rejectWriter(id);
  Future<void> updateUserStatus(String id, bool isActive) => _userRepository.updateUserStatus(id, isActive);

  Future<List<NovelEntity>> getPendingNovels() => _moderationRepository.getPendingNovels();
  Future<void> updateNovelModerationStatus(String novelId, ModerationStatus status) =>
      _moderationRepository.updateNovelModerationStatus(novelId, status);

  Future<List<ReportEntity>> getReports({ReportStatus? status}) => _moderationRepository.getReports(status: status);
  Future<ReportEntity> submitReport(ReportEntity report) => _moderationRepository.submitReport(report);
  Future<void> resolveReport(String reportId, String note, ReportStatus resolution) =>
      _moderationRepository.resolveReport(reportId, note, resolution);

  Future<PlatformAnalyticsEntity> getPlatformAnalytics() => _analyticsRepository.getPlatformAnalytics();
}
