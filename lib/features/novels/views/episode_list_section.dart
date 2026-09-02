import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/episode_entity.dart';
import '../../../core/widgets/app_card.dart';

class EpisodeListSection extends StatelessWidget {
  final List<EpisodeEntity> episodes;
  final ValueChanged<EpisodeEntity> onEpisodeTap;

  const EpisodeListSection({
    super.key,
    required this.episodes,
    required this.onEpisodeTap,
  });

  @override
  Widget build(BuildContext context) {
    if (episodes.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.edit_note_rounded, size: 36, color: AppColors.textTertiary),
              const SizedBox(height: AppSpacing.s),
              Text(
                'No episodes published yet',
                style: AppTextStyles.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                'The author is currently crafting the upcoming chapters.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Table of Contents (${episodes.length})',
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'All Released Chapters',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: episodes.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
          itemBuilder: (context, index) {
            final ep = episodes[index];
            return AppCard(
              onTap: () => onEpisodeTap(ep),
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.s),
                    ),
                    child: Center(
                      child: Text(
                        '${ep.episodeNumber}',
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
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
                          style: AppTextStyles.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (ep.summary != null && ep.summary!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            ep.summary!,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Text(
                    '${ep.wordCount} words',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
