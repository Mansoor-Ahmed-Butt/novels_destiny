import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class NovelCover extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final double borderRadius;
  final String? title;

  const NovelCover({
    super.key,
    required this.url,
    this.width = 110,
    this.height = 160,
    this.borderRadius = AppRadii.m,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: AppShadows.subtle,
        ),
        child: Image.network(
          url,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: width,
              height: height,
              color: AppColors.surfaceMuted,
              padding: const EdgeInsets.all(AppSpacing.s),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.book_rounded, color: AppColors.textTertiary, size: 28),
                  if (title != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ],
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: width,
              height: height,
              color: AppColors.surfaceMuted,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
