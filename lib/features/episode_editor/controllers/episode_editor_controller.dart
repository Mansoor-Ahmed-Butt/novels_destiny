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
import '../../../core/services/notification_service.dart';
import '../../../domain/usecases/novel_usecases.dart';
import '../../../core/errors/failures.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../admin_dashboard/controllers/admin_dashboard_controller.dart';

class EpisodeEditorController extends GetxController {
  final String novelId;
  final String? existingEpisodeId;
  final EpisodeUseCases _episodeUseCases;
  final ILoggerService _logger;
  final SupabaseStorageService _storageService = SupabaseStorageService();

  EpisodeEditorController(this.novelId, this.existingEpisodeId, this._episodeUseCases, this._logger);

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
  bool _isDisposed = false;
  bool _isCleaningUp = false;
  VoidCallback? _contentListenerRemover;
  VoidCallback? _titleListenerRemover;

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
    _contentListenerRemover = () {
      try {
        contentController.removeListener(_onContentChanged);
      } catch (_) {}
    };

    void titleListener() {
      if (_isDisposed) return;
      hasUnsavedChanges.value = true;
    }

    titleController.addListener(titleListener);
    _titleListenerRemover = () {
      try {
        titleController.removeListener(titleListener);
      } catch (_) {}
    };
  }

  void _onContentChanged() {
    if (_isDisposed) return;
    hasUnsavedChanges.value = true;
    _recalculateWordCount();
  }

  void _recalculateWordCount() {
    if (_isDisposed) return;
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
      if (_isDisposed) return;
      numberController.text = '${episodes.length + 1}';
    } catch (_) {}
  }

  Future<void> loadEpisode(String episodeId) async {
    try {
      isLoading.value = true;
      final ep = await _episodeUseCases.getEpisodeById(novelId, episodeId);
      if (_isDisposed) return;
      if (ep != null) {
        numberController.text = '${ep.episodeNumber}';
        titleController.text = ep.title;
        summaryController.text = ep.summary ?? '';
        contentController.text = ep.content;
        blocks.assignAll(ep.effectiveBlocks);
        _recalculateWordCount();
      }
      isLoading.value = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) hasUnsavedChanges.value = false;
      });
    } catch (e) {
      if (_isDisposed) return;
      isLoading.value = false;
      _logger.error('Failed to load episode', e);
    }
  }

  // ================= CONTENT BLOCKS ACTIONS =================
  void addTextBlock(String text) {
    if (_isDisposed) return;
    if (text.trim().isEmpty) return;
    final newBlock = ContentBlockEntity(id: const Uuid().v4(), episodeId: _currentEpisodeId, type: ContentBlockType.text, order: blocks.length + 1, content: text.trim());
    blocks.add(newBlock);
    hasUnsavedChanges.value = true;
    _recalculateWordCount();
  }

  Future<void> pickAndAddImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, imageQuality: 85);
      if (picked == null || _isDisposed) return;

      isUploadingMedia.value = true;
      final result = await _storageService.uploadEpisodeImage(
        novelId: novelId,
        episodeId: _currentEpisodeId,
        filePath: picked.path,
      );
      if (_isDisposed) return;

      final url = result['url'];
      if (url == null || (!url.startsWith('http://') && !url.startsWith('https://'))) {
        throw const StorageFailure('Upload completed without a valid cloud URL. Please verify your Supabase Storage settings.');
      }

      final block = ContentBlockEntity(
        id: const Uuid().v4(),
        episodeId: _currentEpisodeId,
        type: ContentBlockType.image,
        order: blocks.length + 1,
        storagePath: result['storagePath'],
        url: url,
        caption: picked.name,
      );

      blocks.add(block);
      hasUnsavedChanges.value = true;
      isUploadingMedia.value = false;
      Get.snackbar('Image Added', 'Illustration uploaded to Supabase and added to chapter.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      if (_isDisposed) return;
      isUploadingMedia.value = false;
      final msg = e is AppFailure ? e.message : e.toString();
      Get.snackbar(
        'Upload Failed',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 6),
      );
    }
  }

  Future<void> pickAndAddPdf() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (files.isEmpty || files.first.path == null || _isDisposed) return;

      isUploadingMedia.value = true;
      final file = files.first;

      final uploadRes = await _storageService.uploadEpisodePdf(
        novelId: novelId,
        episodeId: _currentEpisodeId,
        filePath: file.path!,
        originalFileName: file.name,
      );
      if (_isDisposed) return;

      final url = uploadRes['url'];
      if (url == null || (!url.startsWith('http://') && !url.startsWith('https://'))) {
        throw const StorageFailure('PDF upload completed without a valid cloud URL. Please verify your Supabase Storage settings.');
      }

      final block = ContentBlockEntity(
        id: const Uuid().v4(),
        episodeId: _currentEpisodeId,
        type: ContentBlockType.pdf,
        order: blocks.length + 1,
        storagePath: uploadRes['storagePath'],
        url: url,
        fileName: file.name,
      );

      blocks.add(block);
      hasUnsavedChanges.value = true;
      isUploadingMedia.value = false;
      Get.snackbar('PDF Uploaded', 'PDF document uploaded to Supabase and added to chapter.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      if (_isDisposed) return;
      isUploadingMedia.value = false;
      final msg = e is AppFailure ? e.message : e.toString();
      Get.snackbar(
        'Upload Failed',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 6),
      );
    }
  }

  void addAdBlock() {
    if (_isDisposed) return;
    final block = ContentBlockEntity(id: const Uuid().v4(), episodeId: _currentEpisodeId, type: ContentBlockType.ad, order: blocks.length + 1, placement: 'inline');
    blocks.add(block);
    hasUnsavedChanges.value = true;
    Get.snackbar('Ad Placement Added', 'An inline advertisement block will appear here for readers.');
  }

  void removeBlock(int index) {
    if (_isDisposed) return;
    if (index >= 0 && index < blocks.length) {
      blocks.removeAt(index);
      _reindexBlocks();
      hasUnsavedChanges.value = true;
      _recalculateWordCount();
    }
  }

  void reorderBlocks(int oldIndex, int newIndex) {
    if (_isDisposed) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final item = blocks.removeAt(oldIndex);
    blocks.insert(newIndex, item);
    _reindexBlocks();
    hasUnsavedChanges.value = true;
  }

  void _reindexBlocks() {
    if (_isDisposed) return;
    for (int i = 0; i < blocks.length; i++) {
      blocks[i] = blocks[i].copyWith(order: i + 1);
    }
  }

  // ================= SAVE & PUBLISH =================
  Future<void> saveEpisode({required bool publishImmediately}) async {
    if (_isDisposed || _isCleaningUp) return;
    if (titleController.text.trim().isEmpty) {
      Get.snackbar('Validation', 'Please provide a title for this episode.');
      return;
    }

    final hasContent = contentController.text.trim().isNotEmpty || blocks.isNotEmpty;
    if (!hasContent) {
      Get.snackbar('Validation', 'Please write some prose or add content blocks for this episode.');
      return;
    }

    if (publishImmediately) {
      for (final b in blocks) {
        if (b.type == ContentBlockType.image || b.type == ContentBlockType.pdf) {
          final isHttp = b.url != null && (b.url!.startsWith('http://') || b.url!.startsWith('https://'));
          final hasStoragePath = b.storagePath != null && b.storagePath!.trim().isNotEmpty;
          if (!isHttp && !hasStoragePath) {
            Get.snackbar(
              'Cannot Publish',
              'One or more media items were not uploaded to cloud storage. Please remove or re-upload them before publishing.',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 5),
            );
            return;
          }
        }
      }
    }

    try {
      isSaving.value = true;
      final auth = Get.find<AuthController>();
      final user = auth.currentUser.value;
      if (user == null) {
        isSaving.value = false;
        Get.snackbar('Sign In Required', 'Please sign in to save this episode.');
        return;
      }

      final epNumber = int.tryParse(numberController.text) ?? 1;
      final status = publishImmediately ? EpisodeStatus.published : EpisodeStatus.draft;

      // Build effective blocks list
      List<ContentBlockEntity> finalBlocks = List<ContentBlockEntity>.from(blocks);
      final prose = contentController.text.trim();
      if (prose.isNotEmpty) {
        final existingTextIdx =
            finalBlocks.indexWhere((b) => b.type == ContentBlockType.text);
        if (existingTextIdx >= 0) {
          finalBlocks[existingTextIdx] =
              finalBlocks[existingTextIdx].copyWith(content: prose);
        } else {
          finalBlocks.insert(
            0,
            ContentBlockEntity(
              id: const Uuid().v4(),
              episodeId: _currentEpisodeId,
              type: ContentBlockType.text,
              order: 1,
              content: prose,
            ),
          );
        }
      }
      for (int i = 0; i < finalBlocks.length; i++) {
        finalBlocks[i] = finalBlocks[i].copyWith(order: i + 1);
      }

      final episode = EpisodeEntity(
        id: _currentEpisodeId,
        novelId: novelId,
        writerId: user.id,
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
      if (_isDisposed) return;

      if (publishImmediately) {
        String novelTitle = 'Novel';
        try {
          if (Get.isRegistered<NovelUseCases>()) {
            final n = await Get.find<NovelUseCases>().getNovelById(novelId);
            if (n != null) novelTitle = n.title;
          }
        } catch (_) {}

        NotificationService.to.broadcastNewEpisodeNotification(
          novelId: novelId,
          episodeId: _currentEpisodeId,
          novelTitle: novelTitle,
          episodeNumber: epNumber,
          episodeTitle: titleController.text.trim(),
          writerName: user.displayName,
        );
      }

      // ── Refresh admin dashboard if active (writer dashboard will refresh upon returning from navigation) ──
      if (Get.isRegistered<AdminDashboardController>()) {
        Get.find<AdminDashboardController>().loadDashboard();
      }

      hasUnsavedChanges.value = false;
      isSaving.value = false;
      _isCleaningUp = true;

      final tag = '$novelId-${existingEpisodeId ?? "__new__"}';
      Get.back(result: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<EpisodeEditorController>(tag: tag)) {
          Get.delete<EpisodeEditorController>(tag: tag, force: true);
        }
      });

      Get.snackbar(publishImmediately ? 'Episode Published' : 'Draft Saved', publishImmediately ? 'Readers can now discover Chapter $epNumber!' : 'Episode saved to your draft workspace.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      if (_isDisposed) return;
      isSaving.value = false;
      Get.snackbar('Error', 'Failed to save episode: $e');
    }
  }

  @override
  void onClose() {
    if (_isCleaningUp) {
      super.onClose();
      return;
    }
    _isCleaningUp = true;
    _isDisposed = true;

    try {
      _contentListenerRemover?.call();
      _contentListenerRemover = null;
    } catch (_) {}
    try {
      _titleListenerRemover?.call();
      _titleListenerRemover = null;
    } catch (_) {}

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        numberController.dispose();
        titleController.dispose();
        summaryController.dispose();
        contentController.dispose();
      } catch (_) {}
    });

    super.onClose();
  }
}
