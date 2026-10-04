import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/novel_entity.dart';
import '../../../domain/entities/episode_entity.dart';
import '../../../domain/entities/content_block_entity.dart';
import '../../../domain/usecases/novel_usecases.dart';
import '../../../domain/usecases/episode_usecases.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../writer_dashboard/controllers/writer_dashboard_controller.dart';
import '../../admin_dashboard/controllers/admin_dashboard_controller.dart';

class NovelEditorController extends GetxController {
  final String? existingNovelId;
  final NovelUseCases _novelUseCases;
  final ILoggerService _logger;
  final EpisodeUseCases _episodeUseCases = Get.find<EpisodeUseCases>();
  final SupabaseStorageService _storageService = SupabaseStorageService();

  NovelEditorController(this.existingNovelId, this._novelUseCases, this._logger);

  // Safety flag: set to true in onClose() so async callbacks don't touch
  // disposed TextEditingControllers or reactive observables after disposal.
  bool _isDisposed = false;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isUploadingCover = false.obs;
  final Rx<NovelStatus> status = NovelStatus.ongoing.obs;
  final RxBool isDownloadEnabled = false.obs;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController coverUrlController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();
  String? coverStoragePath;

  // ── Novel Gallery / Illustrations (Up to 5 images) ──────────────────────
  final RxList<String> galleryImages = <String>[].obs;
  final RxBool isUploadingGalleryImage = false.obs;

  // ── Novel Story Content: Type Complete Novel OR Upload PDF ───────────────
  final RxInt selectedContentMode = 0.obs; // 0 = Type Manuscript, 1 = Upload PDF
  final TextEditingController manuscriptController = TextEditingController();
  final RxInt manuscriptWordCount = 0.obs;
  final RxInt manuscriptCharCount = 0.obs;

  final Rx<String?> pdfUrl = Rx<String?>(null);
  final Rx<String?> pdfStoragePath = Rx<String?>(null);
  final Rx<String?> pdfFileName = Rx<String?>(null);
  final RxBool isUploadingPdf = false.obs;

  late String _activeNovelId;

  final RxList<String> selectedGenres = <String>['Fantasy'].obs;
  final List<String> availableGenres = [
    'Fantasy',
    'Romance',
    'Sci-Fi',
    'Mystery',
    'Steampunk',
    'Gothic',
    'Historical',
    'Adventure',
    'Thriller',
  ];

  final List<String> sampleCoverPresets = [
    'https://images.unsplash.com/photo-1532012164546-f432f2e3edd7?w=600&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=600&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=600&auto=format&fit=crop&q=80',
  ];

  @override
  void onInit() {
    super.onInit();
    _activeNovelId = existingNovelId ?? const Uuid().v4();

    manuscriptController.addListener(_recalculateManuscriptStats);

    if (existingNovelId != null && existingNovelId!.isNotEmpty) {
      loadExistingNovel(existingNovelId!);
    } else {
      coverUrlController.text = sampleCoverPresets.first;
    }
  }

  void _recalculateManuscriptStats() {
    final text = manuscriptController.text;
    manuscriptCharCount.value = text.length;
    if (text.trim().isEmpty) {
      manuscriptWordCount.value = 0;
    } else {
      manuscriptWordCount.value =
          text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    }
  }

  Future<void> loadExistingNovel(String id) async {
    try {
      isLoading.value = true;
      final novel = await _novelUseCases.getNovelById(id);
      if (novel != null) {
        titleController.text = novel.title;
        descriptionController.text = novel.description;
        coverUrlController.text = novel.coverUrl;
        coverStoragePath = novel.coverStoragePath;
        tagsController.text = novel.tags.join(', ');
        selectedGenres.assignAll(novel.genreIds);
        status.value = novel.status;
        isDownloadEnabled.value = novel.isDownloadEnabled;

        galleryImages.assignAll(novel.galleryImageUrls);
        pdfUrl.value = novel.pdfUrl;
        pdfStoragePath.value = novel.pdfStoragePath;
        pdfFileName.value = novel.pdfFileName;

        if (novel.manuscriptContent != null &&
            novel.manuscriptContent!.isNotEmpty) {
          manuscriptController.text = novel.manuscriptContent!;
          selectedContentMode.value = 0;
        } else if (novel.pdfUrl != null && novel.pdfUrl!.isNotEmpty) {
          selectedContentMode.value = 1;
        }
      }
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      _logger.error('Failed to load existing novel for edit', e);
    }
  }

  void toggleGenre(String genre) {
    if (selectedGenres.contains(genre)) {
      if (selectedGenres.length > 1) {
        selectedGenres.remove(genre);
      }
    } else {
      selectedGenres.add(genre);
    }
  }

  void setCoverPreset(String url) {
    coverUrlController.text = url;
    coverStoragePath = null;
  }

