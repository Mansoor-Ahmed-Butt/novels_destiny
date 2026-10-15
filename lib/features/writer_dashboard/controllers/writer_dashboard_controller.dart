import 'package:get/get.dart';
import '../../../domain/entities/novel_entity.dart';
import '../../../domain/entities/analytics_entity.dart';
import '../../../domain/usecases/novel_usecases.dart';
import '../../../domain/usecases/writer_usecases.dart';
import '../../../core/services/logger_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../app/routes/app_routes.dart';

class WriterDashboardController extends GetxController {
  final NovelUseCases _novelUseCases;
  final WriterUseCases _writerUseCases;
  final ILoggerService _logger;

  WriterDashboardController(
    this._novelUseCases,
    this._writerUseCases,
    this._logger,
  );

  final RxBool isLoading = true.obs;
  final RxList<NovelEntity> myNovels = <NovelEntity>[].obs;
  final Rx<WriterAnalyticsEntity?> analytics = Rx<WriterAnalyticsEntity?>(null);

  @override
  void onInit() {
    super.onInit();
    loadDashboard();

    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      ever(auth.currentUser, (user) {
        if (user != null) {
          loadDashboard();
        } else {
          myNovels.clear();
          analytics.value = null;
        }
      });
    }
  }

  DateTime? _lastLoadTime;

  Future<void> loadDashboard({bool force = false}) async {
    final now = DateTime.now();
    if (!force && _lastLoadTime != null && now.difference(_lastLoadTime!) < const Duration(milliseconds: 1500)) {
      return;
    }
    _lastLoadTime = now;

    try {
      isLoading.value = true;
      final auth = Get.find<AuthController>();
      final user = auth.currentUser.value;
      if (user == null) {
        isLoading.value = false;
        return;
      }

      final novels = await _novelUseCases.getNovelsByWriter(user.id);
      final stats = await _writerUseCases.getWriterAnalytics(user.id);

      myNovels.assignAll(novels);

      // Compute total published episodes directly across all author novels
      final totalPublished = novels.fold<int>(
        0,
        (sum, n) => sum + n.publishedEpisodeCount,
      );

      analytics.value = stats.copyWith(
        totalNovels: novels.length,
        publishedEpisodes: totalPublished,
      );

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      _logger.error('Failed to load writer dashboard', e);
    }
  }

  void createNewNovel() async {
    final result = await Get.toNamed(AppRoutes.novelEditor());
    if (result == true) {
      loadDashboard(force: true);
    }
  }

  void editNovel(NovelEntity novel) async {
    final result = await Get.toNamed(AppRoutes.novelEditor(novelId: novel.id));
    if (result == true) {
      loadDashboard(force: true);
    }
  }

  void createEpisode(NovelEntity novel) async {
    final result = await Get.toNamed(AppRoutes.episodeEditor(novelId: novel.id));
    if (result == true) {
      loadDashboard(force: true);
    }
  }

  void viewNovel(NovelEntity novel) async {
    await Get.toNamed(AppRoutes.novelDetails(novel.id));
    loadDashboard(force: true);
  }
}
