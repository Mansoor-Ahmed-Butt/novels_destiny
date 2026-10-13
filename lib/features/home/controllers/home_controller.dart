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

  final RxList<NovelEntity> genreNovels = <NovelEntity>[].obs;
  final RxBool isGenreLoading = false.obs;
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

      // Short delay on cold start — Firebase auth token may not be ready
      // before the first Firestore call, causing empty results silently.
      await Future.delayed(const Duration(milliseconds: 400));

      List<NovelEntity> featured = await _novelUseCases.getFeaturedNovels();
      List<NovelEntity> trending = await _novelUseCases.getTrendingNovels();

      // If empty, Firestore might still be initializing — retry once
      if (featured.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 600));
        featured = await _novelUseCases.getFeaturedNovels();
        trending = await _novelUseCases.getTrendingNovels();
      }

      featuredNovels.assignAll(featured);
      trendingNovels.assignAll(trending);

      // Load reading history for current user
      final authController = Get.find<AuthController>();
      final currentUser = authController.currentUser.value;
      if (currentUser != null) {
        try {
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
        } catch (historyErr) {
          _logger.warning('Reading history load failed (non-critical): $historyErr');
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

  Future<void> selectGenre(String genre) async {
    selectedGenre.value = genre;
    if (searchQuery.isNotEmpty) {
      onSearchChanged(searchQuery.value);
      return;
    }

    if (genre == 'All') {
      genreNovels.clear();
      return;
    }

    try {
      isGenreLoading.value = true;
      final results = await _novelUseCases.getNovelsByGenre(genre);
      if (results.isNotEmpty) {
        genreNovels.assignAll(results);
      } else {
        // Fallback: match against already loaded featured & trending novels
        final cleanGenre = genre.trim().toLowerCase();
        final localMatches = [...featuredNovels, ...trendingNovels].where((n) {
          final hasG = n.genreIds.any((g) {
            final cg = g.trim().toLowerCase();
            return cg == cleanGenre || cg.contains(cleanGenre) || cleanGenre.contains(cg);
          });
          final hasT = n.tags.any((t) {
            final ct = t.trim().toLowerCase();
            return ct == cleanGenre || ct.contains(cleanGenre) || cleanGenre.contains(ct);
          });
          return hasG || hasT;
        }).fold<Map<String, NovelEntity>>({}, (map, n) {
          map[n.id] = n;
          return map;
        }).values.toList();
        genreNovels.assignAll(localMatches);
      }
      isGenreLoading.value = false;
    } catch (e) {
      final cleanGenre = genre.trim().toLowerCase();
      final localMatches = [...featuredNovels, ...trendingNovels].where((n) {
        final hasG = n.genreIds.any((g) => g.trim().toLowerCase().contains(cleanGenre) || cleanGenre.contains(g.trim().toLowerCase()));
        final hasT = n.tags.any((t) => t.trim().toLowerCase().contains(cleanGenre) || cleanGenre.contains(t.trim().toLowerCase()));
        return hasG || hasT;
      }).fold<Map<String, NovelEntity>>({}, (map, n) {
        map[n.id] = n;
        return map;
      }).values.toList();
      genreNovels.assignAll(localMatches);
      isGenreLoading.value = false;
      _logger.error('Failed to load novels for genre $genre', e);
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
