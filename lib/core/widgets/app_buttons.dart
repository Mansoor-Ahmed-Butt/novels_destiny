import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primary,
        foregroundColor: foregroundColor ?? AppColors.textInverse,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.m,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        disabledBackgroundColor: AppColors.surfaceMuted,
      ),
      child: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: AppSpacing.s),
                ],
                Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: foregroundColor ?? AppColors.textInverse,
                  ),
                ),
              ],
            ),
    );

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: btn);
    }
    return btn;
  }
}

class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isExpanded;
  final Color? borderColor;

  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isExpanded = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final btn = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(
          color: borderColor ?? AppColors.cardBorder,
          width: 1.2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        backgroundColor: AppColors.card,
      ),
      child: Row(
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: AppSpacing.s),
          ],
          Text(
            label,
            style: AppTextStyles.labelLarge,
          ),
        ],
      ),
    );

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: btn);
    }
    return btn;
  }
}

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.iconColor,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cardBorder.withOpacity(0.6)),
        ),
        child: Center(
          child: Icon(
            icon,
            size: size * 0.5,
            color: iconColor ?? AppColors.textPrimary,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

class AppPillBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const AppPillBadge({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor ?? AppColors.textSecondary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: textColor ?? AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: content,
      );
    }
    return content;
  }
}
