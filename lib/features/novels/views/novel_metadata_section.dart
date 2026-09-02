import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/novel_entity.dart';
import '../../../core/widgets/app_card.dart';

class NovelMetadataSection extends StatelessWidget {
  final NovelEntity novel;

  const NovelMetadataSection({super.key, required this.novel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metric Counters Row
        Row(
          children: [
            _buildStatItem('Reads', _formatNumber(novel.totalViews), Icons.visibility_outlined),
            const SizedBox(width: AppSpacing.s),
            _buildStatItem('Likes', _formatNumber(novel.totalLikes), Icons.favorite_outline_rounded),
            const SizedBox(width: AppSpacing.s),
            _buildStatItem('Rating', novel.rating.toStringAsFixed(1), Icons.star_outline_rounded),
            const SizedBox(width: AppSpacing.s),
            _buildStatItem('Chapters', '${novel.publishedEpisodeCount}', Icons.menu_book_rounded),
          ],
        ),
        const SizedBox(height: AppSpacing.l),

        // Synopsis Card
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Synopsis',
                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                novel.description,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.55,
                ),
              ),
              if (novel.tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.l),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: novel.tags
                      .map(
                        (t) => Text(
                          '#$t ',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m, horizontal: AppSpacing.s),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.m),
          border: Border.all(color: AppColors.cardBorder.withOpacity(0.8)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppColors.textTertiary),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}
