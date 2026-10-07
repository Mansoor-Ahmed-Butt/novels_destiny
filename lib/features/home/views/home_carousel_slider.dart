import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/novel_entity.dart';
import '../controllers/home_carousel_controller.dart';

class HomeCarouselSlider extends StatefulWidget {
  final List<NovelEntity> novels;
  final ValueChanged<NovelEntity>? onNovelTap;

  const HomeCarouselSlider({
    super.key,
    this.novels = const [],
    this.onNovelTap,
  });

  @override
  State<HomeCarouselSlider> createState() => _HomeCarouselSliderState();
}

class _HomeCarouselSliderState extends State<HomeCarouselSlider> {
  // Unique tag per instance so multiple carousels never clash
  static const _tag = 'home_carousel';
  late final HomeCarouselController _carouselCtrl;

  @override
  void initState() {
    super.initState();
    // Register only once, reuse if already registered (e.g. hot-reload)
    _carouselCtrl = Get.isRegistered<HomeCarouselController>(tag: _tag)
        ? Get.find<HomeCarouselController>(tag: _tag)
        : Get.put(HomeCarouselController(), tag: _tag, permanent: false);
  }

  @override
  void dispose() {
    // Clean up when the widget is removed from the tree
    if (Get.isRegistered<HomeCarouselController>(tag: _tag)) {
      Get.delete<HomeCarouselController>(tag: _tag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If no real novels yet, show a placeholder
    if (widget.novels.isEmpty) {
      return _EmptyCarouselPlaceholder();
    }

    final controller = _carouselCtrl;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    final double sliderHeight = isDesktop ? 390.0 : (isTablet ? 370.0 : 350.0);
    final double viewportFraction = isDesktop ? 0.35 : (isTablet ? 0.50 : 0.70);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarouselSlider.builder(
          carouselController: controller.carouselController,
          itemCount: widget.novels.length,
          options: CarouselOptions(
            height: sliderHeight,
            viewportFraction: viewportFraction,
            autoPlay: widget.novels.length > 1,
            autoPlayInterval: const Duration(milliseconds: 4000),
            autoPlayAnimationDuration: const Duration(milliseconds: 650),
            autoPlayCurve: Curves.easeInOutCubic,
            enlargeCenterPage: true,
            enlargeFactor: 0.32,
            enlargeStrategy: CenterPageEnlargeStrategy.scale,
            enableInfiniteScroll: widget.novels.length > 1,
            padEnds: true,
            onPageChanged: controller.onPageChanged,
          ),
          itemBuilder: (context, index, realIndex) {
            final novel = widget.novels[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Obx(() {
                final isActive = controller.currentIndex.value == index;
                return _buildSlideCard(novel, isActive: isActive);
              }),
            );
          },
        ),

        const SizedBox(height: AppSpacing.l),

        // Animated Page Indicator
        if (widget.novels.length > 1)
          Center(
            child: Obx(() => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.novels.length, (index) {
                final isActive = controller.currentIndex.value == index;
                return GestureDetector(
                  onTap: () => controller.animateToSlide(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: isActive ? 24.0 : 8.0,
                    height: 7.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      gradient: isActive
                          ? const LinearGradient(
                              colors: [
                                Color(0xFFFFDFB0),
                                AppColors.accent,
                                Color(0xFFC47B49),
                              ],
                            )
                          : null,
                      color: isActive ? null : AppColors.cardBorder,
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.55),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            )),
          ),
      ],
    );
  }

  Widget _buildSlideCard(NovelEntity novel, {bool isActive = true}) {
    final badgeText = novel.status == NovelStatus.completed
        ? 'COMPLETED'
        : novel.publishedEpisodeCount > 0
            ? 'CHAPTER ${novel.publishedEpisodeCount}'
            : 'NEW STORY';

    return GestureDetector(
      onTap: () => widget.onNovelTap?.call(novel),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isActive ? 1.0 : 0.70,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            gradient: isActive
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFE8C2),
                      Color(0xFFE5A86D),
                      Color(0xFFC47B49),
                      Color(0xFFFFDFB0),
                      Color(0xFF8B4D24),
                    ],
                    stops: [0.0, 0.25, 0.55, 0.8, 1.0],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.20),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFFC47B49).withValues(alpha: 0.42),
                      blurRadius: 18,
                      spreadRadius: 1.5,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: const Color(0xFFFFD580).withValues(alpha: 0.32),
                      blurRadius: 10,
                      spreadRadius: 0.8,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          padding: EdgeInsets.all(isActive ? 2.2 : 1.2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xl - 2),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Novel cover image
                _buildCoverImage(novel.coverUrl),

                // Bottom gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.45),
                          Colors.black.withValues(alpha: 0.92),
                        ],
                        stops: const [0.0, 0.35, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Badge & Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.50),
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                              border: Border.all(
                                color: const Color(0xFFFFDFB0).withValues(alpha: 0.75),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD580).withValues(alpha: 0.35),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFFFDFB0)),
                                const SizedBox(width: 3),
                                Text(
                                  badgeText,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFFFDFB0),
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              novel.rating > 0 ? '${novel.rating.toStringAsFixed(1)} ★' : '— ★',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFFE8C2),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Bottom Content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (novel.genreIds.isNotEmpty)
                            Text(
                              novel.genreIds.take(2).join(' • ').toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFFDFB0).withValues(alpha: 0.95),
                                letterSpacing: 1.0,
                              ),
                            ),
                          const SizedBox(height: 3),
                          Text(
                            novel.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.merriweather(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.25,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.9),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (novel.description.isNotEmpty)
                            Text(
                              novel.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.35,
                              ),
                            ),
                          const SizedBox(height: AppSpacing.m),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8.5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE5A86D), Color(0xFFC47B49)],
                              ),
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                              border: Border.all(
                                color: const Color(0xFFFFE8C2).withValues(alpha: 0.75),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFC47B49).withValues(alpha: 0.45),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Read Now',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(String? coverUrl) {
    if (coverUrl != null && coverUrl.isNotEmpty) {
      return Image.network(
        coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackCover(),
      );
    }
    return _fallbackCover();
  }

  Widget _fallbackCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.menu_book_rounded, color: AppColors.accent, size: 48),
      ),
    );
  }
}

class _EmptyCarouselPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.library_books_outlined, size: 56, color: AppColors.accent),
          const SizedBox(height: 16),
          Text(
            'No stories published yet',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Admin or writers can publish novels from the Studio tab.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
