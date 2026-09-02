import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/responsive/breakpoints.dart';
import '../controllers/episode_editor_controller.dart';

class EpisodeEditorPage extends StatelessWidget {
  const EpisodeEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final novelId = Get.parameters['novelId'] ?? '';
    final episodeId = Get.parameters['episodeId'];
    final ctrl = Get.find<EpisodeEditorController>(
      tag: '$novelId-${episodeId ?? "__new__"}',
    );

    return PopScope(
      canPop: !ctrl.hasUnsavedChanges.value,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await AppConfirmDialog.show(
          context: context,
          title: 'Unsaved Manuscript Changes',
          message:
              'You have unsaved changes in this episode. Are you sure you want to exit without saving?',
          confirmLabel: 'Discard Changes',
          isDestructive: true,
          onConfirm: () => Get.back(),
        );
      },
      child: AppScaffold(
        body: Obx(() {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxReaderWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppPageHeader(
                      title: 'Episode Editor',
                      subtitle: 'Draft and publish story chapters with live word count',
                      onBack: () {
                        if (ctrl.hasUnsavedChanges.value) {
                          AppConfirmDialog.show(
                            context: context,
                            title: 'Unsaved Changes',
                            message:
                                'Do you want to discard unsaved manuscript changes?',
                            confirmLabel: 'Discard',
                            isDestructive: true,
                            onConfirm: () => Get.back(),
                          );
                        } else {
                          Get.back();
                        }
                      },
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          '${ctrl.wordCount.value} Words',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 90,
                                child: AppTextField(
                                  label: 'Chapter #',
                                  hint: '1',
                                  controller: ctrl.numberController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(
                                child: AppTextField(
                                  label: 'Chapter Title',
                                  hint: 'e.g. The Awakening of the Starlight Core',
                                  controller: ctrl.titleController,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.m),

                          AppTextField(
                            label: 'Chapter Teaser / Summary (Optional)',
                            hint: 'A quick summary of key events for this chapter...',
                            controller: ctrl.summaryController,
                            maxLines: 2,
                          ),
                          const SizedBox(height: AppSpacing.l),

                          Text('Manuscript Prose', style: AppTextStyles.labelLarge),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadii.m),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: TextField(
                              controller: ctrl.contentController,
                              maxLines: 18,
                              style: GoogleFonts.merriweather(
                                fontSize: 16,
                                height: 1.7,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Begin typing your story here...',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(AppSpacing.l),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Publish vs Draft Actions
                          Row(
                            children: [
                              Expanded(
                                child: AppSecondaryButton(
                                  label: 'Save Draft',
                                  icon: Icons.save_outlined,
                                  onPressed: () =>
                                      ctrl.saveEpisode(publishImmediately: false),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(
                                child: AppPrimaryButton(
                                  label: 'Publish Episode',
                                  icon: Icons.send_rounded,
                                  isLoading: ctrl.isSaving.value,
                                  onPressed: () =>
                                      ctrl.saveEpisode(publishImmediately: true),
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
      ),
    );
  }
}
