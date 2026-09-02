import 'dart:async';
import 'package:get/get.dart';
import '../../../domain/entities/novel_entity.dart';
import '../../../domain/entities/reading_progress_entity.dart';
import '../../../domain/usecases/novel_usecases.dart';
import '../../../core/services/logger_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../app/routes/app_routes.dart';

class HomeController extends GetxController {
  final NovelUseCases _novelUseCases;
  final ILoggerService _logger;

  HomeController(this._novelUseCases, this._logger);

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  final RxList<NovelEntity> featuredNovels = <NovelEntity>[].obs;
  final RxList<NovelEntity> trendingNovels = <NovelEntity>[].obs;
  final RxList<NovelEntity> searchResults = <NovelEntity>[].obs;
  final RxList<ReadingProgressEntity> readingHistory = <ReadingProgressEntity>[].obs;
  final RxMap<String, NovelEntity> historyNovelMap = <String, NovelEntity>{}.obs;

  final RxString selectedGenre = 'All'.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;

  final List<String> availableGenres = [
    'All',
    'Fantasy',
    'Romance',
    'Sci-Fi',
    'Mystery',
    'Steampunk',
    'Gothic',
    'Historical',
    'Adventure',
  ];

  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    loadHomeData();
  }

  Future<void> loadHomeData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final featured = await _novelUseCases.getFeaturedNovels();
      final trending = await _novelUseCases.getTrendingNovels();
      featuredNovels.assignAll(featured);
      trendingNovels.assignAll(trending);

      // Load reading history for current user
      final authController = Get.find<AuthController>();
      final currentUser = authController.currentUser.value;
      if (currentUser != null) {
        final history = await _novelUseCases.getReadingHistory(currentUser.id);
        readingHistory.assignAll(history);

        // Fetch novel entities for history items
        for (final prog in history) {
          if (!historyNovelMap.containsKey(prog.novelId)) {
            final novel = await _novelUseCases.getNovelById(prog.novelId);
            if (novel != null) {
              historyNovelMap[prog.novelId] = novel;
            }
          }
        }
      }

      isLoading.value = false;
    } catch (e) {
      errorMessage.value = 'Failed to load stories: $e';
      isLoading.value = false;
      _logger.error('Error loading home data', e);
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    _searchDebounce?.cancel();

    if (query.trim().isEmpty) {
      isSearching.value = false;
      searchResults.clear();
      return;
    }

    isSearching.value = true;
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await _novelUseCases.searchNovels(
        query,
        genre: selectedGenre.value == 'All' ? null : selectedGenre.value,
      );
      searchResults.assignAll(results);
    });
  }

  void selectGenre(String genre) {
    selectedGenre.value = genre;
    if (searchQuery.isNotEmpty) {
      onSearchChanged(searchQuery.value);
    }
  }

  void openNovel(NovelEntity novel) {
    Get.toNamed(AppRoutes.novelDetails(novel.id));
  }

  void resumeReading(ReadingProgressEntity progress) {
    Get.toNamed(
      AppRoutes.episodeReader(progress.novelId, progress.episodeId),
    );
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }
}
