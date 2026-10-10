import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/responsive/breakpoints.dart';
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

}
