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

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final AuthController controller = Get.find<AuthController>();
  bool isSignUp = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController(text: 'aria.reader@destiny.com');
  final TextEditingController passwordController = TextEditingController(text: 'secret123');
  UserRole selectedRole = UserRole.reader;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    boxShadow: AppShadows.card,
                  ),
                  child: const Icon(Icons.auto_stories, color: AppColors.textInverse, size: 28),
                ),
                const SizedBox(height: AppSpacing.l),
                Text(
                  'Novels Destiny',
                  style: AppTextStyles.displayMedium.copyWith(letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  isSignUp ? 'Join our community of storytellers' : 'Sign in to access your library & studio',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Form Card
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Obx(() {
                    final state = controller.state.value;
                    final isLoading = state is AuthLoading;
                    final errorMessage = state is AuthFailureState ? state.message : null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight,
                              borderRadius: BorderRadius.circular(AppRadii.m),
                              border: Border.all(color: AppColors.error.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                                const SizedBox(width: AppSpacing.s),
                                Expanded(
                                  child: Text(
                                    errorMessage,
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                                  ),
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
                            controller: nameController,
                            prefixIcon: const Icon(Icons.person_outline, size: 20),
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
                                      isSelected: selectedRole == UserRole.reader,
                                      onTap: () => setState(() => selectedRole = UserRole.reader),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s),
                                  Expanded(
                                    child: _RoleChip(
                                      title: 'Writer',
                                      isSelected: selectedRole == UserRole.writer,
                                      onTap: () => setState(() => selectedRole = UserRole.writer),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.m),
                        ],
                        AppTextField(
                          label: 'Email',
                          hint: 'your.email@example.com',
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.mail_outline, size: 20),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        AppTextField(
                          label: 'Password',
                          hint: '••••••••',
                          controller: passwordController,
                          isPassword: true,
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppPrimaryButton(
                          label: isSignUp ? 'Create Account' : 'Sign In',
                          isLoading: isLoading,
                          onPressed: () {
                            if (isSignUp) {
                              controller.signUp(
                                emailController.text,
                                passwordController.text,
                                nameController.text.isEmpty ? 'Reader' : nameController.text,
                                selectedRole,
                              );
                            } else {
                              controller.signIn(
                                emailController.text,
                                passwordController.text,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.m),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              isSignUp = !isSignUp;
                            });
                          },
                          child: Text(
                            isSignUp
                                ? 'Already have an account? Sign In'
                                : 'Don\'t have an account? Create one',
                            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    );
                  }),
                ),

                const SizedBox(height: AppSpacing.xl),
                // Quick Demo Logins
                Text(
                  'Quick Demo One-Click Access',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                ),
                const SizedBox(height: AppSpacing.s),
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  alignment: WrapAlignment.center,
                  children: [
                    AppPillBadge(
                      label: 'Reader (Aria)',
                      icon: Icons.auto_stories,
                      onTap: () {
                        emailController.text = 'aria.reader@destiny.com';
                        passwordController.text = 'secret123';
                        controller.signIn('aria.reader@destiny.com', 'secret123');
                      },
                    ),
                    AppPillBadge(
                      label: 'Writer (Julian)',
                      icon: Icons.edit_note,
                      onTap: () {
                        emailController.text = 'julian.author@destiny.com';
                        passwordController.text = 'secret123';
                        controller.signIn('julian.author@destiny.com', 'secret123');
                      },
                    ),
                    AppPillBadge(
                      label: 'Admin (Elena)',
                      icon: Icons.admin_panel_settings,
                      onTap: () {
                        emailController.text = 'admin@novelsdestiny.com';
                        passwordController.text = 'secret123';
                        controller.signIn('admin@novelsdestiny.com', 'secret123');
                      },
                    ),
                  ],
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
