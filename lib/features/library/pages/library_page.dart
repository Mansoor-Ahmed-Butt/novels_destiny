import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/novel_card.dart';
import '../../../core/responsive/breakpoints.dart';
import '../controllers/library_controller.dart';

class LibraryPage extends GetView<LibraryController> {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingState(message: 'Retrieving your shelf...');
        }

        return RefreshIndicator(
          onRefresh: controller.loadLibrary,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxCardGridWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppPageHeader(
                      title: 'My Library',
                      subtitle: 'Bookmarks, reading history & offline shelf',
                    ),

                    // Tab Selector
                    Row(
                      children: [
                        _buildTab('Saved (${controller.savedNovels.length})', 0),
                        const SizedBox(width: AppSpacing.s),
                        _buildTab('History (${controller.history.length})', 1),
                        const SizedBox(width: AppSpacing.s),
                        _buildTab('Offline Shelf (${controller.downloadedNovels.length})', 2),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Tab Content
                    if (controller.selectedTabIndex.value == 0)
                      _buildSavedTab(context)
                    else if (controller.selectedTabIndex.value == 1)
                      _buildHistoryTab(context)
                    else
                      _buildDownloadsTab(context),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = controller.selectedTabIndex.value == index;
    return InkWell(
      onTap: () => controller.selectedTabIndex.value = index,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.textInverse : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSavedTab(BuildContext context) {
    final list = controller.savedNovels;
    if (list.isEmpty) {
      return const AppEmptyState(
        title: 'No saved stories yet',
        message: 'Tap the bookmark icon on any novel to save it to your library.',
        icon: Icons.bookmark_border_rounded,
      );
    }

    final isCompact = AppBreakpoints.isCompact(context);
    final crossAxisCount = isCompact ? 2 : (AppBreakpoints.isMedium(context) ? 3 : 4);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.68,
        crossAxisSpacing: AppSpacing.m,
        mainAxisSpacing: AppSpacing.m,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final novel = list[index];
        return NovelCard(
          novel: novel,
          onTap: () => controller.openNovel(novel),
        );
      },
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    final history = controller.history;
    if (history.isEmpty) {
      return const AppEmptyState(
        title: 'No reading history',
        message: 'Start reading chapters from Discover to track your progress automatically.',
        icon: Icons.history_rounded,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.m),
      itemBuilder: (context, index) {
        final prog = history[index];
        final novel = controller.historyNovelMap[prog.novelId];
        if (novel == null) return const SizedBox.shrink();

        return NovelCard(
          novel: novel,
          variant: NovelCardVariant.list,
          readingProgress: prog.progressPercent,
          onTap: () => controller.resumeEpisode(prog),
        );
      },
    );
  }

  Widget _buildDownloadsTab(BuildContext context) {
    final downloads = controller.downloadedNovels;
    if (downloads.isEmpty) {
      return const AppEmptyState(
        title: 'No offline stories downloaded',
        message: 'Completed novels eligible for offline reading can be downloaded from their details page.',
        icon: Icons.download_outlined,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: downloads.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.m),
      itemBuilder: (context, index) {
        final novel = downloads[index];
        return NovelCard(
          novel: novel,
          variant: NovelCardVariant.list,
          onTap: () => controller.openNovel(novel),
        );
      },
    );
  }
}
