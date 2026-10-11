import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/localization/localization_service.dart';
import '../controllers/profile_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return AppScaffold(
      body: Obx(() {
        final user = authController.currentUser.value;
        if (user == null) return const SizedBox.shrink();

        final currentLocale = controller.currentLocale.value;
        final isUrdu = currentLocale.languageCode == 'ur';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxFormWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageHeader(
                    title: 'account_profile'.tr,
                    subtitle: 'account_profile_subtitle'.tr,
                    badgeText: user.role.displayName.toUpperCase(),
                  ),

                  // Language Switcher Section (English / Urdu)
                  _buildLanguageSelectorCard(context, isUrdu),

                  const SizedBox(height: AppSpacing.l),

                  // User Info Card
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppCard(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0]
                                      : 'U',
                                  style: const TextStyle(
                                    color: AppColors.textInverse,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.m),
                              Text(
                                user.displayName,
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.l),
                              if (user.bio != null &&
                                  user.bio!.isNotEmpty &&
                                  !controller.isEditing.value) ...[
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.m),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.m,
                                    ),
                                  ),
                                  child: Text(
                                    user.bio!,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.l),
                              ],
                              if (controller.isEditing.value) ...[
                                AppTextField(
                                  label: 'display_name'.tr,
                                  controller: controller.nameController,
                                ),
                                const SizedBox(height: AppSpacing.m),
                                AppTextField(
                                  label: 'author_reader_bio'.tr,
                                  controller: controller.bioController,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: AppSpacing.l),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppSecondaryButton(
                                        label: 'cancel'.tr,
                                        onPressed: controller.toggleEdit,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.m),
                                    Expanded(
                                      child: AppPrimaryButton(
                                        label: 'save_changes'.tr,
                                        onPressed: controller.saveProfile,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                AppSecondaryButton(
                                  label: 'edit_profile'.tr,
                                  icon: Icons.edit_outlined,
                                  onPressed: controller.toggleEdit,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Sign Out Button
                  Center(
                    child: TextButton.icon(
                      onPressed: controller.signOut,
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                      ),
                      label: Text(
                        'sign_out_of_account'.tr,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLanguageSelectorCard(BuildContext context, bool isUrdu) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadii.m),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'app_language'.tr,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'app_language_subtitle'.tr,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // Two Selectable Language Option Cards
          Row(
            children: [
              // English Option
              Expanded(
                child: _buildLanguageOption(
                  isSelected: !isUrdu,
                  badge: 'EN',
                  title: 'English',
                  subtitle: isUrdu ? 'پہلے سے طے شدہ' : 'Default Language',
                  onTap: () => controller.changeLanguage(
                    LocalizationService.englishLocale,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              // Urdu Option
              Expanded(
                child: _buildLanguageOption(
                  isSelected: isUrdu,
                  badge: 'اردو',
                  title: 'اردو',
                  subtitle: isUrdu ? 'قومی زبان' : 'Urdu Language',
                  onTap: () => controller.changeLanguage(
                    LocalizationService.urduLocale,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required bool isSelected,
    required String badge,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    badge,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected
                          ? AppColors.textInverse
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: badge == 'اردو' ? 11 : 10,
                    ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
