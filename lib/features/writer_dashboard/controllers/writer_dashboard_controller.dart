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
  }

  Future<void> loadDashboard() async {
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
      analytics.value = stats;

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      _logger.error('Failed to load writer dashboard', e);
    }
  }

  void createNewNovel() {
    Get.toNamed(AppRoutes.novelEditor());
  }

  void editNovel(NovelEntity novel) {
    Get.toNamed(AppRoutes.novelEditor(novelId: novel.id));
  }

  void createEpisode(NovelEntity novel) {
    Get.toNamed(AppRoutes.episodeEditor(novelId: novel.id));
  }

  void viewNovel(NovelEntity novel) {
    Get.toNamed(AppRoutes.novelDetails(novel.id));
  }
}
