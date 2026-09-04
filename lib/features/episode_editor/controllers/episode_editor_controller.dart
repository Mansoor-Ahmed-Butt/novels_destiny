import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/episode_entity.dart';
import '../../../domain/entities/content_block_entity.dart';
import '../../../domain/usecases/episode_usecases.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../../auth/controllers/auth_controller.dart';

class EpisodeEditorController extends GetxController {
  final String novelId;
  final String? existingEpisodeId;
  final EpisodeUseCases _episodeUseCases;
  final ILoggerService _logger;
  final SupabaseStorageService _storageService = SupabaseStorageService();

  EpisodeEditorController(
    this.novelId,
    this.existingEpisodeId,
    this._episodeUseCases,
    this._logger,
  );

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isUploadingMedia = false.obs;
  final RxInt wordCount = 0.obs;
  final RxBool hasUnsavedChanges = false.obs;

  final TextEditingController numberController = TextEditingController(text: '1');
  final TextEditingController titleController = TextEditingController();
  final TextEditingController summaryController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  final RxList<ContentBlockEntity> blocks = <ContentBlockEntity>[].obs;

  late String _currentEpisodeId;

  @override
  void onInit() {
    super.onInit();
    _currentEpisodeId = existingEpisodeId ?? const Uuid().v4();

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
    _recalculateWordCount();
  }

  void _recalculateWordCount() {
    int total = 0;
    final primaryText = contentController.text.trim();
    if (primaryText.isNotEmpty) {
      total += primaryText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    }
    for (final b in blocks) {
      if (b.type == ContentBlockType.text && b.content.trim().isNotEmpty) {
        total += b.content.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      }
    }
    wordCount.value = total;
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
        blocks.assignAll(ep.effectiveBlocks);
        _recalculateWordCount();
        hasUnsavedChanges.value = false;
      }
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      _logger.error('Failed to load episode', e);
    }
  }

  // ================= CONTENT BLOCKS ACTIONS =================
  void addTextBlock(String text) {
    if (text.trim().isEmpty) return;
    final newBlock = ContentBlockEntity(
      id: const Uuid().v4(),
      episodeId: _currentEpisodeId,
      type: ContentBlockType.text,
      order: blocks.length + 1,
      content: text.trim(),
    );
    blocks.add(newBlock);
    hasUnsavedChanges.value = true;
    _recalculateWordCount();
  }

  Future<void> pickAndAddImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, imageQuality: 85);
      if (picked == null) return;

      isUploadingMedia.value = true;
      final result = await _storageService.uploadEpisodeImage(
        novelId: novelId,
        episodeId: _currentEpisodeId,
        filePath: picked.path,
      );

      final block = ContentBlockEntity(
        id: const Uuid().v4(),
        episodeId: _currentEpisodeId,
        type: ContentBlockType.image,
        order: blocks.length + 1,
        storagePath: result['storagePath'],
        url: result['url'],
        caption: picked.name,
      );

      blocks.add(block);
      hasUnsavedChanges.value = true;
      isUploadingMedia.value = false;
      Get.snackbar('Image Uploaded', 'Inline image added to chapter.');
    } catch (e) {
      isUploadingMedia.value = false;
      Get.snackbar('Upload Error', e.toString());
    }
  }

  Future<void> pickAndAddPdf() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (files.isEmpty || files.first.path == null) return;

      isUploadingMedia.value = true;
      final file = files.first;

      final uploadRes = await _storageService.uploadEpisodePdf(
        novelId: novelId,
        episodeId: _currentEpisodeId,
        filePath: file.path!,
        originalFileName: file.name,
      );

      final block = ContentBlockEntity(
        id: const Uuid().v4(),
        episodeId: _currentEpisodeId,
        type: ContentBlockType.pdf,
        order: blocks.length + 1,
        storagePath: uploadRes['storagePath'],
        url: uploadRes['url'],
        fileName: file.name,
      );

      blocks.add(block);
      hasUnsavedChanges.value = true;
      isUploadingMedia.value = false;
      Get.snackbar('PDF Uploaded', 'PDF document added to chapter.');
    } catch (e) {
      isUploadingMedia.value = false;
      Get.snackbar('Upload Error', e.toString());
    }
  }

  void addAdBlock() {
    final block = ContentBlockEntity(
      id: const Uuid().v4(),
      episodeId: _currentEpisodeId,
      type: ContentBlockType.ad,
      order: blocks.length + 1,
      placement: 'inline',
    );
    blocks.add(block);
    hasUnsavedChanges.value = true;
    Get.snackbar('Ad Placement Added', 'An inline advertisement block will appear here for readers.');
  }

  void removeBlock(int index) {
    if (index >= 0 && index < blocks.length) {
      blocks.removeAt(index);
      _reindexBlocks();
      hasUnsavedChanges.value = true;
      _recalculateWordCount();
    }
  }

  void reorderBlocks(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = blocks.removeAt(oldIndex);
    blocks.insert(newIndex, item);
    _reindexBlocks();
    hasUnsavedChanges.value = true;
  }

  void _reindexBlocks() {
    for (int i = 0; i < blocks.length; i++) {
      blocks[i] = blocks[i].copyWith(order: i + 1);
    }
  }

  // ================= SAVE & PUBLISH =================
  Future<void> saveEpisode({required bool publishImmediately}) async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar('Validation', 'Please provide a title for this episode.');
      return;
    }

    final hasContent = contentController.text.trim().isNotEmpty || blocks.isNotEmpty;
    if (!hasContent) {
      Get.snackbar('Validation', 'Please write some prose or add content blocks for this episode.');
      return;
    }

    try {
      isSaving.value = true;
      final auth = Get.find<AuthController>();
      final user = auth.currentUser.value;

      final epNumber = int.tryParse(numberController.text) ?? 1;
      final status = publishImmediately ? EpisodeStatus.published : EpisodeStatus.draft;

      // Build effective blocks list
      List<ContentBlockEntity> finalBlocks = List<ContentBlockEntity>.from(blocks);
      if (finalBlocks.isEmpty && contentController.text.trim().isNotEmpty) {
        finalBlocks.add(
          ContentBlockEntity(
            id: const Uuid().v4(),
            episodeId: _currentEpisodeId,
            type: ContentBlockType.text,
            order: 1,
            content: contentController.text.trim(),
          ),
        );
      }

      final episode = EpisodeEntity(
        id: _currentEpisodeId,
        novelId: novelId,
        writerId: user?.id ?? 'writer_1',
        episodeNumber: epNumber,
        title: titleController.text.trim(),
        titleLowercase: titleController.text.trim().toLowerCase(),
        summary: summaryController.text.trim().isEmpty ? null : summaryController.text.trim(),
        content: contentController.text.trim().isNotEmpty ? contentController.text.trim() : (finalBlocks.isNotEmpty ? finalBlocks.first.content : ''),
        blocks: finalBlocks,
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
