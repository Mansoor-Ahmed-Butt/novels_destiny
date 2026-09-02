import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_theme.dart';
import 'app_buttons.dart';

class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final VoidCallback onConfirm;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    required this.onConfirm,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    required VoidCallback onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppSecondaryButton(
                  label: cancelLabel,
                  onPressed: () => Get.back(result: false),
                ),
                const SizedBox(width: AppSpacing.m),
                AppPrimaryButton(
                  label: confirmLabel,
                  backgroundColor: isDestructive ? AppColors.error : AppColors.primary,
                  onPressed: () {
                    Get.back(result: true);
                    onConfirm();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
