import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/responsive/breakpoints.dart';
import '../controllers/episode_reader_controller.dart';
import '../states/episode_reader_state.dart';
import '../widgets/reader_settings_sheet.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../domain/entities/content_block_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../auth/controllers/auth_controller.dart';
import '../widgets/reader_inline_banner_ad.dart';
import '../../../core/widgets/app_adaptive_image.dart';
import '../../../core/utils/novel_text_helper.dart';

class EpisodeReaderPage extends StatelessWidget {
  const EpisodeReaderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final novelId = Get.parameters['novelId'] ?? '';
    final episodeId = Get.parameters['episodeId'] ?? '';
    final ctrl = Get.find<EpisodeReaderController>(tag: '$novelId-$episodeId');
    final userRole = Get.find<AuthController>().currentUser.value?.role;

    return Obx(() {
      final state = ctrl.state.value;
      final theme = ctrl.colorTheme.value;

      return Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: _buildAppBar(context, ctrl, state, theme),
        drawer: _buildTocDrawer(context, ctrl, state),
        body: switch (state) {
          EpisodeReaderLoading() => const AppLoadingState(
            message: 'Opening chapter page...',
          ),
          EpisodeReaderFailure(:final message) => AppErrorState(
            message: message,
            onRetry: () => ctrl.loadEpisode(ctrl.initialEpisodeId),
          ),
          EpisodeReaderReady(
            :final novel,
            :final currentEpisode,
            :final previousEpisode,
            :final nextEpisode,
          ) =>
            Stack(
              children: [
                // Reading prose centered inside constrained column
                GestureDetector(
                  onTap: ctrl.toggleControls,
                  child: SingleChildScrollView(
                    controller: ctrl.scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xxl,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppBreakpoints.maxReaderWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Novel & Episode Title Header
                            Text(
                              novel.title.toUpperCase(),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: theme.textColor.withValues(alpha: 0.6),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s),
                            Text(
                              currentEpisode.title,
                              textDirection: NovelTextHelper.isUrduText(currentEpisode.title)
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              textAlign: NovelTextHelper.isUrduText(currentEpisode.title)
                                  ? TextAlign.right
                                  : TextAlign.left,
                              style: NovelTextHelper.isUrduText(currentEpisode.title)
                                  ? GoogleFonts.notoNastaliqUrdu(
                                      fontSize: ctrl.fontSize.value + 8,
                                      fontWeight: FontWeight.w700,
                                      color: theme.textColor,
                                      height: 1.8,
                                    )
                                  : (ctrl.fontFamily.value ==
                                          ReaderFontFamily.serif
                                      ? GoogleFonts.merriweather(
                                          fontSize: ctrl.fontSize.value + 8,
                                          fontWeight: FontWeight.w700,
                                          color: theme.textColor,
                                          height: 1.3,
                                        )
                                      : GoogleFonts.plusJakartaSans(
                                          fontSize: ctrl.fontSize.value + 8,
                                          fontWeight: FontWeight.w700,
                                          color: theme.textColor,
                                          height: 1.3,
                                        )),
                            ),
                            const SizedBox(height: AppSpacing.s),
                            Text(
                              'Chapter ${currentEpisode.episodeNumber} • ${currentEpisode.wordCount} words',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: theme.textColor.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Divider(
                              color: theme.textColor.withValues(alpha: 0.15),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Main Story Content (Sequential Content Blocks)
                            ..._buildContentBlocks(
                              ctrl,
                              theme,
                              ctrl.readingBlocks,
                              userRole: userRole,
                            ),

                            const SizedBox(height: AppSpacing.xxxl),
                            Divider(
                              color: theme.textColor.withValues(alpha: 0.15),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Latest Chapter caught-up indicator
                            if (nextEpisode == null) ...[
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.textColor.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.pill,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 16,
                                        color: theme.textColor.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          "You've caught up with the latest chapter!",
                                          style: AppTextStyles.bodySmall
                                              .copyWith(color: theme.textColor),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.l),
                            ],

                            // Navigation Buttons (Prev / Next Chapter)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (previousEpisode != null)
                                  AppSecondaryButton(
                                    label: 'Prev Chapter',
                                    icon: Icons.chevron_left_rounded,
                                    onPressed: ctrl.goToPreviousEpisode,
                                  )
                                else
                                  const SizedBox(width: 8),
                                if (nextEpisode != null)
                                  AppPrimaryButton(
                                    label: 'Next Chapter',
                                    icon: Icons.chevron_right_rounded,
                                    onPressed: ctrl.goToNextEpisode,
                                  )
                                else
                                  const SizedBox(width: 8),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xxxl),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Top Floating Reading Progress Bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Obx(
                    () => LinearProgressIndicator(
                      value: ctrl.progressPercent.value.clamp(0.0, 1.0),
                      backgroundColor: Colors.transparent,
                      color: AppColors.accent,
                      minHeight: 3,
                    ),
                  ),
                ),
              ],
            ),
        },
      );
    });
  }

