import 'package:get/get.dart';
import '../../../domain/entities/novel_entity.dart';
import '../../../domain/entities/reading_progress_entity.dart';
import '../../../domain/usecases/novel_usecases.dart';
import '../../../core/services/logger_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../app/routes/app_routes.dart';

class LibraryController extends GetxController {
  final NovelUseCases _novelUseCases;
  final ILoggerService _logger;

  LibraryController(this._novelUseCases, this._logger);

  final RxInt selectedTabIndex = 0.obs;
  final RxBool isLoading = true.obs;

  final RxList<NovelEntity> savedNovels = <NovelEntity>[].obs;
  final RxList<ReadingProgressEntity> history = <ReadingProgressEntity>[].obs;
  final RxMap<String, NovelEntity> historyNovelMap = <String, NovelEntity>{}.obs;
  final RxList<NovelEntity> downloadedNovels = <NovelEntity>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadLibrary();
  }

  Future<void> loadLibrary() async {
    try {
      isLoading.value = true;
      final auth = Get.find<AuthController>();
      final user = auth.currentUser.value;
      if (user == null) {
        isLoading.value = false;
        return;
      }

      final saved = await _novelUseCases.getSavedNovels(user.id);
      final hist = await _novelUseCases.getReadingHistory(user.id);
      final down = await _novelUseCases.getDownloadedNovels(user.id);

      savedNovels.assignAll(saved);
      history.assignAll(hist);
      downloadedNovels.assignAll(down);

      for (final h in hist) {
        if (!historyNovelMap.containsKey(h.novelId)) {
          final novel = await _novelUseCases.getNovelById(h.novelId);
          if (novel != null) {
            historyNovelMap[h.novelId] = novel;
          }
        }
      }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      _logger.error('Failed to load library data', e);
    }
  }

  void openNovel(NovelEntity novel) {
    Get.toNamed(AppRoutes.novelDetails(novel.id));
  }

  void resumeEpisode(ReadingProgressEntity prog) {
    Get.toNamed(AppRoutes.episodeReader(prog.novelId, prog.episodeId));
  }
}
