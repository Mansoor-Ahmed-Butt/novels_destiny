import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/responsive/breakpoints.dart';
import '../controllers/novel_details_controller.dart';
import '../states/novel_details_state.dart';
import '../views/novel_hero_section.dart';
import '../views/novel_metadata_section.dart';
import '../views/episode_list_section.dart';
import '../widgets/novel_action_bar.dart';

class NovelDetailsPage extends StatelessWidget {
  const NovelDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Read the tag here, inside build, so Get.parameters is populated
    final novelId = Get.parameters['id'] ?? '';
    final ctrl = Get.find<NovelDetailsController>(tag: novelId);

    return AppScaffold(
      body: Obx(() {
        final state = ctrl.state.value;
        return switch (state) {
          NovelDetailsLoading() => const AppLoadingState(message: 'Opening story volume...'),
          NovelDetailsFailure(:final message) => AppErrorState(
              message: message,
              onRetry: ctrl.load,
            ),
          NovelDetailsReady(
            :final novel,
            :final episodes,
            :final isLiked,
            :final isSaved,
            :final readingProgress
          ) =>
            Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.l,
                    right: AppSpacing.l,
                    top: AppSpacing.l,
                    bottom: 100,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxCardGridWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppPageHeader(
                            title: novel.title,
                            subtitle: 'Story Details & Chapters',
                            onBack: () => Get.back(),
                          ),
                          NovelHeroSection(novel: novel),
                          const SizedBox(height: AppSpacing.xl),
                          NovelMetadataSection(novel: novel),
                          const SizedBox(height: AppSpacing.xl),
                          EpisodeListSection(
                            episodes: episodes,
                            onEpisodeTap: ctrl.openEpisode,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: NovelActionBar(
                    isLiked: isLiked,
                    isSaved: isSaved,
                    isDownloadEligible: novel.isDownloadEnabled,
                    hasStartedReading: readingProgress != null,
                    onRead: ctrl.startReading,
                    onToggleLike: ctrl.toggleLike,
                    onToggleSave: ctrl.toggleSave,
                    onDownload: novel.isDownloadEnabled ? ctrl.downloadFullNovel : null,
                    onReport: () => _showReportDialog(context, ctrl),
                  ),
                ),
              ],
            ),
        };
      }),
    );
  }

  void _showReportDialog(BuildContext context, NovelDetailsController ctrl) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
        title: Text('Report Story', style: AppTextStyles.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please describe why you are reporting this novel for review:',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              controller: reasonController,
              hint: 'Reason for report (e.g. copyright, inappropriate content)...',
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTextStyles.labelMedium),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (reasonController.text.trim().isNotEmpty) {
                ctrl.submitReport(reasonController.text.trim());
              }
            },
            child: Text('Submit Report', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
