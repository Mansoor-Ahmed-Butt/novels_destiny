import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import 'app_card.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      backgroundColor: backgroundColor ?? AppColors.card,
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor ?? AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            value,
            style: AppTextStyles.displayMedium.copyWith(
              fontSize: 24,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class SummaryHeroCard extends StatelessWidget {
  final String mainLabel;
  final String mainValue;
  final String? unit;
  final List<SummarySubMetric> subMetrics;
  final VoidCallback? onNotificationTap;

  const SummaryHeroCard({
    super.key,
    required this.mainLabel,
    required this.mainValue,
    this.unit,
    this.subMetrics = const [],
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_stories_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    mainLabel,
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              if (onNotificationTap != null)
                InkWell(
                  onTap: onNotificationTap,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none_rounded, size: 18, color: AppColors.textPrimary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                mainValue,
                style: AppTextStyles.displayLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 6),
                Text(
                  unit!,
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
          if (subMetrics.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            Row(
              children: subMetrics
                  .map(
                    (m) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: AppSpacing.s),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(AppRadii.m),
                          border: Border.all(color: AppColors.cardBorder.withOpacity(0.6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.label,
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.value,
                              style: AppTextStyles.titleSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class SummarySubMetric {
  final String label;
  final String value;

  const SummarySubMetric({required this.label, required this.value});
}
