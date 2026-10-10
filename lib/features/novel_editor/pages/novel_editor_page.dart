import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/widgets/app_adaptive_image.dart';
import '../controllers/novel_editor_controller.dart';

class NovelEditorPage extends StatefulWidget {
  const NovelEditorPage({super.key});

  @override
  State<NovelEditorPage> createState() => _NovelEditorPageState();
}

class _NovelEditorPageState extends State<NovelEditorPage> {
  late final NovelEditorController _ctrl;
  late final String _tag;
  bool _isNavigatingBack = false;

  @override
  void initState() {
    super.initState();
    final novelId = Get.parameters['id'];
    _tag = novelId ?? '__new_novel__';
    _ctrl = Get.find<NovelEditorController>(tag: _tag);
  }

  void _onBack() {
    FocusScope.of(context).unfocus();
    if (_isNavigatingBack) return;
    if (_ctrl.hasUnsavedChanges.value) {
      AppConfirmDialog.show(
        context: context,
        title: 'Unsaved Changes',
        message: 'Do you want to discard unsaved novel changes?',
        confirmLabel: 'Discard',
        isDestructive: true,
        onConfirm: _navigateBack,
      );
    } else {
      _navigateBack();
    }
  }

  void _navigateBack() {
    if (_isNavigatingBack) return;
    _isNavigatingBack = true;
    FocusScope.of(context).unfocus();

    Get.back();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<NovelEditorController>(tag: _tag)) {
        Get.delete<NovelEditorController>(tag: _tag, force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => PopScope(
          canPop: !_ctrl.hasUnsavedChanges.value && !_isNavigatingBack,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (_isNavigatingBack) return;
            if (_ctrl.hasUnsavedChanges.value) {
              await AppConfirmDialog.show(
                context: context,
                title: 'Unsaved Novel Changes',
                message: 'You have unsaved changes. Exit without saving?',
                confirmLabel: 'Discard Changes',
                isDestructive: true,
                onConfirm: _navigateBack,
              );
            } else {
              _navigateBack();
            }
          },
          child: AppScaffold(
            body: Obx(() {
              if (_ctrl.isLoading.value) {
                return const AppLoadingState(message: 'Loading story details...');
              }
              return _buildForm();
            }),
          ),
        ));
  }

  Widget _buildForm() {
    final isEditing = _ctrl.existingNovelId != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxFormWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppPageHeader(
                title: isEditing ? 'Edit Novel' : 'Create Novel Draft',
                subtitle:
                    'Set up your title, manuscript, illustrations, and digital PDF book',
                onBack: _onBack,
              ),

              // ── 1. Story Basics ──────────────────────────────────────────
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Story Information',
                      style: AppTextStyles.titleMedium
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Title
                    AppTextField(
                      label: 'Novel Title',
                      hint: 'e.g. The Whispering Archive',
                      controller: _ctrl.titleController,
                    ),
                    const SizedBox(height: AppSpacing.l),

                    // Synopsis / Blurb
                    AppTextField(
                      label: 'Synopsis / Blurb',
                      hint:
                          'A captivating summary that hooks readers on the explore page...',
                      controller: _ctrl.descriptionController,
                      maxLines: 4,
                    ),
                    const SizedBox(height: AppSpacing.l),

                    // Primary Genres
                    Text('Primary Genres', style: AppTextStyles.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Obx(
                      () => Wrap(
                        spacing: AppSpacing.s,
                        runSpacing: AppSpacing.s,
                        children: _ctrl.availableGenres.map((g) {
                          final isSelected = _ctrl.selectedGenres.contains(g);
                          return InkWell(
                            onTap: () => _ctrl.toggleGenre(g),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.pill,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.cardBorder,
                                ),
                              ),
                              child: Text(
                                g,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isSelected
                                      ? AppColors.textInverse
                                      : AppColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),

                    // Tags
                    AppTextField(
                      label: 'Tags (comma separated)',
                      hint: 'magic, academy, dark fantasy, dragons',
                      controller: _ctrl.tagsController,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.l),

              // ── 2. Cover Artwork (Book Cover) ────────────────────────────
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cover Artwork (Book Cover)',
                                style: AppTextStyles.titleMedium
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Main cover image shown in library & reader cards. (Optional: if left empty, your 1st illustration will be used as the cover).',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Obx(
                          () => OutlinedButton.icon(
                            onPressed: _ctrl.isUploadingCover.value
                                ? null
                                : _ctrl.pickAndUploadCover,
                            icon: _ctrl.isUploadingCover.value
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 16,
                                  ),
                            label: Text(
                              _ctrl.isUploadingCover.value
                                  ? 'Uploading...'
                                  : 'Upload Cover',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s),
                    AppTextField(
                      label: 'Cover Image URL / Path (Optional)',
                      hint: 'https://... or upload with button above',
                      controller: _ctrl.coverUrlController,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Or pick a curated artwork preset:',
                      style: AppTextStyles.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: _ctrl.sampleCoverPresets.map((url) {
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.s),
                          child: InkWell(
                            onTap: () => _ctrl.setCoverPreset(url),
                            borderRadius: BorderRadius.circular(AppRadii.s),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadii.s),
                              child: Image.network(
                                url,
                                width: 48,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 48,
                                  height: 64,
                                  color: AppColors.surface,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.l),

              // ── 3. Novel Illustrations & Image Gallery (1 to 5 Images) ────
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Novel Illustrations & Gallery',
                                style: AppTextStyles.titleMedium
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Add 1 to 5 illustrations, character artwork, or maps',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Obx(
                          () => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _ctrl.galleryImages.length >= 5
                                  ? AppColors.warningLight
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                              border: Border.all(
                                color: _ctrl.galleryImages.length >= 5
                                    ? AppColors.warning
                                    : AppColors.cardBorder,
                              ),
                            ),
                            child: Text(
                              '${_ctrl.galleryImages.length} / 5 Images',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: _ctrl.galleryImages.length >= 5
                                    ? AppColors.warning
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Gallery images strip / list
                    Obx(() {
                      final images = _ctrl.galleryImages;
                      final isUploading = _ctrl.isUploadingGalleryImage.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (images.isNotEmpty)
                            SizedBox(
                              height: 120,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: images.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: AppSpacing.m),
                                itemBuilder: (context, index) {
                                  final imgUrl = images[index];
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 90,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.m,
                                          ),
                                          border: Border.all(
                                            color: AppColors.cardBorder,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.m,
                                          ),
                                          child: _buildImageThumbnail(imgUrl),
                                        ),
                                      ),
                                      // Image index badge
                                      Positioned(
                                        top: 6,
                                        left: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withValues(alpha: 0.7),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '#${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Remove button
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: InkWell(
                                          onTap: () =>
                                              _ctrl.removeGalleryImage(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: AppColors.error,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close_rounded,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.l,
                                horizontal: AppSpacing.m,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.m),
                                border: Border.all(
                                  color: AppColors.cardBorder,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.collections_outlined,
                                    size: 32,
                                    color: AppColors.textTertiary,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'No illustrations added yet',
                                    style: AppTextStyles.labelMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Attach up to 5 visual artworks to immerse readers in your world.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: AppSpacing.m),

                          // Add Image button
                          OutlinedButton.icon(
                            onPressed: (images.length >= 5 || isUploading)
                                ? null
                                : _ctrl.pickAndAddGalleryImage,
                            icon: isUploading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 18,
                                  ),
                            label: Text(
                              isUploading
                                  ? 'Uploading Image...'
                                  : (images.length >= 5
                                      ? 'Maximum 5 Images Reached'
                                      : 'Add Illustration (${images.length}/5)'),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.l),

              // ── 4. Novel Manuscript / Content (Type or Upload PDF) ────────
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Novel Story Content',
                      style: AppTextStyles.titleMedium
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Type your complete novel manuscript or upload a full digital PDF book for readers.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Content Mode Switcher
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.m),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildModeTab(
                                index: 0,
                                label: 'Type Complete Novel',
                                icon: Icons.edit_note_rounded,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildModeTab(
                                index: 1,
                                label: 'Upload Novel PDF',
                                icon: Icons.picture_as_pdf_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),

                    // Mode 0: Type Complete Novel Prose
                    Obx(() {
                      if (_ctrl.selectedContentMode.value != 0) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            label: 'Full Novel Manuscript',
                            hint:
                                'Type or paste your complete story here...\n\nReaders will enjoy seamless reading with customizable fonts, font sizes, line height, and dark/light themes.',
                            controller: _ctrl.manuscriptController,
                            maxLines: 12,
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Prose Editor',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              Text(
                                '${_ctrl.manuscriptWordCount.value} words • ${_ctrl.manuscriptCharCount.value} characters',
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),

                    // Mode 1: Upload Novel PDF Document
                    Obx(() {
                      if (_ctrl.selectedContentMode.value != 1) {
                        return const SizedBox.shrink();
                      }
                      final pdf = _ctrl.pdfUrl.value;
                      final isUploading = _ctrl.isUploadingPdf.value;

                      if (pdf != null && pdf.isNotEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.l),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadii.m),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorLight,
                                      borderRadius:
                                          BorderRadius.circular(AppRadii.s),
                                    ),
                                    child: const Icon(
                                      Icons.picture_as_pdf_rounded,
                                      color: AppColors.error,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.m),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _ctrl.pdfFileName.value ??
                                              'Complete Novel.pdf',
                                          style: AppTextStyles.labelLarge
                                              .copyWith(
                                                  fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              size: 14,
                                              color: AppColors.success,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Ready for readers via Syncfusion PDF Viewer',
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                color: AppColors.success,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.m),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: isUploading
                                        ? null
                                        : _ctrl.pickAndUploadPdf,
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 16),
                                    label: const Text('Replace PDF'),
                                  ),
                                  const SizedBox(width: AppSpacing.m),
                                  TextButton.icon(
                                    onPressed: _ctrl.removePdf,
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                      color: AppColors.error,
                                    ),
                                    label: Text(
                                      'Remove',
                                      style: AppTextStyles.labelMedium
                                          .copyWith(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.m),
                          border: Border.all(
                            color: AppColors.cardBorder,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.upload_file_rounded,
                                size: 36,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.m),
                            Text(
                              'Attach Complete Novel PDF',
                              style: AppTextStyles.titleSmall
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload your formatted book PDF (up to 50MB).\nReaders can view the complete book directly inside the app.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.l),
                            AppPrimaryButton(
                              label: isUploading
                                  ? 'Uploading PDF...'
                                  : 'Select & Upload PDF Document',
                              icon: Icons.upload_rounded,
                              isLoading: isUploading,
                              onPressed:
                                  isUploading ? null : _ctrl.pickAndUploadPdf,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.l),

              // ── 5. Offline Download Toggle ───────────────────────────────
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Obx(
                  () => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Enable Full Offline EPUB/PDF Downloads',
                      style: AppTextStyles.labelLarge,
                    ),
                    subtitle: Text(
                      'Allows authorized readers to download complete novel once finished.',
                      style: AppTextStyles.bodySmall,
                    ),
                    value: _ctrl.isDownloadEnabled.value,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => _ctrl.isDownloadEnabled.value = val,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── 6. Action Buttons ────────────────────────────────────────
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: 'Save Draft',
                        onPressed: _ctrl.isSaving.value
                            ? null
                            : () => _ctrl.saveNovel(publishImmediately: false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: AppPrimaryButton(
                        label: isEditing ? 'Update Novel' : 'Publish Story',
                        isLoading: _ctrl.isSaving.value,
                        onPressed: _ctrl.isSaving.value
                            ? null
                            : () => _ctrl.saveNovel(publishImmediately: true),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _ctrl.selectedContentMode.value == index;
    return InkWell(
      onTap: () => _ctrl.selectedContentMode.value = index,
      borderRadius: BorderRadius.circular(AppRadii.s),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.s),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  isSelected ? AppColors.textInverse : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected
                      ? AppColors.textInverse
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(String imgUrl) {
    return AppAdaptiveImage(
      url: imgUrl,
      fit: BoxFit.cover,
    );
  }
}