  PreferredSizeWidget? _buildAppBar(
    BuildContext context,
    EpisodeReaderController ctrl,
    EpisodeReaderState state,
    ReaderColorTheme theme,
  ) {
    if (!ctrl.showControls.value) return null;

    final title = state is EpisodeReaderReady
        ? state.currentEpisode.title
        : 'Reader';

    return AppBar(
      backgroundColor: theme.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: theme.textColor),
        onPressed: () => Get.back(),
      ),
      title: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(color: theme.textColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        // Table of contents drawer trigger
        Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu_book_rounded, color: theme.textColor),
            tooltip: 'Table of Contents',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        // Reading Settings Sheet trigger
        IconButton(
          icon: Icon(Icons.format_size_rounded, color: theme.textColor),
          tooltip: 'Reading Preferences',
          onPressed: () => ReaderSettingsSheet.show(context, ctrl),
        ),
      ],
    );
  }

  Widget _buildTocDrawer(
    BuildContext context,
    EpisodeReaderController ctrl,
    EpisodeReaderState state,
  ) {
    if (state is! EpisodeReaderReady) return const SizedBox.shrink();

    return Drawer(
      backgroundColor: AppColors.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.novel.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Table of Contents (${state.allEpisodes.length} Chapters)',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: state.allEpisodes.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final ep = state.allEpisodes[index];
                  final isCurrent = ep.id == state.currentEpisode.id;

                  return ListTile(
                    tileColor: isCurrent
                        ? AppColors.surfaceMuted
                        : Colors.transparent,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: isCurrent
                          ? AppColors.primary
                          : AppColors.surface,
                      child: Text(
                        '${ep.episodeNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCurrent
                              ? AppColors.textInverse
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      ep.title,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isCurrent
                        ? const Icon(
                            Icons.bookmark_rounded,
                            size: 18,
                            color: AppColors.accent,
                          )
                        : null,
                    onTap: () {
                      Navigator.of(context).pop();
                      ctrl.goToEpisode(ep);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContentBlocks(
    EpisodeReaderController ctrl,
    ReaderColorTheme theme,
    List<ContentBlockEntity> blocks, {
    UserRole? userRole,
  }) {
    if (blocks.isEmpty) {
      return [
        Text(
          'No content available in this chapter.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: theme.textColor.withValues(alpha: 0.6),
          ),
        ),
      ];
    }

    final widgets = <Widget>[];

    for (final block in blocks) {
      switch (block.type) {
        case ContentBlockType.text:
          if (block.content.trim().isNotEmpty) {
            final isUrdu = NovelTextHelper.isUrduText(block.content);
            widgets.add(
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.l),
                child: Text(
                  block.content,
                  textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                  textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                  style: isUrdu
                      ? GoogleFonts.notoNastaliqUrdu(
                          fontSize: ctrl.fontSize.value + 2,
                          height: 2.1,
                          color: theme.textColor,
                        )
                      : (ctrl.fontFamily.value == ReaderFontFamily.serif
                          ? GoogleFonts.merriweather(
                              fontSize: ctrl.fontSize.value,
                              height: ctrl.lineHeight.value,
                              color: theme.textColor,
                            )
                          : GoogleFonts.plusJakartaSans(
                              fontSize: ctrl.fontSize.value,
                              height: ctrl.lineHeight.value,
                              color: theme.textColor,
                            )),
                ),
              ),
            );
          }
          break;

        case ContentBlockType.image:
          final imageUrl = block.url ?? '';
          if (imageUrl.isNotEmpty) {
            widgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppAdaptiveImage(
                      url: imageUrl,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(AppRadii.m),
                      width: double.infinity,
                    ),
                    if (block.caption != null &&
                        block.caption!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        block.caption!,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.textColor.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
          break;

        case ContentBlockType.pdf:
          final pdfUrl = block.url ?? '';
          if (pdfUrl.isNotEmpty) {
            widgets.add(
              Container(
                height: 480,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.m),
                  border: Border.all(
                    color: theme.textColor.withValues(alpha: 0.15),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.m),
                  child:
                      pdfUrl.startsWith('http://') ||
                          pdfUrl.startsWith('https://')
                      ? SfPdfViewer.network(pdfUrl)
                      : SfPdfViewer.file(File(pdfUrl)),
                ),
              ),
            );
          }
          break;

        case ContentBlockType.ad:
          widgets.add(
            ReaderInlineBannerAd(
              theme: theme,
              slotKey: block.id,
              userRole: userRole,
            ),
          );
          break;
      }
    }

    return widgets;
  }
}
