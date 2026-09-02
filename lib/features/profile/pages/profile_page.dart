import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../domain/entities/user_entity.dart';
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxFormWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageHeader(
                    title: 'Account Profile',
                    subtitle: 'Manage your credentials, bio, and active workspace persona',
                    badgeText: user.role.displayName.toUpperCase(),
                  ),

                  // User Info Card
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            user.displayName.isNotEmpty ? user.displayName[0] : 'U',
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
                          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.l),
                        if (user.bio != null && user.bio!.isNotEmpty && !controller.isEditing.value) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadii.m),
                            ),
                            child: Text(
                              user.bio!,
                              style: AppTextStyles.bodyMedium.copyWith(fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.l),
                        ],
                        if (controller.isEditing.value) ...[
                          AppTextField(
                            label: 'Display Name',
                            controller: controller.nameController,
                          ),
                          const SizedBox(height: AppSpacing.m),
                          AppTextField(
                            label: 'Author / Reader Bio',
                            controller: controller.bioController,
                            maxLines: 3,
                          ),
                          const SizedBox(height: AppSpacing.l),
                          Row(
                            children: [
                              Expanded(
                                child: AppSecondaryButton(
                                  label: 'Cancel',
                                  onPressed: controller.toggleEdit,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(
                                child: AppPrimaryButton(
                                  label: 'Save Changes',
                                  onPressed: controller.saveProfile,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          AppSecondaryButton(
                            label: 'Edit Profile',
                            icon: Icons.edit_outlined,
                            onPressed: controller.toggleEdit,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Quick Role Switcher (Crucial for seamlessly testing all 3 roles!)
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.swap_horiz_rounded, size: 20, color: AppColors.accent),
                            const SizedBox(width: 6),
                            Text(
                              'Switch User Role (Demo Testing)',
                              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Test reader discovering novels, writer drafting chapters, or admin moderating content.',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.l),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleCard(
                                title: 'Reader',
                                description: 'Discover & read stories',
                                isSelected: user.role == UserRole.reader,
                                icon: Icons.auto_stories,
                                onTap: () => controller.switchRole(UserRole.reader),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Expanded(
                              child: _buildRoleCard(
                                title: 'Writer',
                                description: 'Draft novels & episodes',
                                isSelected: user.role == UserRole.writer,
                                icon: Icons.edit_note,
                                onTap: () => controller.switchRole(UserRole.writer),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Expanded(
                              child: _buildRoleCard(
                                title: 'Admin',
                                description: 'Moderate & see analytics',
                                isSelected: user.role == UserRole.admin,
                                icon: Icons.admin_panel_settings,
                                onTap: () => controller.switchRole(UserRole.admin),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Sign Out Button
                  Center(
                    child: TextButton.icon(
                      onPressed: controller.signOut,
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                      label: Text(
                        'Sign Out of Account',
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
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

  Widget _buildRoleCard({
    required String title,
    required String description,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.m),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceMuted : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.m),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(fontSize: 10, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
