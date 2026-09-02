import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../../domain/entities/novel_entity.dart';
import 'novel_cover.dart';
import 'app_status_chip.dart';
import 'app_card.dart';

enum NovelCardVariant { grid, list, hero }

class NovelCard extends StatelessWidget {
  final NovelEntity novel;
  final VoidCallback onTap;
  final NovelCardVariant variant;
  final double? readingProgress; // 0.0 to 1.0 if continuing reading

  const NovelCard({
    super.key,
    required this.novel,
    required this.onTap,
    this.variant = NovelCardVariant.grid,
    this.readingProgress,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case NovelCardVariant.grid:
        return _buildGridCard(context);
      case NovelCardVariant.list:
        return _buildListCard(context);
      case NovelCardVariant.hero:
        return _buildHeroCard(context);
    }
  }

  Widget _buildGridCard(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: NovelCover(
                    url: novel.coverUrl,
                    title: novel.title,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: AppStatusChip.novelStatus(novel.status),
                ),
                if (readingProgress != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadii.m)),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: readingProgress!.clamp(0.0, 1.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadii.m)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            novel.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            novel.writerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD48828)),
                  const SizedBox(width: 2),
                  Text(
                    novel.rating.toStringAsFixed(1),
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
              Text(
                '${novel.publishedEpisodeCount} chs',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NovelCover(
            url: novel.coverUrl,
            title: novel.title,
            width: 80,
            height: 110,
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        novel.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    AppStatusChip.novelStatus(novel.status),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  novel.writerName,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  novel.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary, height: 1.3),
                ),
                const SizedBox(height: AppSpacing.s),
                Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${novel.publishedEpisodeCount} Chapters',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    const Icon(Icons.favorite_rounded, size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      '${novel.totalLikes}',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.l),
      backgroundColor: AppColors.surfaceMuted,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          NovelCover(
            url: novel.coverUrl,
            title: novel.title,
            width: 100,
            height: 140,
          ),
          const SizedBox(width: AppSpacing.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppStatusChip.novelStatus(novel.status),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  novel.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'By ${novel.writerName}',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.s),
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
      ),
    );
  }
}
