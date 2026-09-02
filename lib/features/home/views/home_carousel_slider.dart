import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/novel_entity.dart';

class CarouselSlideData {
  final String imagePath;
  final String badgeText;
  final String title;
  final String genreText;
  final String description;
  final String rating;
  final String? novelId;

  const CarouselSlideData({required this.imagePath, required this.badgeText, required this.title, required this.genreText, required this.description, required this.rating, this.novelId});
}

class HomeCarouselSlider extends StatefulWidget {
  final List<NovelEntity> novels;
  final ValueChanged<NovelEntity>? onNovelTap;

  const HomeCarouselSlider({super.key, this.novels = const [], this.onNovelTap});

  @override
  State<HomeCarouselSlider> createState() => _HomeCarouselSliderState();
}

class _HomeCarouselSliderState extends State<HomeCarouselSlider> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentIndex = 0;

  late final List<CarouselSlideData> _slides;

  @override
  void initState() {
    super.initState();
    _initSlides();
  }

  void _initSlides() {
    _slides = [
      const CarouselSlideData(imagePath: 'assets/imgs/img1.jpg', badgeText: 'FEATURED PICK', title: 'The Clockwork Alchemist', genreText: 'Steampunk • Alchemy', description: 'In steam-shrouded Oakhaven, forbidden transmutation awakens an ancient destiny.', rating: '4.9 ★', novelId: 'novel_1'),
      const CarouselSlideData(imagePath: 'assets/imgs/img2.jpg', badgeText: 'TRENDING NOW', title: 'Whispers Across the Moors', genreText: 'Gothic • Romance', description: 'Seven iron keys unlock the haunting secrets of Yorkshire’s Blackwood Manor.', rating: '4.8 ★', novelId: 'novel_2'),
      const CarouselSlideData(imagePath: 'assets/imgs/img3.jpg', badgeText: 'NEW EPISODE', title: 'Echoes of the Starlit Citadel', genreText: 'Sci-Fi • Space Opera', description: 'Kai navigates the Orion nebula to safeguard the starlight conjunction core.', rating: '5.0 ★', novelId: 'novel_3'),
      const CarouselSlideData(imagePath: 'assets/imgs/img4.jpg', badgeText: 'STAFF CHOICE', title: 'The Silent Cartographer', genreText: 'High Fantasy', description: 'Mapping the shifting realms beyond the Sunken Veil before time dissolves.', rating: '4.9 ★', novelId: 'novel_4'),
      const CarouselSlideData(imagePath: 'assets/imgs/img5.jpg', badgeText: 'TOP RATED', title: 'Celestial Veil', genreText: 'Mythic • Adventure', description: 'An ancient codex reveals constellations bound to human destiny.', rating: '4.9 ★', novelId: 'novel_1'),
    ];
  }

  void _handleSlideTap(CarouselSlideData slide) {
    if (widget.novels.isNotEmpty && widget.onNovelTap != null) {
      final match = widget.novels.firstWhere((n) => n.id == slide.novelId || n.title.toLowerCase() == slide.title.toLowerCase(), orElse: () => widget.novels.first);
      widget.onNovelTap!(match);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    // Proportions optimized for center focus (portrait book-card style)
    final double sliderHeight = isDesktop ? 390.0 : (isTablet ? 370.0 : 350.0);
    final double viewportFraction = isDesktop ? 0.35 : (isTablet ? 0.50 : 0.70);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carousel Slider from carousel_slider package
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: _slides.length,
          options: CarouselOptions(
            height: sliderHeight,
            viewportFraction: viewportFraction,
            autoPlay: true,
            autoPlayInterval: const Duration(milliseconds: 4000),
            autoPlayAnimationDuration: const Duration(milliseconds: 650),
            autoPlayCurve: Curves.easeInOutCubic,
            enlargeCenterPage: true,
            enlargeFactor: 0.32,
            enlargeStrategy: CenterPageEnlargeStrategy.scale,
            enableInfiniteScroll: true,
            padEnds: true,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final slide = _slides[index];
            final isActive = _currentIndex == index;
            return Padding(
              // Spacing between adjacent images
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: _buildSlideCard(slide, isActive: isActive),
            );
          },
        ),

        const SizedBox(height: AppSpacing.l),

        // Animated Page Indicator with direct tap support
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_slides.length, (index) {
              final isActive = _currentIndex == index;
              return GestureDetector(
                onTap: () {
                  _carouselController.animateToPage(index, duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: isActive ? 24.0 : 8.0,
                  height: 7.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    gradient: isActive ? const LinearGradient(colors: [Color(0xFFFFDFB0), AppColors.accent, Color(0xFFC47B49)]) : null,
                    color: isActive ? null : AppColors.cardBorder,
                    boxShadow: isActive ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.55), blurRadius: 8, spreadRadius: 1, offset: const Offset(0, 1))] : null,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSlideCard(CarouselSlideData slide, {bool isActive = true}) {
    return GestureDetector(
      onTap: () => _handleSlideTap(slide),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isActive ? 1.0 : 0.70,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            // Lightning Glowing Illuminated Border for active center card
            gradient: isActive
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFE8C2), // Glowing gold apex
                      Color(0xFFE5A86D), // Warm amber
                      Color(0xFFC47B49), // Terracotta
                      Color(0xFFFFDFB0), // Radiant highlight
                      Color(0xFF8B4D24), // Rich depth accent
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
                    // Ambient lightning aura shadow
                    BoxShadow(color: const Color(0xFFC47B49).withValues(alpha: 0.42), blurRadius: 18, spreadRadius: 1.5, offset: const Offset(0, 6)),
                    // Inner incandescent spark
                    BoxShadow(color: const Color(0xFFFFD580).withValues(alpha: 0.32), blurRadius: 10, spreadRadius: 0.8, offset: const Offset(0, 1)),
                  ]
                : [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
          ),
          // Border wrapper for glowing gradient stroke
          padding: EdgeInsets.all(isActive ? 2.2 : 1.2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xl - 2),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Clean Asset Image as the direct background
              Image.asset(
                slide.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.surfaceMuted,
                    child: const Center(child: Icon(Icons.menu_book_rounded, color: AppColors.accent, size: 48)),
                  );
                },
              ),

              // Bottom gradient only (for clean, legible text without heavy dark background)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.transparent, Colors.black.withValues(alpha: 0.45), Colors.black.withValues(alpha: 0.92)], stops: const [0.0, 0.35, 0.65, 1.0]),
                  ),
                ),
              ),

              // Content Layout (Portrait layout optimized for tall height & narrower width)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Glowing Badge & Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Glassmorphic Glowing Lightning Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.50),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            border: Border.all(color: const Color(0xFFFFDFB0).withValues(alpha: 0.75), width: 1.2),
                            boxShadow: [BoxShadow(color: const Color(0xFFFFD580).withValues(alpha: 0.35), blurRadius: 6)],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFFFDFB0)),
                              const SizedBox(width: 3),
                              Text(
                                slide.badgeText,
                                style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFFFFDFB0), letterSpacing: 0.6),
                              ),
                            ],
                          ),
                        ),

                        // Rating Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            slide.rating,
                            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFFFFE8C2)),
                          ),
                        ),
                      ],
                    ),

                    // Bottom Content Section: Genre, Title, Description, and CTA Button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Genre
                        Text(
                          slide.genreText.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFFFDFB0).withValues(alpha: 0.95), letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 3),

                        // Story Title
                        Text(
                          slide.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.merriweather(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.25,
                            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.9), blurRadius: 6, offset: const Offset(0, 1.5))],
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Story Description
                        Text(
                          slide.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.85), height: 1.35),
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // "Read Now" Radiant Action Button
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8.5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFE5A86D), Color(0xFFC47B49)]),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            border: Border.all(color: const Color(0xFFFFE8C2).withValues(alpha: 0.75), width: 1),
                            boxShadow: [BoxShadow(color: const Color(0xFFC47B49).withValues(alpha: 0.45), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Read Now',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
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
}
