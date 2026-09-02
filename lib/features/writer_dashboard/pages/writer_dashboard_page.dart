import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/novel_cover.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/responsive/breakpoints.dart';
import '../controllers/writer_dashboard_controller.dart';
import '../widgets/writer_chart_view.dart';

class WriterDashboardPage extends GetView<WriterDashboardController> {
  const WriterDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingState(message: 'Opening author workspace...');
        }

        final stats = controller.analytics.value;

        return RefreshIndicator(
          onRefresh: controller.loadDashboard,
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
                    // Header with Quick Action Buttons
                    AppPageHeader(
                      title: 'Author Studio',
                      subtitle: 'Manage your stories, episodes, and reader engagement',
                      badgeText: 'WRITER',
                      trailing: Row(
                        children: [
                          AppPrimaryButton(
                            label: 'New Novel',
                            icon: Icons.add_rounded,
                            onPressed: controller.createNewNovel,
                          ),
                        ],
                      ),
                    ),

                    // Top Summary Card (Inspired by reference screenshot)
                    SummaryHeroCard(
                      mainLabel: 'Total Platform Reads',
                      mainValue: _formatNumber(stats?.totalReads ?? 0),
                      unit: 'all-time',
                      subMetrics: [
                        SummarySubMetric(label: 'Novels', value: '${stats?.totalNovels ?? 0}'),
                        SummarySubMetric(label: 'Episodes', value: '${stats?.publishedEpisodes ?? 0}'),
                        SummarySubMetric(label: 'Total Likes', value: _formatNumber(stats?.totalLikes ?? 0)),
                        SummarySubMetric(label: 'Downloads', value: _formatNumber(stats?.totalDownloads ?? 0)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Analytics Chart
                    if (stats != null && stats.dailyReadsTrend.isNotEmpty) ...[
                      WriterChartView(dataPoints: stats.dailyReadsTrend),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // My Novels List / Table
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Published Works (${controller.myNovels.length})',
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),

                    if (controller.myNovels.isEmpty)
                      AppEmptyState(
                        title: 'No novels created yet',
                        message: 'Start your author journey by drafting your first manuscript.',
                        actionLabel: 'Create Novel Draft',
                        onAction: controller.createNewNovel,
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.myNovels.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.m),
                        itemBuilder: (context, index) {
                          final novel = controller.myNovels[index];
                          return AppCard(
                            padding: const EdgeInsets.all(AppSpacing.l),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                NovelCover(
                                  url: novel.coverUrl,
                                  title: novel.title,
                                  width: 60,
                                  height: 85,
                                ),
                                const SizedBox(width: AppSpacing.m),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              novel.title,
                                              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          AppStatusChip.novelStatus(novel.status),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${novel.publishedEpisodeCount} Episodes • ${novel.totalViews} Reads • ${novel.totalLikes} Likes',
                                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.m),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppSecondaryButton(
                                      label: '+ Episode',
                                      icon: Icons.add_rounded,
                                      onPressed: () => controller.createEpisode(novel),
                                    ),
                                    const SizedBox(width: AppSpacing.s),
                                    AppIconButton(
                                      icon: Icons.edit_outlined,
                                      tooltip: 'Edit Story Details',
                                      onPressed: () => controller.editNovel(novel),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    AppIconButton(
                                      icon: Icons.visibility_outlined,
                                      tooltip: 'View as Reader',
                                      onPressed: () => controller.viewNovel(novel),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}
