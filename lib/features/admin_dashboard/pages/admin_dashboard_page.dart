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
import '../../../core/responsive/breakpoints.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../../writer_dashboard/widgets/writer_chart_view.dart';
import '../../../domain/entities/report_entity.dart';

class AdminDashboardPage extends GetView<AdminDashboardController> {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                        SummarySubMetric(label: 'Total Users', value: '${stats?.totalUsers ?? 0}'),
                        SummarySubMetric(label: 'Stories', value: '${stats?.totalNovels ?? 0}'),
                        SummarySubMetric(label: 'Pending Review', value: '${controller.pendingNovels.length}'),
                        SummarySubMetric(label: 'Reports', value: '${controller.reports.where((r) => r.status == ReportStatus.pending).length}'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Time Series Chart
                    if (stats != null && stats.dailyReadsTrend.isNotEmpty) ...[
                      WriterChartView(
                        dataPoints: stats.dailyReadsTrend,
                        title: 'Platform-wide Traffic Growth',
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // Section Tabs: Moderation Queue, Reports, Users
                    Row(
                      children: [
                        _buildTab('Moderation Queue (${controller.pendingNovels.length})', 0),
                        const SizedBox(width: AppSpacing.s),
                        _buildTab('User Reports (${controller.reports.length})', 1),
                        const SizedBox(width: AppSpacing.s),
                        _buildTab('Users (${controller.users.length})', 2),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),

                    if (controller.selectedTab.value == 0)
                      _buildModerationTab()
                    else if (controller.selectedTab.value == 1)
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

  Widget _buildModerationTab() {
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
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.m),
      itemBuilder: (context, index) {
        final novel = pending[index];
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Row(
            children: [
              NovelCover(url: novel.coverUrl, title: novel.title, width: 64, height: 90),
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
                          ),
                        ),
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
              const SizedBox(width: AppSpacing.m),
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
            ],
          ),
        );
      },
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
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.m),
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
                        Text('Target: "${rep.targetTitle}"', style: AppTextStyles.titleSmall),
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
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.m),
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
                        Text(u.displayName, style: AppTextStyles.titleSmall),
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
                    Text(u.email, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              AppSecondaryButton(
                label: u.isActive ? 'Suspend' : 'Activate',
                onPressed: () => controller.toggleUserStatus(u),
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
