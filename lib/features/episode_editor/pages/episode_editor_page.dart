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
import '../../../domain/entities/content_block_entity.dart';

class EpisodeEditorPage extends StatefulWidget {
  const EpisodeEditorPage({super.key});

  @override
  State<EpisodeEditorPage> createState() => _EpisodeEditorPageState();
}

class _EpisodeEditorPageState extends State<EpisodeEditorPage> {
  late final EpisodeEditorController _ctrl;
  late final String _tag;
  bool _isNavigatingBack = false;

  @override
  void initState() {
    super.initState();
    final novelId = Get.parameters['novelId'] ?? '';
    final episodeId = Get.parameters['episodeId'];
    _tag = '$novelId-${episodeId ?? "__new__"}';
    _ctrl = Get.find<EpisodeEditorController>(tag: _tag);
  }

  void _onBack() {
    FocusScope.of(context).unfocus();
    if (_isNavigatingBack) return;
    if (_ctrl.hasUnsavedChanges.value) {
      AppConfirmDialog.show(context: context, title: 'Unsaved Changes', message: 'Do you want to discard unsaved manuscript changes?', confirmLabel: 'Discard', isDestructive: true, onConfirm: _navigateBack);
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
      if (Get.isRegistered<EpisodeEditorController>(tag: _tag)) {
        Get.delete<EpisodeEditorController>(tag: _tag, force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopScope(
        canPop: !_ctrl.hasUnsavedChanges.value && !_isNavigatingBack,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (_isNavigatingBack) return;
          if (_ctrl.hasUnsavedChanges.value) {
            await AppConfirmDialog.show(context: context, title: 'Unsaved Manuscript Changes', message: 'You have unsaved changes. Exit without saving?', confirmLabel: 'Discard Changes', isDestructive: true, onConfirm: _navigateBack);
          } else {
            _navigateBack();
          }
        },
        child: AppScaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxReaderWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header (reactive word count only) ──────────────
                    Obx(
                      () => AppPageHeader(
                        title: 'Episode Editor',
                        subtitle: 'Draft and publish story chapters with live word count',
                        onBack: _onBack,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(
                            '${_ctrl.wordCount.value} Words',
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),

                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Chapter meta (static TextFields) ──────────
                          Row(
                            children: [
                              SizedBox(
                                width: 90,
                                child: AppTextField(label: 'Chapter #', hint: '1', controller: _ctrl.numberController, keyboardType: TextInputType.number),
                              ),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(
                                child: AppTextField(label: 'Chapter Title', hint: 'e.g. The Awakening of the Starlight Core', controller: _ctrl.titleController),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.m),

                          AppTextField(label: 'Chapter Teaser / Summary (Optional)', hint: 'A quick summary of key events for this chapter...', controller: _ctrl.summaryController, maxLines: 2),
                          const SizedBox(height: AppSpacing.l),

                          // ── Manuscript text area (static) ──────────────
                          Text('Manuscript Prose', style: AppTextStyles.labelLarge),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadii.m),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: TextField(
                              controller: _ctrl.contentController,
                              maxLines: 18,
                              style: GoogleFonts.merriweather(fontSize: 16, height: 1.7, color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Begin typing your story here...',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(AppSpacing.l),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // ── Content Blocks header (reactive upload state)
                          Obx(
                            () => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Ordered Content Blocks', style: AppTextStyles.labelLarge),
                                    Text('Attach chapter images, PDF files, or inline ads', style: AppTextStyles.bodySmall),
                                  ],
                                ),
                                if (_ctrl.isUploadingMedia.value) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),

                          // ── Block insertion buttons (reactive) ─────────
                          Obx(
                            () => Wrap(
                              spacing: AppSpacing.s,
                              runSpacing: AppSpacing.s,
                              children: [
                                OutlinedButton.icon(onPressed: _ctrl.isUploadingMedia.value ? null : _ctrl.pickAndAddImage, icon: const Icon(Icons.add_photo_alternate_outlined, size: 18), label: const Text('Add Image')),
                                OutlinedButton.icon(onPressed: _ctrl.isUploadingMedia.value ? null : _ctrl.pickAndAddPdf, icon: const Icon(Icons.picture_as_pdf_outlined, size: 18), label: const Text('Add PDF')),
                                OutlinedButton.icon(onPressed: _ctrl.addAdBlock, icon: const Icon(Icons.ad_units_outlined, size: 18), label: const Text('Add Ad Placement')),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),

                          // ── Reorderable block list (reactive) ──────────
                          Obx(() {
                            if (_ctrl.blocks.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _ctrl.blocks.length,
                              onReorderItem: (oldIndex, newIndex) => _ctrl.reorderBlocks(oldIndex, newIndex),
                              itemBuilder: (context, index) {
                                final block = _ctrl.blocks[index];
                                return Container(
                                  key: ValueKey(block.id),
                                  margin: const EdgeInsets.only(bottom: AppSpacing.s),
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(AppRadii.s),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        block.type == ContentBlockType.image
                                            ? Icons.image_rounded
                                            : block.type == ContentBlockType.pdf
                                            ? Icons.picture_as_pdf_rounded
                                            : block.type == ContentBlockType.ad
                                            ? Icons.ad_units_rounded
                                            : Icons.text_snippet_rounded,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: AppSpacing.m),
                                      Expanded(
                                        child: Text(
                                          block.type == ContentBlockType.image
                                              ? 'Image: ${block.caption ?? "Episode Image"}'
                                              : block.type == ContentBlockType.pdf
                                              ? 'PDF: ${block.fileName ?? "Episode Document"}'
                                              : block.type == ContentBlockType.ad
                                              ? 'AdMob Placement (inline)'
                                              : 'Text Paragraph',
                                          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                                        onPressed: () => _ctrl.removeBlock(index),
                                      ),
                                      const Icon(Icons.drag_handle_rounded, size: 20, color: AppColors.textTertiary),
                                    ],
                                  ),
                                );
                              },
                            );
                          }),
                          const SizedBox(height: AppSpacing.xl),

                          // ── Save / Publish buttons (reactive loading) ──
                          Obx(
                            () => Row(
                              children: [
                                Expanded(
                                  child: AppSecondaryButton(label: 'Save Draft', icon: Icons.save_outlined, onPressed: () => _ctrl.saveEpisode(publishImmediately: false)),
                                ),
                                const SizedBox(width: AppSpacing.m),
                                Expanded(
                                  child: AppPrimaryButton(label: 'Publish Episode', icon: Icons.send_rounded, isLoading: _ctrl.isSaving.value, onPressed: () => _ctrl.saveEpisode(publishImmediately: true)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
