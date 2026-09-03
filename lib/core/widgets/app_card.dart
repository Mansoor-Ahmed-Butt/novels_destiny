import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool hasShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.onTap,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius ?? AppRadii.card);

    Widget card = Material(
      color: backgroundColor ?? AppColors.card,
      borderRadius: radius,
      child: Container(
        margin: margin,
        padding: padding ?? const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: borderColor ?? AppColors.cardBorder,
            width: 1.0,
          ),
          boxShadow: hasShadow ? AppShadows.card : null,
        ),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: card,
      );
    }
    return card;
  }
}
