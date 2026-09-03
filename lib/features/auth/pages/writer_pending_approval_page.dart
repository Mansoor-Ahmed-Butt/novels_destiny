import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../domain/entities/user_entity.dart';
import '../controllers/auth_controller.dart';

class WriterPendingApprovalPage extends StatelessWidget {
  const WriterPendingApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return AppScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l,
            vertical: AppSpacing.xxl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Obx(() {
              final user = authController.currentUser.value;
              final displayName = user?.displayName ?? 'Author';
              final email = user?.email ?? 'author@destiny.com';
              final isApproved = user?.approvalStatus == ApprovalStatus.approved;
              final isRejected = user?.approvalStatus == ApprovalStatus.rejected;

              final statusColor = isRejected
                  ? AppColors.error
                  : isApproved
                      ? AppColors.success
                      : AppColors.warning;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Icon Header
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isRejected
                            ? Icons.cancel_outlined
                            : isApproved
                                ? Icons.verified_rounded
                                : Icons.hourglass_top_rounded,
                        color: statusColor,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // Title & Subtitle
                  Text(
                    isRejected
                        ? 'Application Update'
                        : isApproved
                            ? 'Congratulations, $displayName!'
                            : 'Application Under Review',
                    style: AppTextStyles.displayMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    isRejected
                        ? 'Your writer application was not approved at this time. You can continue reading as a reader.'
                        : isApproved
                            ? 'Your writer account has been approved by the editorial team. You can now access the Writer Studio!'
                            : 'Thank you for applying to become a verified author on Novels Destiny. Your profile is currently under editorial review.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Main Status Card
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Application Status',
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.m,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppRadii.pill),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    user?.approvalStatus.displayName.toUpperCase() ?? 'PENDING REVIEW',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: statusColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.l),

                        _buildApplicantDetailRow(
                          icon: Icons.person_outline,
                          label: 'Pen Name',
                          value: displayName,
                        ),
                        const SizedBox(height: AppSpacing.m),
                        _buildApplicantDetailRow(
                          icon: Icons.mail_outline,
                          label: 'Account Email',
                          value: email,
                        ),
                        const SizedBox(height: AppSpacing.m),
                        _buildApplicantDetailRow(
                          icon: Icons.assignment_outlined,
                          label: 'Target Role',
                          value: 'Writer / Novelist',
                        ),
                        const SizedBox(height: AppSpacing.m),
                        _buildApplicantDetailRow(
                          icon: Icons.access_time_rounded,
                          label: 'Estimated Review',
                          value: 'Within 24 - 48 Hours',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // What Happens Next Card
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                            const SizedBox(width: AppSpacing.s),
                            Text(
                              'What happens next?',
                              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.m),
                        _buildTimelineStep(
                          step: '1',
                          title: 'Editorial Verification',
                          desc: 'Our admin team reviews novel guidelines and verifies new creators.',
                          isCompleted: true,
                        ),
                        const SizedBox(height: AppSpacing.s),
                        _buildTimelineStep(
                          step: '2',
                          title: 'Admin Approval & Notification',
                          desc: 'Once approved, your studio access and publishing rights are unlocked.',
                          isCompleted: isApproved,
                        ),
                        const SizedBox(height: AppSpacing.s),
                        _buildTimelineStep(
                          step: '3',
                          title: 'Publish & Earn',
                          desc: 'Create series, publish episodes, and engage with your readers.',
                          isCompleted: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Action Buttons
                  if (isApproved)
                    AppPrimaryButton(
                      label: 'Enter Writer Studio',
                      icon: Icons.rocket_launch_rounded,
                      onPressed: () => authController.enterApprovedWriterStudio(),
                    )
                  else
                    AppPrimaryButton(
                      label: 'Check Approval Status',
                      icon: Icons.refresh_rounded,
                      onPressed: () => authController.checkWriterApprovalStatus(),
                    ),
                  const SizedBox(height: AppSpacing.m),

                  // Simulation Button for Testing
                  if (!isApproved) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        if (user != null) {
                          authController.simulateAdminApproval(user.id);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.m),
                        ),
                        side: const BorderSide(color: AppColors.accent, width: 1.2),
                      ),
                      icon: const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 18),
                      label: Text(
                        'Demo Testing: Instant Admin Approve',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                  ],

                  // Sign Out Button
                  Center(
                    child: TextButton.icon(
                      onPressed: () => authController.signOut(),
                      icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.textTertiary),
                      label: Text(
                        'Sign Out / Back to Login',
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicantDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.s),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String step,
    required String title,
    required String desc,
    required bool isCompleted,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.success : AppColors.surface,
            border: Border.all(
              color: isCompleted ? AppColors.success : AppColors.cardBorder,
              width: 1.5,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: AppColors.textInverse)
                : Text(
                    step,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
