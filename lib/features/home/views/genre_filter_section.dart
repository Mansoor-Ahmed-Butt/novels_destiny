import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class GenreFilterSection extends StatelessWidget {
  final List<String> genres;
  final String selectedGenre;
  final ValueChanged<String> onSelectGenre;

  const GenreFilterSection({
    super.key,
    required this.genres,
    required this.selectedGenre,
    required this.onSelectGenre,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s),
        itemBuilder: (context, index) {
          final genre = genres[index];
          final isSelected = genre == selectedGenre;
          return InkWell(
            onTap: () => onSelectGenre(genre),
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
                genre,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? AppColors.textInverse : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
