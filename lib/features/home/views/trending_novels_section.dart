import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/novel_entity.dart';
import '../../../core/widgets/novel_card.dart';
import '../../../core/responsive/breakpoints.dart';

class TrendingNovelsSection extends StatelessWidget {
  final List<NovelEntity> novels;
  final ValueChanged<NovelEntity> onNovelTap;

  const TrendingNovelsSection({
    super.key,
    required this.novels,
    required this.onNovelTap,
  });

  @override
  Widget build(BuildContext context) {
    if (novels.isEmpty) return const SizedBox.shrink();

    final isCompact = AppBreakpoints.isCompact(context);
    final crossAxisCount = isCompact ? 2 : (AppBreakpoints.isMedium(context) ? 3 : 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up_rounded, size: 20, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  'Popular & Trending',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Text(
              '${novels.length} stories',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.68,
            crossAxisSpacing: AppSpacing.m,
            mainAxisSpacing: AppSpacing.m,
          ),
          itemCount: novels.length,
          itemBuilder: (context, index) {
            final novel = novels[index];
            return NovelCard(
              novel: novel,
              variant: NovelCardVariant.grid,
              onTap: () => onNovelTap(novel),
            );
          },
        ),
      ],
    );
  }
}
