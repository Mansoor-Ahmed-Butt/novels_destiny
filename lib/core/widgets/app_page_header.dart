import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import 'app_buttons.dart';

class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? badgeText;
  final Widget? trailing;
  final VoidCallback? onBack;

  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.l),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null) ...[
            AppIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: onBack,
              size: 38,
            ),
            const SizedBox(width: AppSpacing.m),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: AppSpacing.s),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          border: Border.all(color: AppColors.cardBorder.withOpacity(0.6)),
                        ),
                        child: Text(
                          badgeText!,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
