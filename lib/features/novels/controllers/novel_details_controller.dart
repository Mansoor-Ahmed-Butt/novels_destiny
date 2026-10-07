import 'package:get/get.dart';
import '../../../domain/entities/episode_entity.dart';
import '../../../domain/entities/content_block_entity.dart';
import '../../../domain/usecases/novel_usecases.dart';
import '../../../domain/usecases/episode_usecases.dart';
import '../../../domain/usecases/admin_usecases.dart';
import '../../../domain/entities/report_entity.dart';
import '../../../core/services/logger_service.dart';
import '../states/novel_details_state.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/ad_service.dart';

class NovelDetailsController extends GetxController {
  final String novelId;
  final NovelUseCases _novelUseCases;
  final EpisodeUseCases _episodeUseCases;
  final AdminUseCases _adminUseCases;
  final ILoggerService _logger;

  NovelDetailsController(
    this.novelId,
    this._novelUseCases,
    this._episodeUseCases,
    this._adminUseCases,
    this._logger,
  );

  final Rx<NovelDetailsState> state = Rx<NovelDetailsState>(const NovelDetailsLoading());

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      state.value = const NovelDetailsLoading();
      final novel = await _novelUseCases.getNovelById(novelId);
      if (novel == null) {
        state.value = const NovelDetailsFailure('Story not found.');
        return;
      }

      var episodes = await _episodeUseCases.getEpisodesForNovel(novelId, publishedOnly: true);

      // Auto-fallback: If no episodes exist but novel has manuscript, PDF, or gallery,
      // create Chapter 1 so the reader can start reading immediately!
      if (episodes.isEmpty &&
          ((novel.manuscriptContent != null && novel.manuscriptContent!.isNotEmpty) ||
              (novel.pdfUrl != null && novel.pdfUrl!.isNotEmpty) ||
              novel.galleryImageUrls.isNotEmpty)) {
        final blocks = <ContentBlockEntity>[];
        int blockOrder = 1;

        for (int i = 0; i < novel.galleryImageUrls.length; i++) {
          blocks.add(
            ContentBlockEntity(
              id: 'block_art_$i',
              episodeId: 'ep_complete',
              type: ContentBlockType.image,
              order: blockOrder++,
              url: novel.galleryImageUrls[i],
              caption: 'Illustration ${i + 1}',
            ),
          );
        }

        if (novel.manuscriptContent != null && novel.manuscriptContent!.isNotEmpty) {
          blocks.add(
            ContentBlockEntity(
              id: 'block_text_main',
              episodeId: 'ep_complete',
              type: ContentBlockType.text,
              order: blockOrder++,
              content: novel.manuscriptContent!,
            ),
          );
        }

        if (novel.pdfUrl != null && novel.pdfUrl!.isNotEmpty) {
          blocks.add(
            ContentBlockEntity(
              id: 'block_pdf_main',
              episodeId: 'ep_complete',
              type: ContentBlockType.pdf,
              order: blockOrder++,
              url: novel.pdfUrl,
              fileName: novel.pdfFileName ?? '${novel.title}.pdf',
            ),
          );
        }

        final autoEp = EpisodeEntity(
          id: 'ep_complete',
          novelId: novelId,
          writerId: novel.writerId,
          episodeNumber: 1,
          title: novel.pdfUrl != null && (novel.manuscriptContent == null || novel.manuscriptContent!.isEmpty)
              ? 'Complete Novel (PDF Edition)'
              : 'Complete Story: ${novel.title}',
          titleLowercase: 'complete story: ${novel.title.toLowerCase()}',
          summary: novel.description,
          content: novel.manuscriptContent ?? '',
          blocks: blocks,
          wordCount: (novel.manuscriptContent ?? '').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
          status: EpisodeStatus.published,
          createdAt: novel.createdAt,
          updatedAt: novel.updatedAt,
          publishedAt: novel.publishedAt ?? DateTime.now(),
        );

        try {
          await _episodeUseCases.createEpisode(autoEp);
          episodes = [autoEp];
        } catch (_) {}
      }

