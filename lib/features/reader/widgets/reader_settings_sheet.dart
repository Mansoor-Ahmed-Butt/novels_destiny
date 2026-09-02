import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../controllers/episode_reader_controller.dart';
import '../states/episode_reader_state.dart';

class ReaderSettingsSheet extends StatelessWidget {
  final EpisodeReaderController controller;

  const ReaderSettingsSheet({super.key, required this.controller});

  static void show(BuildContext context, EpisodeReaderController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReaderSettingsSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reading Preferences',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),

            // Font Size Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Text Size', style: AppTextStyles.labelLarge),
                Obx(
                  () => Row(
                    children: [
                      IconButton(
                        onPressed: () => controller.adjustFontSize(-1.5),
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                      Text(
                        '${controller.fontSize.value.toInt()} pt',
                        style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        onPressed: () => controller.adjustFontSize(1.5),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),

            // Typography Switcher
            Text('Typography', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: _buildOptionTile(
                      title: 'Editorial Serif',
                      isSelected: controller.fontFamily.value == ReaderFontFamily.serif,
                      onTap: () => controller.setFontFamily(ReaderFontFamily.serif),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: _buildOptionTile(
                      title: 'Modern Sans',
                      isSelected: controller.fontFamily.value == ReaderFontFamily.sans,
                      onTap: () => controller.setFontFamily(ReaderFontFamily.sans),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),

            // Theme Switcher
            Text('Background Paper Theme', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSpacing.s),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ReaderColorTheme.values.map((t) {
                  final isSelected = controller.colorTheme.value == t;
                  return InkWell(
                    onTap: () => controller.setColorTheme(t),
                    borderRadius: BorderRadius.circular(AppRadii.m),
                    child: Container(
                      width: 72,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: t.backgroundColor,
                        borderRadius: BorderRadius.circular(AppRadii.m),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.cardBorder,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          t.label,
                          style: TextStyle(
                            color: t.textColor,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.m),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceMuted : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.m),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
