import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../domain/entities/episode_entity.dart';
import '../../../domain/entities/content_block_entity.dart';
import '../../../domain/entities/reading_progress_entity.dart';
import '../../../domain/usecases/novel_usecases.dart';
import '../../../domain/usecases/episode_usecases.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/episode_reader_ad_placements.dart';
import '../states/episode_reader_state.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/services/ad_service.dart';

class EpisodeReaderController extends GetxController {
  final String novelId;
  final String initialEpisodeId;
  final NovelUseCases _novelUseCases;
  final EpisodeUseCases _episodeUseCases;
  final ILoggerService _logger;

  EpisodeReaderController(
    this.novelId,
    this.initialEpisodeId,
    this._novelUseCases,
    this._episodeUseCases,
    this._logger,
  );

  final Rx<EpisodeReaderState> state = Rx<EpisodeReaderState>(const EpisodeReaderLoading());
  final ScrollController scrollController = ScrollController();

  // Reader Customization State
  final RxDouble fontSize = 17.0.obs;
  final Rx<ReaderColorTheme> colorTheme = ReaderColorTheme.cream.obs;
  final Rx<ReaderFontFamily> fontFamily = ReaderFontFamily.serif.obs;
  final RxDouble lineHeight = 1.7.obs;
  final RxBool showControls = true.obs;

  // Lightweight progress observable: prevents rebuilding entire chapter widget tree during scroll
  final RxDouble progressPercent = 0.0.obs;

  // Pre-computed ordered blocks: calculated once per chapter load
  final RxList<ContentBlockEntity> readingBlocks = <ContentBlockEntity>[].obs;

  late String _currentEpisodeId;
  Timer? _progressDebounce;

  @override
  void onInit() {
    super.onInit();
    _currentEpisodeId = initialEpisodeId;
    loadEpisode(_currentEpisodeId);
    scrollController.addListener(_onScroll);
  }

  Future<void> loadEpisode(String episodeId) async {
    final role = Get.find<AuthController>().currentUser.value?.role;
    await AdService().showInterstitialForEpisode(episodeId, role: role);

    try {
      state.value = const EpisodeReaderLoading();
      _currentEpisodeId = episodeId;

      final novel = await _novelUseCases.getNovelById(novelId);
      if (novel == null) {
        state.value = const EpisodeReaderFailure('Novel not found');
        return;
      }

      final allEpisodes =
          await _episodeUseCases.getEpisodesForNovel(novelId, publishedOnly: true);
      final currentEpIdx = allEpisodes.indexWhere((e) => e.id == episodeId);
      if (currentEpIdx < 0) {
        state.value = const EpisodeReaderFailure('Episode not found');
        return;
      }

      final currentEp =
          await _episodeUseCases.getEpisodeById(novelId, episodeId) ??
              allEpisodes[currentEpIdx];
      final prevEp = currentEpIdx > 0 ? allEpisodes[currentEpIdx - 1] : null;
      final nextEp =
          currentEpIdx < allEpisodes.length - 1 ? allEpisodes[currentEpIdx + 1] : null;

      _episodeUseCases.incrementEpisodeView(novelId, episodeId);

      final auth = Get.find<AuthController>();
      final uid = auth.currentUser.value?.id;
      double savedProgress = 0.0;
      if (uid != null) {
        final existing = await _novelUseCases.getReadingProgress(uid, novelId);
        if (existing != null && existing.episodeId == episodeId) {
          savedProgress = existing.progressPercent;
        }
      }

      // Pre-compute interleaved reading blocks once
      final showAds = AdService().shouldShowAdsFor(role: role);
      final blocks = EpisodeReaderAdPlacements.forReading(
        currentEp.effectiveBlocks,
        episodeId: episodeId,
        injectAds: showAds,
      );
      readingBlocks.assignAll(blocks);
      progressPercent.value = savedProgress;

      state.value = EpisodeReaderReady(
        novel: novel,
        currentEpisode: currentEp,
        allEpisodes: allEpisodes,
        previousEpisode: prevEp,
        nextEpisode: nextEp,
        progressPercent: savedProgress,
      );

      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
    } catch (e) {
      state.value = EpisodeReaderFailure('Failed to load chapter: $e');
      _logger.error('Failed to load episode $episodeId', e);
    }
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final max = scrollController.position.maxScrollExtent;
    final current = scrollController.position.pixels;
    if (max <= 0) return;

    final progress = (current / max).clamp(0.0, 1.0);
    // Only update the lightweight progress observable, do NOT rebuild the entire page state
    progressPercent.value = progress;
    _debounceSaveProgress(progress, current);
  }

  void _debounceSaveProgress(double progress, double offset) {
    _progressDebounce?.cancel();
    _progressDebounce = Timer(const Duration(seconds: 2), () async {
      final auth = Get.find<AuthController>();
      final user = auth.currentUser.value;
      final s = state.value;
      if (user != null && s is EpisodeReaderReady) {
        await _novelUseCases.saveReadingProgress(
          user.id,
          ReadingProgressEntity(
            novelId: novelId,
            episodeId: s.currentEpisode.id,
            episodeNumber: s.currentEpisode.episodeNumber,
            scrollOffset: offset,
            progressPercent: progress,
            updatedAt: DateTime.now(),
          ),
        );
        _logger.debug(
          'Progress auto-saved for novel $novelId, ep ${s.currentEpisode.episodeNumber}: ${(progress * 100).toInt()}%',
        );
      }
    });
  }

  void toggleControls() {
    showControls.value = !showControls.value;
  }

  void adjustFontSize(double delta) {
    final next = (fontSize.value + delta).clamp(12.0, 28.0);
    fontSize.value = next;
  }

  void setColorTheme(ReaderColorTheme theme) {
    colorTheme.value = theme;
  }

  void setFontFamily(ReaderFontFamily family) {
    fontFamily.value = family;
  }

  void goToEpisode(EpisodeEntity episode) {
    loadEpisode(episode.id);
  }

  void goToPreviousEpisode() {
    final s = state.value;
    if (s is EpisodeReaderReady && s.previousEpisode != null) {
      loadEpisode(s.previousEpisode!.id);
    }
  }

  void goToNextEpisode() {
    final s = state.value;
    if (s is EpisodeReaderReady && s.nextEpisode != null) {
      loadEpisode(s.nextEpisode!.id);
    }
  }

  @override
  void onClose() {
    _progressDebounce?.cancel();
    scrollController.dispose();
    super.onClose();
  }
}
