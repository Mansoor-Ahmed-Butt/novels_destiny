import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/entities/user_entity.dart';
import '../controllers/auth_controller.dart';
import '../states/auth_state.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    return AppScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Brand Header
                Obx(
                  () => Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: controller.isAdminMode.value
                          ? AppColors.accent
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      boxShadow: AppShadows.card,
                    ),
                    child: Icon(
                      controller.isAdminMode.value
                          ? Icons.admin_panel_settings
                          : Icons.auto_stories,
                      color: AppColors.textInverse,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                Obx(
                  () => Text(
                    controller.isAdminMode.value
                        ? 'Admin Portal'
                        : 'Novels Destiny',
                    style: AppTextStyles.displayMedium.copyWith(
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Text(
                    controller.isSignUp.value
                        ? 'Join our community of storytellers'
                        : controller.isAdminMode.value
                        ? 'Sign in to access platform administration & moderation'
                        : 'Sign in to access your library & studio',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Form Card
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Obx(() {
                    final state = controller.state.value;
                    final isSignUp = controller.isSignUp.value;
                    final isAdminMode = controller.isAdminMode.value;
                    final selectedRole = controller.selectedRole.value;
                    final isLoading = state is AuthLoading;
                    final errorMessage = state is AuthFailureState
                        ? state.message
                        : null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight,
                              borderRadius: BorderRadius.circular(AppRadii.m),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: AppSpacing.s),
                                Expanded(
                                  child: Text(
                                    errorMessage,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                        ],

                        // Admin Portal Access Switch (Only on Sign In)
                        if (!isSignUp) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.m,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isAdminMode
                                  ? AppColors.accent.withValues(alpha: 0.08)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadii.m),
                              border: Border.all(
                                color: isAdminMode
                                    ? AppColors.accent.withValues(alpha: 0.35)
                                    : AppColors.cardBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isAdminMode
                                      ? Icons.admin_panel_settings
                                      : Icons.shield_outlined,
                                  size: 22,
                                  color: isAdminMode
                                      ? AppColors.accent
                                      : AppColors.textTertiary,
                                ),
                                const SizedBox(width: AppSpacing.m),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Admin Mode Access',
                                        style: AppTextStyles.labelMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: isAdminMode
                                                  ? AppColors.accent
                                                  : AppColors.textPrimary,
                                            ),
                                      ),
                                      Text(
                                        isAdminMode
                                            ? 'Enter administrator credentials'
                                            : 'Turn ON if logging in as an Admin',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontSize: 11,
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: isAdminMode,
                                  activeTrackColor: AppColors.accent,
                                  onChanged: (val) =>
                                      controller.toggleAdminMode(val),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                        ],

                        if (isSignUp) ...[
                          AppTextField(
                            label: 'Full Name',
                            hint: 'Pen name or author name',
                            controller: controller.nameController,
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                          // Role selector
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'I want to join as',
                                style: AppTextStyles.labelLarge,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  Expanded(
                                    child: _RoleChip(
                                      title: 'Reader',
                                      isSelected:
                                          selectedRole == UserRole.reader,
                                      onTap: () => controller.setSelectedRole(
                                        UserRole.reader,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s),
                                  Expanded(
                                    child: _RoleChip(
                                      title: 'Writer',
                                      isSelected:
                                          selectedRole == UserRole.writer,
                                      onTap: () => controller.setSelectedRole(
                                        UserRole.writer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (selectedRole == UserRole.writer) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Note: Writer accounts undergo admin review before publishing access is unlocked.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.warning,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.m),
                        ],
                        AppTextField(
                          label: 'Email',
                          hint: 'your.email@example.com',
                          controller: controller.emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.mail_outline, size: 20),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        AppTextField(
                          label: 'Password',
                          hint: '••••••••',
                          controller: controller.passwordController,
                          isPassword: true,
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        AppPrimaryButton(
                          label: isSignUp
                              ? (selectedRole == UserRole.writer
                                    ? 'Submit Writer Application'
                                    : 'Create Reader Account')
                              : (isAdminMode
                                    ? 'Sign In to Admin Portal'
                                    : 'Sign In'),
                          isLoading: isLoading,
                          onPressed: () {
                            if (isSignUp) {
                              controller.signUp(
                                controller.emailController.text.trim(),
                                controller.passwordController.text.trim(),
                                controller.nameController.text.isEmpty
                                    ? (selectedRole == UserRole.writer
                                          ? 'New Writer'
                                          : 'Reader')
                                    : controller.nameController.text.trim(),
                                selectedRole,
                              );
                            } else {
                              controller.signIn(
                                controller.emailController.text.trim(),
                                controller.passwordController.text.trim(),
                              );
                            }
                          },
                        ),
                        // Admin-block error message
                        Obx(() {
                          final msg = controller.adminBlockMessage.value;
                          if (msg.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.s),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.block,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    msg,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: AppSpacing.m),

                        // Google Sign In (Reader)
                        if (!isAdminMode) ...[
                          Obx(() {
                            final googleLoading =
                                controller.isGoogleLoading.value;
                            return OutlinedButton(
                              onPressed: (isLoading || googleLoading)
                                  ? null
                                  : () => controller.signInWithGoogle(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.m,
                                  ),
                                ),
                                side: const BorderSide(
                                  color: AppColors.cardBorder,
                                  width: 1.2,
                                ),
                                backgroundColor: AppColors.surface,
                              ),
                              child: googleLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.textSecondary,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'G',
                                              style: TextStyle(
                                                color: Color(0xFF4285F4),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                                fontFamily: 'sans-serif',
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.s),
                                        Text(
                                          'Sign in with Google',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                        ),
                                      ],
                                    ),
                            );
                          }),
                          const SizedBox(height: AppSpacing.m),
                        ],

                        TextButton(
                          onPressed: () => controller.toggleSignUpMode(),
                          child: Text(
                            isSignUp
                                ? 'Already have an account? Sign In'
                                : 'Don\'t have an account? Create one',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.m),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.m),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: isSelected ? AppColors.textInverse : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
