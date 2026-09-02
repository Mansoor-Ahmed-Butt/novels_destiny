import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/novel_entity.dart';
import '../../../core/widgets/novel_card.dart';

class HomeHeroSection extends StatelessWidget {
  final List<NovelEntity> novels;
  final ValueChanged<NovelEntity> onNovelTap;

  const HomeHeroSection({
    super.key,
    required this.novels,
    required this.onNovelTap,
  });

  @override
  Widget build(BuildContext context) {
    if (novels.isEmpty) return const SizedBox.shrink();

    final featured = novels.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Spotlight',
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                'Editor\'s Choice',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        NovelCard(
          novel: featured,
          variant: NovelCardVariant.hero,
          onTap: () => onNovelTap(featured),
        ),
      ],
    );
  }
}
