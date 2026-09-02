import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../domain/entities/episode_entity.dart';
import '../../../domain/usecases/episode_usecases.dart';
import '../../../core/services/logger_service.dart';
import '../../auth/controllers/auth_controller.dart';

class EpisodeEditorController extends GetxController {
  final String novelId;
  final String? existingEpisodeId;
  final EpisodeUseCases _episodeUseCases;
  final ILoggerService _logger;

  EpisodeEditorController(
    this.novelId,
    this.existingEpisodeId,
    this._episodeUseCases,
    this._logger,
  );

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxInt wordCount = 0.obs;
  final RxBool hasUnsavedChanges = false.obs;

  final TextEditingController numberController = TextEditingController(text: '1');
  final TextEditingController titleController = TextEditingController();
  final TextEditingController summaryController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    if (existingEpisodeId != null && existingEpisodeId!.isNotEmpty) {
      loadEpisode(existingEpisodeId!);
    } else {
      _calculateNextEpisodeNumber();
    }

    contentController.addListener(_onContentChanged);
    titleController.addListener(() => hasUnsavedChanges.value = true);
  }

  void _onContentChanged() {
    hasUnsavedChanges.value = true;
    final text = contentController.text.trim();
    if (text.isEmpty) {
      wordCount.value = 0;
    } else {
      wordCount.value = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    }
  }

  Future<void> _calculateNextEpisodeNumber() async {
    try {
      final episodes = await _episodeUseCases.getEpisodesForNovel(novelId, publishedOnly: false);
      numberController.text = '${episodes.length + 1}';
    } catch (_) {}
  }

  Future<void> loadEpisode(String episodeId) async {
    try {
      isLoading.value = true;
      final ep = await _episodeUseCases.getEpisodeById(novelId, episodeId);
      if (ep != null) {
        numberController.text = '${ep.episodeNumber}';
        titleController.text = ep.title;
        summaryController.text = ep.summary ?? '';
        contentController.text = ep.content;
        wordCount.value = ep.wordCount;
        hasUnsavedChanges.value = false;
      }
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      _logger.error('Failed to load episode', e);
    }
  }

  Future<void> saveEpisode({required bool publishImmediately}) async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar('Validation', 'Please provide a title for this episode.');
      return;
    }
    if (contentController.text.trim().isEmpty) {
      Get.snackbar('Validation', 'Please write some prose content for this episode.');
      return;
    }

    try {
      isSaving.value = true;
      final auth = Get.find<AuthController>();
      final user = auth.currentUser.value;

      final epNumber = int.tryParse(numberController.text) ?? 1;
      final status = publishImmediately ? EpisodeStatus.published : EpisodeStatus.draft;

      final episode = EpisodeEntity(
        id: existingEpisodeId ?? '',
        novelId: novelId,
        writerId: user?.id ?? 'writer_1',
        episodeNumber: epNumber,
        title: titleController.text.trim(),
        titleLowercase: titleController.text.trim().toLowerCase(),
        summary: summaryController.text.trim().isEmpty ? null : summaryController.text.trim(),
        content: contentController.text.trim(),
        wordCount: wordCount.value,
        status: status,
        publishedAt: publishImmediately ? DateTime.now() : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (existingEpisodeId != null && existingEpisodeId!.isNotEmpty) {
        await _episodeUseCases.updateEpisode(episode);
      } else {
        await _episodeUseCases.createEpisode(episode);
      }

      hasUnsavedChanges.value = false;
      isSaving.value = false;
      Get.back();
      Get.snackbar(
        publishImmediately ? 'Episode Published' : 'Draft Saved',
        publishImmediately ? 'Readers can now discover Chapter $epNumber!' : 'Episode saved to your draft workspace.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      isSaving.value = false;
      Get.snackbar('Error', 'Failed to save episode: $e');
    }
  }

  @override
  void onClose() {
    numberController.dispose();
    titleController.dispose();
    summaryController.dispose();
    contentController.dispose();
    super.onClose();
  }
}
