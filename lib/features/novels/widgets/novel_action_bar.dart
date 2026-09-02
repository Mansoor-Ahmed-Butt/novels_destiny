import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_buttons.dart';

class NovelActionBar extends StatelessWidget {
  final bool isLiked;
  final bool isSaved;
  final bool isDownloadEligible;
  final bool hasStartedReading;
  final VoidCallback onRead;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleSave;
  final VoidCallback? onDownload;
  final VoidCallback onReport;

  const NovelActionBar({
    super.key,
    required this.isLiked,
    required this.isSaved,
    required this.isDownloadEligible,
    required this.hasStartedReading,
    required this.onRead,
    required this.onToggleLike,
    required this.onToggleSave,
    this.onDownload,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Like Button
            AppIconButton(
              icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              iconColor: isLiked ? AppColors.accent : AppColors.textPrimary,
              onPressed: onToggleLike,
              tooltip: isLiked ? 'Liked' : 'Like Story',
            ),
            const SizedBox(width: AppSpacing.s),

            // Save/Bookmark Button
            AppIconButton(
              icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
              iconColor: isSaved ? AppColors.primary : AppColors.textPrimary,
              onPressed: onToggleSave,
              tooltip: isSaved ? 'Saved in Library' : 'Save to Library',
            ),
            const SizedBox(width: AppSpacing.s),

            // Download (if eligible)
            if (isDownloadEligible && onDownload != null) ...[
              AppIconButton(
                icon: Icons.download_rounded,
                iconColor: AppColors.primary,
                onPressed: onDownload,
                tooltip: 'Download Full Novel',
              ),
              const SizedBox(width: AppSpacing.s),
            ],

            // Report
            AppIconButton(
              icon: Icons.flag_outlined,
              iconColor: AppColors.textTertiary,
              onPressed: onReport,
              tooltip: 'Report Content',
            ),
            const SizedBox(width: AppSpacing.m),

            // Read / Continue button
            Expanded(
              child: AppPrimaryButton(
                label: hasStartedReading ? 'Continue Reading' : 'Start Reading',
                icon: hasStartedReading ? Icons.auto_stories : Icons.play_arrow_rounded,
                onPressed: onRead,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
