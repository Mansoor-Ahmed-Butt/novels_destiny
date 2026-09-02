import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/novel_entity.dart';
import '../../../core/widgets/novel_cover.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../../../core/widgets/app_card.dart';

class NovelHeroSection extends StatelessWidget {
  final NovelEntity novel;

  const NovelHeroSection({super.key, required this.novel});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.surfaceMuted,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NovelCover(
            url: novel.coverUrl,
            title: novel.title,
            width: 120,
            height: 175,
            borderRadius: AppRadii.card,
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppStatusChip.novelStatus(novel.status),
                    const SizedBox(width: AppSpacing.s),
                    AppStatusChip.moderationStatus(novel.moderationStatus),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  novel.title,
                  style: AppTextStyles.displayMedium.copyWith(fontSize: 22, height: 1.2),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Written by ',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                    ),
                    Text(
                      novel.writerName,
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                // Genre tags
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: novel.genreIds
                      .map(
                        (g) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(
                            g,
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
