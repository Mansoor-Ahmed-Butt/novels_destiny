import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/novel_entity.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_adaptive_image.dart';
import '../controllers/novel_details_controller.dart';

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
            _buildStatItem(
              'Rating',
              novel.rating > 0 ? '${novel.rating.toStringAsFixed(1)} ★' : 'New',
              Icons.star_rounded,
            ),
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

        // Interactive Community Rating Card
        const SizedBox(height: AppSpacing.l),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFEAA228), size: 24),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        novel.rating > 0 ? '${novel.rating.toStringAsFixed(1)} ★' : 'No ratings yet',
                        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (novel.ratingCount > 0) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '(${novel.ratingCount} ${novel.ratingCount == 1 ? "review" : "reviews"})',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    'Reader Feedback',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              Builder(
                builder: (context) {
                  final ctrl = Get.isRegistered<NovelDetailsController>(tag: novel.id)
                      ? Get.find<NovelDetailsController>(tag: novel.id)
                      : null;
                  if (ctrl == null) return const SizedBox.shrink();

                  return Obx(() {
                    final currentRating = ctrl.userRating.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentRating > 0
                              ? 'Your Rating: ${currentRating.toStringAsFixed(0)} ★'
                              : 'Tap a star to rate this novel:',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: currentRating > 0 ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Row(
                          children: List.generate(5, (index) {
                            final star = index + 1;
                            final isFilled = star <= currentRating;
                            return IconButton(
                              iconSize: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: isFilled ? const Color(0xFFEAA228) : AppColors.textTertiary,
                              ),
                              onPressed: ctrl.isSubmittingRating.value
                                  ? null
                                  : () => ctrl.rateNovel(star.toDouble()),
                            );
                          }),
                        ),
                      ],
                    );
                  });
                },
              ),
            ],
          ),
        ),

        // Digital PDF Edition Card (if PDF uploaded)
        if (novel.pdfUrl != null && novel.pdfUrl!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.l),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(AppRadii.m),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AppColors.error,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Digital PDF Book Included',
                        style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        novel.pdfFileName ?? 'Complete Novel Edition (PDF)',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    'PDF Ready',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Story Illustrations Gallery (if gallery images uploaded)
        if (novel.galleryImageUrls.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.l),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Story Illustrations & Visuals',
                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${novel.galleryImageUrls.length} artworks',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: novel.galleryImageUrls.length,
                    separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.m),
                    itemBuilder: (context, index) {
                      final imgUrl = novel.galleryImageUrls[index];
                      return InkWell(
                        onTap: () => _showEnlargedImage(context, imgUrl, index),
                        borderRadius: BorderRadius.circular(AppRadii.m),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.m),
                          child: Container(
                            width: 80,
                            height: 110,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.cardBorder),
                              borderRadius: BorderRadius.circular(AppRadii.m),
                            ),
                            child: AppAdaptiveImage(
                              url: imgUrl,
                              width: 80,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showEnlargedImage(BuildContext context, String url, int index) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.card),
              child: AppAdaptiveImage(
                url: url,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m, horizontal: AppSpacing.s),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.m),
          border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.8)),
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
