import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/novel_entity.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/novel_cover.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../../../core/widgets/app_buttons.dart';

class WriterNovelCard extends StatelessWidget {
  final NovelEntity novel;
  final VoidCallback onAddEpisode;
  final VoidCallback onEdit;
  final VoidCallback onView;

  const WriterNovelCard({
    super.key,
    required this.novel,
    required this.onAddEpisode,
    required this.onEdit,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onEdit,
      padding: const EdgeInsets.all(AppSpacing.m),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // If available width is compact (mobile), stack actions below story details
          if (constraints.maxWidth < 600) {
            return _buildCompactLayout(context);
          }
          // Wide layout for tablets and desktops
          return _buildWideLayout(context);
        },
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NovelCover(
              url: novel.coverUrl,
              title: novel.title,
              width: 68,
              height: 96,
              borderRadius: AppRadii.m,
            ),
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
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      AppStatusChip.novelStatus(novel.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),
                  _buildStatsWrap(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        Divider(
          height: 1,
          thickness: 1,
          color: AppColors.cardBorder.withValues(alpha: 0.6),
        ),
        const SizedBox(height: AppSpacing.s),
        Row(
          children: [
            Expanded(
              child: AppSecondaryButton(
                label: 'Add Episode',
                icon: Icons.add_rounded,
                isExpanded: true,
                onPressed: onAddEpisode,
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            AppIconButton(
              icon: Icons.edit_outlined,
              tooltip: 'Edit Story Details',
              onPressed: onEdit,
            ),
            const SizedBox(width: AppSpacing.xs),
            AppIconButton(
              icon: Icons.visibility_outlined,
              tooltip: 'View as Reader',
              onPressed: onView,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        NovelCover(
          url: novel.coverUrl,
          title: novel.title,
          width: 72,
          height: 102,
          borderRadius: AppRadii.m,
        ),
        const SizedBox(width: AppSpacing.l),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      novel.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  AppStatusChip.novelStatus(novel.status),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              _buildStatsWrap(),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.l),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSecondaryButton(
              label: 'Add Episode',
              icon: Icons.add_rounded,
              onPressed: onAddEpisode,
            ),
            const SizedBox(width: AppSpacing.s),
            AppIconButton(
              icon: Icons.edit_outlined,
              tooltip: 'Edit Story Details',
              onPressed: onEdit,
            ),
            const SizedBox(width: AppSpacing.xs),
            AppIconButton(
              icon: Icons.visibility_outlined,
              tooltip: 'View as Reader',
              onPressed: onView,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsWrap() {
    final episodeLabel = novel.publishedEpisodeCount == 1
        ? '1 Episode'
        : '${novel.publishedEpisodeCount} Episodes';

    return Wrap(
      spacing: AppSpacing.m,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildStatBadge(Icons.auto_stories_outlined, episodeLabel),
        _buildStatBadge(Icons.visibility_outlined, '${_formatNumber(novel.totalViews)} Reads'),
        _buildStatBadge(Icons.favorite_border_rounded, '${_formatNumber(novel.totalLikes)} Likes'),
      ],
    );
  }

  Widget _buildStatBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}
