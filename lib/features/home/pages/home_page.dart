import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/novel_card.dart';
import '../../../core/responsive/breakpoints.dart';
import '../controllers/home_controller.dart';
import '../views/home_hero_section.dart';
import '../views/continue_reading_section.dart';
import '../views/genre_filter_section.dart';
import '../views/trending_novels_section.dart';
import '../views/home_carousel_slider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/widgets/adaptive_banner_slot.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return AppScaffold(
      body: Obx(() {
        // Show full-screen loader while data is being fetched
        if (controller.isLoading.value) {
          return const AppLoadingState(message: 'Curating world of stories...');
        }

        if (controller.errorMessage.isNotEmpty) {
          return AppErrorState(message: controller.errorMessage.value, onRetry: controller.loadHomeData);
        }

        final user = authController.currentUser.value;

        return RefreshIndicator(
          onRefresh: controller.loadHomeData,
          color: AppColors.primary,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.l),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: AppBreakpoints.maxCardGridWidth, minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top App Header with user greeting
                        AppPageHeader(
                          title: user != null ? 'Hello, ${user.displayName.split(' ').first}' : 'Novels Destiny',
                          subtitle: 'Find your next captivating story',
                          badgeText: user?.role.displayName.toUpperCase(),
                          trailing: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(AppRadii.pill),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Sep 2026',
                                      style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Search bar
                        AppSearchField(hint: 'Search title, writer, or tag...', onChanged: controller.onSearchChanged, onClear: () => controller.onSearchChanged('')),
                        const SizedBox(height: AppSpacing.l),

                        // Search Mode vs Normal Mode
                        if (controller.isSearching.value)
                          _buildSearchResults()
                        else if (controller.selectedGenre.value != 'All')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GenreFilterSection(
                                genres: controller.availableGenres,
                                selectedGenre: controller.selectedGenre.value,
                                onSelectGenre: controller.selectGenre,
                              ),
                              const SizedBox(height: AppSpacing.l),
                              _buildGenreNovelsSection(),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Genre filter chips
                              GenreFilterSection(
                                genres: controller.availableGenres,
                                selectedGenre: controller.selectedGenre.value,
                                onSelectGenre: controller.selectGenre,
                              ),
                              const SizedBox(height: AppSpacing.l),

                              // Featured Banner Carousel — only render when novels are loaded
                              if (controller.featuredNovels.isNotEmpty) ...[
                                HomeCarouselSlider(
                                  novels: List.unmodifiable(controller.featuredNovels),
                                  onNovelTap: controller.openNovel,
                                ),
                                const SizedBox(height: AppSpacing.xl),
                              ],

                              // Continue Reading (if any)
                              if (controller.readingHistory.isNotEmpty) ...[
                                ContinueReadingSection(
                                  history: controller.readingHistory,
                                  novelMap: controller.historyNovelMap,
                                  onResumeTap: controller.resumeReading,
                                ),
                                const SizedBox(height: AppSpacing.xl),
                              ],

                              // Featured Hero Section
                              if (controller.featuredNovels.isNotEmpty) ...[
                                HomeHeroSection(
                                  novels: List.unmodifiable(controller.featuredNovels),
                                  onNovelTap: controller.openNovel,
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                              ],

                              // Trending Grid
                              TrendingNovelsSection(
                                novels: List.unmodifiable(controller.trendingNovels),
                                onNovelTap: controller.openNovel,
                              ),
                              AdaptiveBannerSlot(placementKey: 'home_footer', userRole: user?.role),
                              const SizedBox(height: AppSpacing.xxxl),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildSearchResults() {
    final results = controller.searchResults;
    if (results.isEmpty) {
      return const AppEmptyState(title: 'No stories found', message: 'Try adjusting your search keywords or exploring different genres.', icon: Icons.search_off_rounded);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Search Results (${results.length})', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.m),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: results.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
          itemBuilder: (context, index) {
            final novel = results[index];
            return NovelCard(novel: novel, variant: NovelCardVariant.list, onTap: () => controller.openNovel(novel));
          },
        ),
      ],
    );
  }

  Widget _buildGenreNovelsSection() {
    final genre = controller.selectedGenre.value;

    if (controller.isGenreLoading.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: AppLoadingState(message: 'Exploring realm stories...'),
      );
    }

    final novels = controller.genreNovels;

    if (novels.isEmpty) {
      return AppEmptyState(title: 'No $genre Stories Yet', message: 'No published stories found under "$genre". Writers can publish the very first novel here!', icon: Icons.auto_stories_outlined, actionLabel: 'Explore All Stories', onAction: () => controller.selectGenre('All'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$genre Stories', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                Text('${novels.length} ${novels.length == 1 ? "story" : "stories"} found', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary)),
              ],
            ),
            TextButton.icon(
              onPressed: () => controller.selectGenre('All'),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Show All'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: novels.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
          itemBuilder: (context, index) {
            final novel = novels[index];
            return NovelCard(novel: novel, variant: NovelCardVariant.list, onTap: () => controller.openNovel(novel));
          },
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
