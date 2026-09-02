import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/novel_entity.dart';
import '../../../domain/entities/reading_progress_entity.dart';
import '../../../core/widgets/novel_cover.dart';
import '../../../core/widgets/app_card.dart';

class ContinueReadingSection extends StatelessWidget {
  final List<ReadingProgressEntity> history;
  final Map<String, NovelEntity> novelMap;
  final ValueChanged<ReadingProgressEntity> onResumeTap;

  const ContinueReadingSection({
    super.key,
    required this.history,
    required this.novelMap,
    required this.onResumeTap,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.bookmark_added_rounded, size: 18, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  'Continue Reading',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Text(
              '${history.length} in progress',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.m),
            itemBuilder: (context, index) {
              final progress = history[index];
              final novel = novelMap[progress.novelId];
              if (novel == null) return const SizedBox.shrink();

              final percentInt = (progress.progressPercent * 100).toInt();

              return AppCard(
                onTap: () => onResumeTap(progress),
                padding: const EdgeInsets.all(AppSpacing.s),
                child: SizedBox(
                  width: 260,
                  child: Row(
                    children: [
                      NovelCover(
                        url: novel.coverUrl,
                        title: novel.title,
                        width: 64,
                        height: 90,
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              novel.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Chapter ${progress.episodeNumber}',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: AppSpacing.s),
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                              child: LinearProgressIndicator(
                                value: progress.progressPercent.clamp(0.05, 1.0),
                                backgroundColor: AppColors.surfaceMuted,
                                color: AppColors.accent,
                                minHeight: 5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$percentInt% completed',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
