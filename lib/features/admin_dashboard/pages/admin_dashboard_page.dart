import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../../../core/widgets/novel_cover.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/responsive/breakpoints.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../widgets/admin_analytics_charts_view.dart';
import '../../../domain/entities/report_entity.dart';
import '../../../domain/entities/novel_entity.dart';
import '../../../domain/entities/episode_entity.dart';
import '../../../app/routes/app_routes.dart';

class AdminDashboardPage extends GetView<AdminDashboardController> {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!controller.isLoading.value && (controller.analytics.value == null || controller.users.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!controller.isLoading.value && (controller.analytics.value == null || controller.users.isEmpty)) {
          controller.loadDashboard();
        }
      });
    }

    return AppScaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingState(message: 'Loading administrator command center...');
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
                    AppPageHeader(
                      title: 'Command Center',
                      subtitle: 'Platform analytics, content moderation, reports, and users',
                      badgeText: 'ADMIN',
                    ),

                    // Key metric cards
                    SummaryHeroCard(
                      mainLabel: 'Global Reader Traffic',
                      mainValue: _formatNumber(stats?.totalReads ?? 0),
                      unit: 'all-time reads',
                      subMetrics: [
                        SummarySubMetric(
                          label: 'Total Users',
                          value: '${(stats?.totalUsers != null && stats!.totalUsers > 0) ? stats.totalUsers : controller.users.length}',
                        ),
                        SummarySubMetric(label: 'Stories', value: '${stats?.totalNovels ?? controller.allNovels.length}'),
                        SummarySubMetric(label: 'Pending Review', value: '${controller.pendingNovels.length}'),
                        SummarySubMetric(label: 'Reports', value: '${controller.reports.where((r) => r.status == ReportStatus.pending).length}'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Intelligence & Ratings Analytics Charts
                    if (stats != null) ...[
                      AdminAnalyticsChartsView(stats: stats),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // Section Tabs: Writer Applications, Moderation Queue, Stories, Reports, Users
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTab('Writer Applications (${controller.pendingWriters.length})', 0),
                          const SizedBox(width: AppSpacing.s),
                          _buildTab('Moderation Queue (${controller.pendingNovels.length})', 1),
                          const SizedBox(width: AppSpacing.s),
                          _buildTab('Stories & Content (${controller.allNovels.length})', 2),
                          const SizedBox(width: AppSpacing.s),
                          _buildTab('User Reports (${controller.reports.length})', 3),
                          const SizedBox(width: AppSpacing.s),
                          _buildTab('All Users (${controller.users.length})', 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),

                    if (controller.selectedTab.value == 0)
                      _buildWriterApplicationsTab()
                    else if (controller.selectedTab.value == 1)
                      _buildModerationTab(context)
                    else if (controller.selectedTab.value == 2)
                      _buildStoriesTab(context)
                    else if (controller.selectedTab.value == 3)
                      _buildReportsTab()
                    else
                      _buildUsersTab(),
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
    final isSelected = controller.selectedTab.value == index;
    return InkWell(
      onTap: () => controller.selectedTab.value = index,
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

  Widget _buildModerationTab(BuildContext context) {
    final pending = controller.pendingNovels;
    if (pending.isEmpty) {
      return const AppEmptyState(
        title: 'Moderation queue is empty',
        message: 'All published novels and submissions have been reviewed and approved.',
        icon: Icons.verified_user_outlined,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pending.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
      itemBuilder: (context, index) {
        final novel = pending[index];
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 600;
              final novelInfo = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NovelCover(url: novel.coverUrl, title: novel.title, width: 64, height: 90),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                novel.title,
                                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s),
                            AppStatusChip.moderationStatus(novel.moderationStatus),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('By ${novel.writerName}', style: AppTextStyles.bodySmall),
                        const SizedBox(height: 4),
                        Text(
                          novel.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    novelInfo,
                    const SizedBox(height: AppSpacing.m),
                    Row(
                      children: [
                        Expanded(
                          child: AppPrimaryButton(
                            label: 'Approve',
                            icon: Icons.check_rounded,
                            backgroundColor: AppColors.success,
                            isExpanded: true,
                            onPressed: () => controller.approveNovel(novel),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          child: AppSecondaryButton(
                            label: 'Reject',
                            icon: Icons.close_rounded,
                            isExpanded: true,
                            onPressed: () => controller.rejectNovel(novel),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        IconButton(
                          icon: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                          tooltip: 'Delete Novel & Supabase Files',
                          onPressed: () => _confirmDeleteNovel(context, novel),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: novelInfo),
                  const SizedBox(width: AppSpacing.m),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        children: [
                          AppPrimaryButton(
                            label: 'Approve',
                            icon: Icons.check_rounded,
                            backgroundColor: AppColors.success,
                            onPressed: () => controller.approveNovel(novel),
                          ),
                          const SizedBox(height: AppSpacing.s),
                          AppSecondaryButton(
                            label: 'Reject',
                            icon: Icons.close_rounded,
                            onPressed: () => controller.rejectNovel(novel),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.s),
                      IconButton(
                        icon: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                        tooltip: 'Delete Novel & Supabase Files',
                        onPressed: () => _confirmDeleteNovel(context, novel),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStoriesTab(BuildContext context) {
    final novels = controller.allNovels;
    if (novels.isEmpty) {
      return const AppEmptyState(
        title: 'No novels on platform',
        message: 'No published or submitted stories found.',
        icon: Icons.auto_stories_outlined,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: novels.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
      itemBuilder: (context, index) {
        final novel = novels[index];
        final hasPdf = (novel.pdfUrl != null && novel.pdfUrl!.isNotEmpty) ||
            (novel.pdfStoragePath != null && novel.pdfStoragePath!.isNotEmpty);

        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NovelCover(url: novel.coverUrl, title: novel.title, width: 68, height: 95),
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            AppStatusChip.moderationStatus(novel.moderationStatus),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('Author: ${novel.writerName}', style: AppTextStyles.bodySmall),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFEAA228)),
                            const SizedBox(width: 2),
                            Text(
                              novel.rating > 0 ? '${novel.rating.toStringAsFixed(1)} ★' : 'Unrated',
                              style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (novel.ratingCount > 0) ...[
                              const SizedBox(width: 2),
                              Text(
                                '(${novel.ratingCount})',
                                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary, fontSize: 10),
                              ),
                            ],
                            const SizedBox(width: AppSpacing.m),
                            Text(
                              '${novel.totalViews} reads',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Text(
                              '${novel.publishedEpisodeCount} chs',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                        if (hasPdf) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight,
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.picture_as_pdf_rounded, size: 12, color: AppColors.error),
                                const SizedBox(width: 4),
                                Text(
                                  'Contains Supabase PDF',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.error,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.s),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                        label: const Text('View Novel'),
                        onPressed: () => Get.toNamed(AppRoutes.novelDetails(novel.id)),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        icon: const Icon(Icons.menu_book_rounded, size: 14),
                        label: Text('Chapters (${novel.publishedEpisodeCount})'),
                        onPressed: () => _showNovelEpisodesSheet(context, novel),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    icon: const Icon(Icons.delete_forever_rounded, size: 16),
                    label: const Text('Delete'),
                    onPressed: () => _confirmDeleteNovel(context, novel),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNovelEpisodesSheet(BuildContext context, NovelEntity novel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return FutureBuilder<List<EpisodeEntity>>(
              future: controller.getEpisodesForNovel(novel.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final episodes = snapshot.data ?? [];

                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.cardBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chapters: ${novel.title}',
                                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${episodes.length} Total Chapters • Manage or delete episodes',
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.m),
                      if (episodes.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text('No episodes created for this novel yet.'),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            controller: scrollController,
                            itemCount: episodes.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
                            itemBuilder: (context, epIdx) {
                              final ep = episodes[epIdx];
                              final hasPdf = ep.blocks.any((b) => (b.storagePath != null && b.storagePath!.isNotEmpty));

                              return Container(
                                padding: const EdgeInsets.all(AppSpacing.m),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(AppRadii.m),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceMuted,
                                        borderRadius: BorderRadius.circular(AppRadii.s),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${ep.episodeNumber}',
                                          style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.m),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ep.title,
                                            style: AppTextStyles.titleSmall.copyWith(fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                '${ep.wordCount} words • ${ep.totalViews} views',
                                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary, fontSize: 11),
                                              ),
                                              if (hasPdf) ...[
                                                const SizedBox(width: 8),
                                                Text(
                                                  '• [PDF attached]',
                                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                      tooltip: 'Delete Episode (Cleans up Supabase PDF)',
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        _confirmDeleteEpisode(context, novel.id, ep);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _confirmDeleteNovel(BuildContext context, NovelEntity novel) {
    AppConfirmDialog.show(
      context: context,
      title: 'Permanently Delete Story',
      message: 'Delete "${novel.title}"? This will permanently delete this novel, all its episodes, and remove any attached PDF files from Supabase storage.',
      confirmLabel: 'Delete Novel & Files',
      isDestructive: true,
      onConfirm: () => controller.deleteNovel(novel),
    );
  }

  void _confirmDeleteEpisode(BuildContext context, String novelId, EpisodeEntity episode) {
    AppConfirmDialog.show(
      context: context,
      title: 'Delete Chapter ${episode.episodeNumber}',
      message: 'Delete "${episode.title}"? Any attached PDF document will also be permanently deleted from Supabase storage.',
      confirmLabel: 'Delete Chapter',
      isDestructive: true,
      onConfirm: () => controller.deleteEpisode(novelId, episode),
    );
  }

  Widget _buildReportsTab() {
    final reports = controller.reports;
    if (reports.isEmpty) {
      return const AppEmptyState(
        title: 'No user reports',
        message: 'No stories or users have been flagged by readers.',
        icon: Icons.flag_outlined,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
      itemBuilder: (context, index) {
        final rep = reports[index];
        final isPending = rep.status == ReportStatus.pending;

        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: isPending ? AppColors.warningLight : AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.report_problem_outlined,
                  color: isPending ? AppColors.warning : AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Target: "${rep.targetTitle}"',
                            style: AppTextStyles.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        AppStatusChip.reportStatus(rep.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Reported by ${rep.reporterName} • ${_formatDate(rep.createdAt)}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.s),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.s),
                      ),
                      child: Text(
                        '"${rep.reason}"',
                        style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
              if (isPending) ...[
                const SizedBox(width: AppSpacing.m),
                AppPrimaryButton(
                  label: 'Resolve',
                  icon: Icons.check_circle_outline,
                  onPressed: () => controller.resolveReport(rep),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsersTab() {
    final userList = controller.users;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: userList.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
      itemBuilder: (context, index) {
        final u = userList[index];
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  u.displayName.isNotEmpty ? u.displayName[0] : 'U',
                  style: const TextStyle(color: AppColors.textInverse, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            u.displayName,
                            style: AppTextStyles.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            u.role.displayName,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      u.email,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              OutlinedButton(
                onPressed: () => controller.toggleUserStatus(u),
                style: OutlinedButton.styleFrom(
                  foregroundColor: u.isActive ? AppColors.error : AppColors.primary,
                  side: BorderSide(
                    color: u.isActive
                        ? AppColors.error.withValues(alpha: 0.5)
                        : AppColors.primary.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  u.isActive ? 'Suspend' : 'Activate',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: u.isActive ? AppColors.error : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWriterApplicationsTab() {
    if (controller.pendingWriters.isEmpty) {
      return const AppEmptyState(
        title: 'No Pending Writer Applications',
        message: 'All incoming author registration requests have been reviewed and approved.',
        icon: Icons.verified_user_outlined,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.pendingWriters.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
      itemBuilder: (context, index) {
        final writer = controller.pendingWriters[index];
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                    child: Text(
                      writer.displayName.isNotEmpty ? writer.displayName[0] : 'W',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                writer.displayName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppRadii.pill),
                                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'AWAITING APPROVAL',
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          writer.email,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Applied ${_formatDate(writer.createdAt)}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
              if (writer.bio != null && writer.bio!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.m),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadii.m),
                  ),
                  child: Text(
                    '"${writer.bio}"',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.l),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => controller.rejectWriter(writer),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.m),
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject'),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  AppPrimaryButton(
                    label: 'Approve Writer',
                    icon: Icons.check_circle_outline,
                    onPressed: () => controller.approveWriter(writer),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
