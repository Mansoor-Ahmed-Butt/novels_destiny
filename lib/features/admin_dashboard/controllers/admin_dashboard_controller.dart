import 'package:get/get.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/entities/novel_entity.dart';
import '../../../domain/entities/report_entity.dart';
import '../../../domain/entities/analytics_entity.dart';
import '../../../domain/usecases/admin_usecases.dart';
import '../../../core/services/logger_service.dart';

class AdminDashboardController extends GetxController {
  final AdminUseCases _adminUseCases;
  final ILoggerService _logger;

  AdminDashboardController(this._adminUseCases, this._logger);

  final RxBool isLoading = true.obs;
  final Rx<PlatformAnalyticsEntity?> analytics = Rx<PlatformAnalyticsEntity?>(null);
  final RxList<UserEntity> users = <UserEntity>[].obs;
  final RxList<UserEntity> pendingWriters = <UserEntity>[].obs;
  final RxList<NovelEntity> pendingNovels = <NovelEntity>[].obs;
  final RxList<ReportEntity> reports = <ReportEntity>[].obs;
  final RxInt selectedTab = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      isLoading.value = true;
      final platformStats = await _adminUseCases.getPlatformAnalytics();
      final allUsers = await _adminUseCases.getAllUsers();
      final pendingApplicants = await _adminUseCases.getPendingWriters();
      final pending = await _adminUseCases.getPendingNovels();
      final repList = await _adminUseCases.getReports();

      analytics.value = platformStats;
      users.assignAll(allUsers);
      pendingWriters.assignAll(pendingApplicants);
      pendingNovels.assignAll(pending);
      reports.assignAll(repList);

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      _logger.error('Failed to load admin metrics', e);
    }
  }

  Future<void> approveWriter(UserEntity writer) async {
    try {
      await _adminUseCases.approveWriter(writer.id);
      pendingWriters.removeWhere((w) => w.id == writer.id);
      final idx = users.indexWhere((u) => u.id == writer.id);
      if (idx >= 0) {
        users[idx] = writer.copyWith(approvalStatus: ApprovalStatus.approved);
      }
      Get.snackbar(
        'Writer Approved',
        '${writer.displayName} has been approved and granted Writer Studio access.',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to approve writer');
    }
  }

  Future<void> rejectWriter(UserEntity writer) async {
    try {
      await _adminUseCases.rejectWriter(writer.id);
      pendingWriters.removeWhere((w) => w.id == writer.id);
      final idx = users.indexWhere((u) => u.id == writer.id);
      if (idx >= 0) {
        users[idx] = writer.copyWith(approvalStatus: ApprovalStatus.rejected);
      }
      Get.snackbar(
        'Application Rejected',
        '${writer.displayName}\'s writer application was rejected.',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to reject writer');
    }
  }

  Future<void> approveNovel(NovelEntity novel) async {
    try {
      await _adminUseCases.updateNovelModerationStatus(novel.id, ModerationStatus.approved);
      pendingNovels.removeWhere((n) => n.id == novel.id);
      Get.snackbar('Approved', '${novel.title} is now visible to readers.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to approve novel');
    }
  }

  Future<void> rejectNovel(NovelEntity novel) async {
    try {
      await _adminUseCases.updateNovelModerationStatus(novel.id, ModerationStatus.rejected);
      pendingNovels.removeWhere((n) => n.id == novel.id);
      Get.snackbar('Rejected', '${novel.title} has been marked rejected.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to reject novel');
    }
  }

  Future<void> resolveReport(ReportEntity report) async {
    try {
      await _adminUseCases.resolveReport(report.id, 'Reviewed and action completed by Admin.', ReportStatus.resolved);
      final idx = reports.indexWhere((r) => r.id == report.id);
      if (idx >= 0) {
        reports[idx] = report.copyWith(status: ReportStatus.resolved, resolutionNote: 'Resolved by Admin');
      }
      Get.snackbar('Report Resolved', 'The flagged report has been marked resolved.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to resolve report');
    }
  }

  Future<void> toggleUserStatus(UserEntity user) async {
    try {
      final newStatus = !user.isActive;
      await _adminUseCases.updateUserStatus(user.id, newStatus);
      final idx = users.indexWhere((u) => u.id == user.id);
      if (idx >= 0) {
        users[idx] = user.copyWith(isActive: newStatus);
      }
      Get.snackbar(
        newStatus ? 'User Activated' : 'User Suspended',
        '${user.displayName} is now ${newStatus ? 'active' : 'suspended'}.',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update user status');
    }
  }
}
