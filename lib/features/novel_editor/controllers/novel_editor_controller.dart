import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../domain/entities/novel_entity.dart';
import '../../../domain/usecases/novel_usecases.dart';
import '../../../core/services/logger_service.dart';
import '../../auth/controllers/auth_controller.dart';

class NovelEditorController extends GetxController {
  final String? existingNovelId;
  final NovelUseCases _novelUseCases;
  final ILoggerService _logger;

  NovelEditorController(this.existingNovelId, this._novelUseCases, this._logger);

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final Rx<NovelStatus> status = NovelStatus.ongoing.obs;
  final RxBool isDownloadEnabled = false.obs;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController coverUrlController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();

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
    if (existingNovelId != null && existingNovelId!.isNotEmpty) {
      loadExistingNovel(existingNovelId!);
    } else {
      coverUrlController.text = sampleCoverPresets.first;
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
        tagsController.text = novel.tags.join(', ');
        selectedGenres.assignAll(novel.genreIds);
        status.value = novel.status;
        isDownloadEnabled.value = novel.isDownloadEnabled;
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
  }

  Future<void> saveNovel({required bool publishImmediately}) async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar('Validation Error', 'Please enter a title for your novel.');
      return;
    }

    try {
      isSaving.value = true;
      final auth = Get.find<AuthController>();
      final user = auth.currentUser.value;

      final novelStatus = publishImmediately ? NovelStatus.ongoing : NovelStatus.draft;

      final novel = NovelEntity(
        id: existingNovelId ?? '',
        writerId: user?.id ?? 'writer_1',
        writerName: user?.displayName ?? 'Julian Vance',
        writerAvatarUrl: user?.photoUrl,
        title: titleController.text.trim(),
        titleLowercase: titleController.text.trim().toLowerCase(),
        description: descriptionController.text.trim(),
        coverUrl: coverUrlController.text.trim().isEmpty ? sampleCoverPresets.first : coverUrlController.text.trim(),
        genreIds: selectedGenres.toList(),
        tags: tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
        status: novelStatus,
        isDownloadEnabled: isDownloadEnabled.value,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (existingNovelId != null && existingNovelId!.isNotEmpty) {
        await _novelUseCases.updateNovel(novel);
        Get.back();
        Get.snackbar('Saved', 'Novel updated successfully.');
      } else {
        await _novelUseCases.createNovel(novel);
        Get.back();
        Get.snackbar('Created', 'Novel drafted successfully!');
      }

      isSaving.value = false;
    } catch (e) {
      isSaving.value = false;
      Get.snackbar('Error', 'Failed to save novel: $e');
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    coverUrlController.dispose();
    tagsController.dispose();
    super.onClose();
  }
}
