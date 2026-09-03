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
  bool isAdminMode = false;

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
                    color: isAdminMode ? AppColors.accent : AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    boxShadow: AppShadows.card,
                  ),
                  child: Icon(
                    isAdminMode ? Icons.admin_panel_settings : Icons.auto_stories,
                    color: AppColors.textInverse,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                Text(
                  isAdminMode ? 'Admin Portal' : 'Novels Destiny',
                  style: AppTextStyles.displayMedium.copyWith(letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  isSignUp
                      ? 'Join our community of storytellers'
                      : isAdminMode
                          ? 'Sign in to access platform administration & moderation'
                          : 'Sign in to access your library & studio',
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
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
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

                        // Admin Portal Access Switch (Only on Sign In)
                        if (!isSignUp) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 10),
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
                                  isAdminMode ? Icons.admin_panel_settings : Icons.shield_outlined,
                                  size: 22,
                                  color: isAdminMode ? AppColors.accent : AppColors.textTertiary,
                                ),
                                const SizedBox(width: AppSpacing.m),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Admin Mode Access',
                                        style: AppTextStyles.labelMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isAdminMode ? AppColors.accent : AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        isAdminMode
                                            ? 'Administrator credentials enabled'
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
                                  activeColor: AppColors.accent,
                                  onChanged: (val) {
                                    setState(() {
                                      isAdminMode = val;
                                      if (isAdminMode) {
                                        emailController.text = 'admin@novelsdestiny.com';
                                        passwordController.text = 'secret123';
                                      } else {
                                        emailController.text = 'aria.reader@destiny.com';
                                        passwordController.text = 'secret123';
                                      }
                                    });
                                  },
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
                          label: isSignUp
                              ? (selectedRole == UserRole.writer ? 'Submit Writer Application' : 'Create Reader Account')
                              : (isAdminMode ? 'Sign In to Admin Portal' : 'Sign In'),
                          isLoading: isLoading,
                          onPressed: () {
                            if (isSignUp) {
                              controller.signUp(
                                emailController.text.trim(),
                                passwordController.text.trim(),
                                nameController.text.isEmpty
                                    ? (selectedRole == UserRole.writer ? 'New Writer' : 'Reader')
                                    : nameController.text.trim(),
                                selectedRole,
                              );
                            } else {
                              controller.signIn(
                                emailController.text.trim(),
                                passwordController.text.trim(),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Google Sign In (Reader Default)
                        if (!isSignUp && !isAdminMode) ...[
                          OutlinedButton(
                            onPressed: isLoading ? null : () => controller.signInWithGoogle(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadii.m),
                              ),
                              side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
                              backgroundColor: AppColors.surface,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                        ],

                        TextButton(
                          onPressed: () {
                            setState(() {
                              isSignUp = !isSignUp;
                              if (isSignUp) {
                                isAdminMode = false;
                                emailController.text = '';
                                passwordController.text = '';
                              } else {
                                emailController.text = 'aria.reader@destiny.com';
                                passwordController.text = 'secret123';
                              }
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
                        setState(() => isAdminMode = false);
                        emailController.text = 'aria.reader@destiny.com';
                        passwordController.text = 'secret123';
                        controller.signIn('aria.reader@destiny.com', 'secret123');
                      },
                    ),
                    AppPillBadge(
                      label: 'Writer (Julian)',
                      icon: Icons.edit_note,
                      onTap: () {
                        setState(() => isAdminMode = false);
                        emailController.text = 'julian.author@destiny.com';
                        passwordController.text = 'secret123';
                        controller.signIn('julian.author@destiny.com', 'secret123');
                      },
                    ),
                    AppPillBadge(
                      label: 'Pending Writer (Kaelen)',
                      icon: Icons.hourglass_top_rounded,
                      onTap: () {
                        setState(() => isAdminMode = false);
                        emailController.text = 'kaelen.writer@destiny.com';
                        passwordController.text = 'secret123';
                        controller.signIn('kaelen.writer@destiny.com', 'secret123');
                      },
                    ),
                    AppPillBadge(
                      label: 'Admin (Elena)',
                      icon: Icons.admin_panel_settings,
                      onTap: () {
                        setState(() => isAdminMode = true);
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