      final auth = Get.find<AuthController>();
      final uid = auth.currentUser.value?.id ?? '';

      final isLiked = uid.isNotEmpty ? await _novelUseCases.isNovelLiked(novelId, uid) : false;
      final isSaved = uid.isNotEmpty ? await _novelUseCases.isNovelSaved(novelId, uid) : false;
      final progress = uid.isNotEmpty ? await _novelUseCases.getReadingProgress(uid, novelId) : null;

      state.value = NovelDetailsReady(
        novel: novel,
        episodes: episodes,
        isLiked: isLiked,
        isSaved: isSaved,
        readingProgress: progress,
      );

      AdService().preloadInterstitial();
    } catch (e) {
      state.value = NovelDetailsFailure('Failed to load story: $e');
      _logger.error('Failed to load novel details', e);
    }
  }

  Future<void> toggleLike() async {
    final current = state.value;
    if (current is! NovelDetailsReady) return;

    final auth = Get.find<AuthController>();
    final user = auth.currentUser.value;
    if (user == null) {
      Get.snackbar('Sign In Required', 'Please sign in to like this story.');
      return;
    }

    await _novelUseCases.toggleLikeNovel(novelId, user.id);
    final updatedLiked = !current.isLiked;
    final updatedNovel = current.novel.copyWith(
      totalLikes: updatedLiked ? current.novel.totalLikes + 1 : (current.novel.totalLikes - 1).clamp(0, 999999),
    );

    state.value = current.copyWith(
      novel: updatedNovel,
      isLiked: updatedLiked,
    );
  }

  Future<void> toggleSave() async {
    final current = state.value;
    if (current is! NovelDetailsReady) return;

    final auth = Get.find<AuthController>();
    final user = auth.currentUser.value;
    if (user == null) {
      Get.snackbar('Sign In Required', 'Please sign in to save stories to your library.');
      return;
    }

    await _novelUseCases.toggleSaveNovel(novelId, user.id);
    state.value = current.copyWith(isSaved: !current.isSaved);
    Get.snackbar(
      current.isSaved ? 'Removed from Library' : 'Saved to Library',
      current.isSaved ? 'Story removed from your collection.' : 'Story added to your personal library.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> downloadFullNovel() async {
    final current = state.value;
    if (current is! NovelDetailsReady) return;

    final auth = Get.find<AuthController>();
    final user = auth.currentUser.value;
    if (user == null) {
      Get.snackbar('Sign In Required', 'Please sign in to download complete novels.');
      return;
    }

    await _novelUseCases.recordDownload(user.id, novelId);
    state.value = current.copyWith(
      novel: current.novel.copyWith(totalDownloads: current.novel.totalDownloads + 1),
    );

    Get.snackbar(
      'Download Complete',
      '${current.novel.title} is now available in your offline library shelf.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void openEpisode(EpisodeEntity episode) {
    Get.toNamed(AppRoutes.episodeReader(novelId, episode.id));
  }

  void startReading() {
    final current = state.value;
    if (current is! NovelDetailsReady) return;

    if (current.readingProgress != null) {
      Get.toNamed(AppRoutes.episodeReader(novelId, current.readingProgress!.episodeId));
    } else if (current.episodes.isNotEmpty) {
      Get.toNamed(AppRoutes.episodeReader(novelId, current.episodes.first.id));
    } else {
      Get.snackbar('No Episodes', 'No published episodes are available yet.');
    }
  }

  Future<void> submitReport(String reason) async {
    final current = state.value;
    if (current is! NovelDetailsReady) return;

    final auth = Get.find<AuthController>();
    final user = auth.currentUser.value;

    await _adminUseCases.submitReport(
      ReportEntity(
        id: '',
        reporterId: user?.id ?? 'anonymous',
        reporterName: user?.displayName ?? 'Reader',
        targetType: 'novel',
        targetId: novelId,
        targetTitle: current.novel.title,
        reason: reason,
        createdAt: DateTime.now(),
      ),
    );

    Get.snackbar(
      'Report Submitted',
      'Thank you for helping keep our reading community safe. Our editorial team will review this story.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