  Future<void> pickAndUploadCover() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: ImageSource.gallery, maxWidth: 1080, imageQuality: 85);
      if (picked == null || _isDisposed) return;

      isUploadingCover.value = true;
      final publicUrl = await _storageService.uploadNovelCover(
        novelId: _activeNovelId,
        filePath: picked.path,
      );
      if (_isDisposed) return;

      coverUrlController.text = publicUrl;
      coverStoragePath =
          'novels/$_activeNovelId/cover.${picked.path.split('.').last}';
      isUploadingCover.value = false;
      Get.snackbar('Cover Uploaded', 'Artwork successfully uploaded to Supabase Storage.');
    } catch (e) {
      if (_isDisposed) return;
      isUploadingCover.value = false;
      Get.snackbar('Upload Failed', e.toString());
    }
  }

  // ── Novel Gallery Picker (Up to 5 images) ─────────────────────────────────
  Future<void> pickAndAddGalleryImage() async {
    if (galleryImages.length >= 5) {
      Get.snackbar(
        'Maximum Limit Reached',
        'You can upload up to 5 illustrations per novel.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (picked == null || _isDisposed) return;

      isUploadingGalleryImage.value = true;
      final result = await _storageService.uploadNovelGalleryImage(
        novelId: _activeNovelId,
        filePath: picked.path,
      );
      if (_isDisposed) return;

      final url = result['url'] ?? '';
      if (url.isNotEmpty && galleryImages.length < 5) {
        galleryImages.add(url);
        Get.snackbar(
          'Image Added',
          'Illustration added to novel gallery (${galleryImages.length}/5).',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      isUploadingGalleryImage.value = false;
    } catch (e) {
      if (_isDisposed) return;
      isUploadingGalleryImage.value = false;
      Get.snackbar('Gallery Upload Failed', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void removeGalleryImage(int index) {
    if (index >= 0 && index < galleryImages.length) {
      galleryImages.removeAt(index);
    }
  }

  // ── Novel PDF Picker & Uploader ──────────────────────────────────────────
  Future<void> pickAndUploadPdf() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (files.isEmpty || files.first.path == null || _isDisposed) return;

      final file = files.first;

      isUploadingPdf.value = true;
      final uploadRes = await _storageService.uploadNovelPdf(
        novelId: _activeNovelId,
        filePath: file.path!,
        originalFileName: file.name,
      );
      if (_isDisposed) return;

      pdfUrl.value = uploadRes['url'];
      pdfStoragePath.value = uploadRes['storagePath'];
      pdfFileName.value = uploadRes['fileName'] ?? file.name;
      isUploadingPdf.value = false;

      Get.snackbar(
        'PDF Uploaded',
        'Complete novel PDF "${pdfFileName.value}" is ready for readers.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      if (_isDisposed) return;
      isUploadingPdf.value = false;
      Get.snackbar('PDF Upload Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void removePdf() {
    pdfUrl.value = null;
    pdfStoragePath.value = null;
    pdfFileName.value = null;
  }

  // ── Save / Publish Novel Flow ────────────────────────────────────────────
  Future<void> saveNovel({required bool publishImmediately}) async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar('Validation Error', 'Please enter a title for your novel.');
      return;
    }

    try {
      isSaving.value = true;
      final auth = Get.find<AuthController>();
      final user = auth.currentUser.value;

      final novelStatus =
          publishImmediately ? NovelStatus.ongoing : NovelStatus.draft;

      final tags = tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final typedManuscript = manuscriptController.text.trim();
      final hasManuscript = typedManuscript.isNotEmpty;
      final hasPdf = pdfUrl.value != null && pdfUrl.value!.isNotEmpty;
      final hasGallery = galleryImages.isNotEmpty;

      final initialEpisodeCount = (hasManuscript || hasPdf) ? 1 : 0;

      // Fallback for coverUrl: if user omitted cover artwork, use 1st illustration, or sample preset
      String effectiveCoverUrl = coverUrlController.text.trim();
      if (effectiveCoverUrl.isEmpty && galleryImages.isNotEmpty) {
        effectiveCoverUrl = galleryImages.first;
      }
      if (effectiveCoverUrl.isEmpty) {
        effectiveCoverUrl = sampleCoverPresets.first;
      }

      final novel = NovelEntity(
        id: _activeNovelId,
        writerId: user?.id ?? 'writer_1',
        writerName: user?.displayName ?? 'Julian Vance',
        writerAvatarUrl: user?.photoUrl,
        title: titleController.text.trim(),
        titleLowercase: titleController.text.trim().toLowerCase(),
        description: descriptionController.text.trim(),
        coverUrl: effectiveCoverUrl,
        coverStoragePath: coverStoragePath,
        genreIds: selectedGenres.toList(),
        tags: tags,
        status: novelStatus,
        isDownloadEnabled: isDownloadEnabled.value,
        galleryImageUrls: galleryImages.toList(),
        pdfUrl: pdfUrl.value,
        pdfStoragePath: pdfStoragePath.value,
        pdfFileName: pdfFileName.value,
        manuscriptContent: hasManuscript ? typedManuscript : null,
        publishedEpisodeCount: initialEpisodeCount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        publishedAt: publishImmediately ? DateTime.now() : null,
      );

      if (existingNovelId != null && existingNovelId!.isNotEmpty) {
        await _novelUseCases.updateNovel(novel);
      } else {
        await _novelUseCases.createNovel(novel);
      }
      if (_isDisposed) return;

      // ── Seamless Reader / Episode Creation ───────────────────────────────
      // If author typed a manuscript or uploaded a PDF or added gallery images,
      // ensure Chapter 1 exists so reader can immediately start reading!
      if (hasManuscript || hasPdf || hasGallery) {
        await _syncInitialChapter(
          novel: novel,
          publishImmediately: publishImmediately,
          hasManuscript: hasManuscript,
          manuscriptText: typedManuscript,
          hasPdf: hasPdf,
          hasGallery: hasGallery,
        );
      }
      if (_isDisposed) return;

      // Refresh writer dashboard if active
      if (Get.isRegistered<WriterDashboardController>()) {
        Get.find<WriterDashboardController>().loadDashboard();
      }

      // Refresh admin dashboard if active
      if (Get.isRegistered<AdminDashboardController>()) {
        Get.find<AdminDashboardController>().loadDashboard();
      }

      isSaving.value = false;

      // Delete this tagged controller so the next open gets a clean instance
      final tag = existingNovelId ?? '__new_novel__';
      Get.back();
      Future.microtask(() {
        if (Get.isRegistered<NovelEditorController>(tag: tag)) {
          Get.delete<NovelEditorController>(tag: tag, force: true);
        }
      });

      Get.snackbar(
        publishImmediately ? 'Novel Published' : 'Draft Saved',
        publishImmediately
            ? 'Your novel "${novel.title}" is published and available to readers.'
            : 'Draft saved to your author workspace.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      if (_isDisposed) return;
      isSaving.value = false;
      Get.snackbar('Error', 'Failed to save novel: $e');
      _logger.error('Failed to save novel', e);
    }
  }

  Future<void> _syncInitialChapter({
    required NovelEntity novel,
    required bool publishImmediately,
    required bool hasManuscript,
    required String manuscriptText,
    required bool hasPdf,
    required bool hasGallery,
  }) async {
    try {
      final existingEpisodes = await _episodeUseCases.getEpisodesForNovel(
        novel.id,
        publishedOnly: false,
      );

      final blocks = <ContentBlockEntity>[];
      int blockOrder = 1;

      // 1. Add gallery illustrations as image blocks
      if (hasGallery) {
        for (int i = 0; i < galleryImages.length; i++) {
          blocks.add(
            ContentBlockEntity(
              id: const Uuid().v4(),
              episodeId: '',
              type: ContentBlockType.image,
              order: blockOrder++,
              url: galleryImages[i],
              caption: 'Illustration ${i + 1}',
            ),
          );
        }
      }

      // 2. Add full typed manuscript text block
      if (hasManuscript) {
        blocks.add(
          ContentBlockEntity(
            id: const Uuid().v4(),
            episodeId: '',
            type: ContentBlockType.text,
            order: blockOrder++,
            content: manuscriptText,
          ),
        );
      }

      // 3. Add PDF block if provided
      if (hasPdf) {
        blocks.add(
          ContentBlockEntity(
            id: const Uuid().v4(),
            episodeId: '',
            type: ContentBlockType.pdf,
            order: blockOrder++,
            url: pdfUrl.value,
            storagePath: pdfStoragePath.value,
            fileName: pdfFileName.value ?? '${novel.title}.pdf',
          ),
        );
      }

      final chapterStatus =
          publishImmediately ? EpisodeStatus.published : EpisodeStatus.draft;

      if (existingEpisodes.isEmpty) {
        final epId = const Uuid().v4();
        final ep = EpisodeEntity(
          id: epId,
          novelId: novel.id,
          writerId: novel.writerId,
          episodeNumber: 1,
          title: hasPdf && !hasManuscript
              ? 'Complete Novel (PDF Edition)'
              : 'Complete Novel: ${novel.title}',
          titleLowercase:
              'complete novel: ${novel.title.toLowerCase()}',
          summary: novel.description,
          content: manuscriptText,
          blocks: blocks
              .map((b) => b.copyWith(episodeId: epId))
              .toList(),
          wordCount: manuscriptWordCount.value,
          status: chapterStatus,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          publishedAt: publishImmediately ? DateTime.now() : null,
        );
        await _episodeUseCases.createEpisode(ep);
      } else {
        // Update first episode with latest manuscript/PDF/gallery
        final first = existingEpisodes.first;
        final updated = first.copyWith(
          title: hasPdf && !hasManuscript
              ? 'Complete Novel (PDF Edition)'
              : 'Complete Novel: ${novel.title}',
          content: manuscriptText,
          blocks: blocks
              .map((b) => b.copyWith(episodeId: first.id))
              .toList(),
          wordCount: manuscriptWordCount.value,
          status: chapterStatus,
          updatedAt: DateTime.now(),
          publishedAt: publishImmediately ? DateTime.now() : first.publishedAt,
        );
        await _episodeUseCases.updateEpisode(updated);
      }
    } catch (e) {
      _logger.error('Failed to sync initial chapter from novel editor', e);
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    titleController.dispose();
    descriptionController.dispose();
    coverUrlController.dispose();
    tagsController.dispose();
    manuscriptController.dispose();
    super.onClose();
  }
}
