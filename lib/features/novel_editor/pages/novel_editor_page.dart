import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/responsive/breakpoints.dart';
import '../controllers/novel_editor_controller.dart';

class NovelEditorPage extends StatelessWidget {
  const NovelEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final novelId = Get.parameters['id'];
    final ctrl = Get.find<NovelEditorController>(tag: novelId ?? '__new_novel__');

    return AppScaffold(
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const AppLoadingState(message: 'Loading story details...');
        }

        final isEditing = ctrl.existingNovelId != null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxFormWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageHeader(
                    title: isEditing ? 'Edit Novel' : 'Create Novel Draft',
                    subtitle: 'Set up your title, synopsis, genres, and cover artwork',
                    onBack: () => Get.back(),
                  ),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: 'Novel Title',
                          hint: 'e.g. The Whispering Archive',
                          controller: ctrl.titleController,
                        ),
                        const SizedBox(height: AppSpacing.l),

                        AppTextField(
                          label: 'Synopsis / Blurb',
                          hint:
                              'A captivating synopsis that hooks your prospective readers...',
                          controller: ctrl.descriptionController,
                          maxLines: 4,
                        ),
                        const SizedBox(height: AppSpacing.l),

                        // Genre selector
                        Text('Primary Genres', style: AppTextStyles.labelLarge),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.s,
                          runSpacing: AppSpacing.s,
                          children: ctrl.availableGenres.map((g) {
                            final isSelected = ctrl.selectedGenres.contains(g);
                            return InkWell(
                              onTap: () => ctrl.toggleGenre(g),
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.pill),
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
                        const SizedBox(height: AppSpacing.l),

                        // Tags
                        AppTextField(
                          label: 'Tags',
                          hint:
                              'mystery, slow-burn, victorian, magic (comma separated)',
                          controller: ctrl.tagsController,
                        ),
                        const SizedBox(height: AppSpacing.l),

                        // Cover Artwork & Upload
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Cover Artwork', style: AppTextStyles.labelLarge),
                            OutlinedButton.icon(
                              onPressed: ctrl.isUploadingCover.value ? null : ctrl.pickAndUploadCover,
                              icon: ctrl.isUploadingCover.value
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.cloud_upload_outlined, size: 16),
                              label: Text(ctrl.isUploadingCover.value ? 'Uploading...' : 'Upload File (Supabase)'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppTextField(
                          hint: 'https://...',
                          controller: ctrl.coverUrlController,
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Text('Or pick a curated artwork preset:',
                            style: AppTextStyles.labelSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: ctrl.sampleCoverPresets.map((url) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(right: AppSpacing.s),
                              child: InkWell(
                                onTap: () => ctrl.setCoverPreset(url),
                                borderRadius: BorderRadius.circular(AppRadii.s),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(AppRadii.s),
                                  child: Image.network(url,
                                      width: 48, height: 64, fit: BoxFit.cover),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Offline download toggle
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                              'Enable Full Offline EPUB/PDF Downloads',
                              style: AppTextStyles.labelLarge),
                          subtitle: Text(
                              'Allows authorized readers to download complete novel once finished.',
                              style: AppTextStyles.bodySmall),
                          value: ctrl.isDownloadEnabled.value,
                          activeColor: AppColors.primary,
                          onChanged: (val) =>
                              ctrl.isDownloadEnabled.value = val,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: AppSecondaryButton(
                                label: 'Save Draft',
                                onPressed: () =>
                                    ctrl.saveNovel(publishImmediately: false),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Expanded(
                              child: AppPrimaryButton(
                                label: isEditing
                                    ? 'Update Novel'
                                    : 'Publish Story',
                                isLoading: ctrl.isSaving.value,
                                onPressed: () =>
                                    ctrl.saveNovel(publishImmediately: true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
