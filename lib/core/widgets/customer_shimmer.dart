import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/theme/app_theme.dart';
import '../responsive/breakpoints.dart';

/// A fully responsive Shimmer widget for skeleton loading states across all
/// screen sizes (compact mobile, tablet, and desktop).
///
/// Features:
/// - Fully responsive sizing: uses [FractionallySizedBox], [AspectRatio], and flexible
///   width factors to prevent overflow on narrow screens and adapt smoothly to tablets.
/// - Automatically switches base and highlight colors between Light and Dark mode.
/// - Stops animation ticker completely when [enabled] is false for top performance.
/// - Single-shimmer list and grid wrappers to avoid multi-ticker performance degradation.
class CustomerShimmer extends StatelessWidget {
  /// The skeleton placeholder child widget.
  final Widget child;

  /// Whether the shimmer animation is active.
  /// When set to false, [child] is rendered statically without animation overhead.
  final bool enabled;

  /// Base color of the shimmer gradient. Defaults to theme-aware colors.
  final Color? baseColor;

  /// Highlight color passing over the base color.
  final Color? highlightColor;

  /// Optional custom gradient (e.g. LinearGradient, RadialGradient).
  final Gradient? gradient;

  /// Direction of the shimmer animation (default: left-to-right).
  final ShimmerDirection direction;

  /// Duration of one complete shimmer cycle.
  final Duration period;

  /// Number of loops before stopping (0 = loops infinitely).
  final int loop;

  const CustomerShimmer({
    super.key,
    required this.child,
    this.enabled = true,
    this.baseColor,
    this.highlightColor,
    this.gradient,
    this.direction = ShimmerDirection.ltr,
    this.period = const Duration(milliseconds: 1500),
    this.loop = 0,
  });

  /// Responsive placeholder box.
  ///
  /// If [widthFactor] is provided (e.g. 0.8 for 80%), it automatically adapts to
  /// the parent width instead of using a rigid pixel dimension.
  factory CustomerShimmer.box({
    Key? key,
    double? width,
    double? widthFactor,
    double? height,
    double borderRadius = AppRadii.s,
    EdgeInsetsGeometry? margin,
    Color? baseColor,
    Color? highlightColor,
    BoxShape shape = BoxShape.rectangle,
  }) {
    Widget box = Container(
      width: widthFactor != null ? null : width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(borderRadius),
      ),
    );

    if (widthFactor != null) {
      box = FractionallySizedBox(
        widthFactor: widthFactor.clamp(0.0, 1.0),
        alignment: Alignment.centerLeft,
        child: box,
      );
    }

    return CustomerShimmer(
      key: key,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: box,
    );
  }

  /// Circular shimmer placeholder for avatars or circular action buttons.
  factory CustomerShimmer.circle({
    Key? key,
    double size = 48.0,
    EdgeInsetsGeometry? margin,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return CustomerShimmer.box(
      key: key,
      width: size,
      height: size,
      shape: BoxShape.circle,
      margin: margin,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }

  /// Responsive text line placeholder.
  ///
  /// [widthFactor] (default 1.0) lets lines scale proportionally to whatever
  /// screen or container width is available (e.g. 0.9 for title, 0.6 for subtitle),
  /// completely avoiding fixed-width overflow on smaller mobile screens.
  factory CustomerShimmer.textLine({
    Key? key,
    double? width,
    double widthFactor = 1.0,
    double height = 14.0,
    double borderRadius = AppRadii.xs,
    EdgeInsetsGeometry? margin,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return CustomerShimmer.box(
      key: key,
      width: width,
      widthFactor: width != null ? null : widthFactor,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }

  /// Responsive list tile placeholder (avatar + 2 flexible text lines).
  ///
  /// Uses proportional width factors (90% and 55%) so it seamlessly fits
  /// screen sizes from 320px compact phones to widescreen tablets.
  factory CustomerShimmer.listTile({
    Key? key,
    double leadingSize = 44.0,
    bool hasLeading = true,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.m,
      vertical: AppSpacing.s,
    ),
    Color? baseColor,
    Color? highlightColor,
  }) {
    return CustomerShimmer(
      key: key,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (hasLeading) ...[
              Container(
                width: leadingSize,
                height: leadingSize,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title line (85% width)
                  FractionallySizedBox(
                    widthFactor: 0.85,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 14.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  // Subtitle line (55% width)
                  FractionallySizedBox(
                    widthFactor: 0.55,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Responsive Novel Card placeholder tailored for Novels Destiny.
  ///
  /// Fits automatically inside [GridView], [Expanded], or [Row].
  /// When [width] is null, it adapts flexibly to parent constraints using
  /// standard book cover aspect ratio (2:3), completely eliminating fixed-width
  /// overflows.
  factory CustomerShimmer.novelCard({
    Key? key,
    double? width,
    double? coverHeight,
    double aspectRatio = 2 / 3,
    Color? baseColor,
    Color? highlightColor,
  }) {
    final Widget coverWidget = coverHeight != null
        ? Container(
            height: coverHeight,
            width: width ?? double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.m),
            ),
          )
        : AspectRatio(
            aspectRatio: aspectRatio,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.m),
              ),
            ),
          );

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        coverWidget,
        const SizedBox(height: AppSpacing.s),
        // Title placeholder (proportional 85% width)
        FractionallySizedBox(
          widthFactor: 0.85,
          alignment: Alignment.centerLeft,
          child: Container(
            height: 13.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Author/genre placeholder (proportional 55% width)
        FractionallySizedBox(
          widthFactor: 0.55,
          alignment: Alignment.centerLeft,
          child: Container(
            height: 11.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
          ),
        ),
      ],
    );

    return CustomerShimmer(
      key: key,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: width != null ? SizedBox(width: width, child: cardContent) : cardContent,
    );
  }

  /// Wraps a list of skeleton items in a single Shimmer for optimal 60fps performance.
  static Widget list({
    Key? key,
    int itemCount = 6,
    required Widget Function(BuildContext context, int index) itemBuilder,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.m),
    Widget? separator,
    Color? baseColor,
    Color? highlightColor,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
    bool shrinkWrap = true,
  }) {
    return CustomerShimmer(
      key: key,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.separated(
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemCount: itemCount,
        separatorBuilder: (_, _) =>
            separator ?? const SizedBox(height: AppSpacing.m),
        itemBuilder: itemBuilder,
      ),
    );
  }

  /// Wraps a grid of skeleton items in a single Shimmer for optimal performance.
  static Widget grid({
    Key? key,
    int itemCount = 6,
    required SliverGridDelegate gridDelegate,
    required Widget Function(BuildContext context, int index) itemBuilder,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.m),
    Color? baseColor,
    Color? highlightColor,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
    bool shrinkWrap = true,
  }) {
    return CustomerShimmer(
      key: key,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: GridView.builder(
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemCount: itemCount,
        gridDelegate: gridDelegate,
        itemBuilder: itemBuilder,
      ),
    );
  }

  /// Responsive novel card grid that automatically determines the optimal
  /// column count based on screen width breakpoints (Compact: 2, Medium: 3-4, Expanded: 5-6).
  static Widget responsiveNovelGrid({
    Key? key,
    required BuildContext context,
    int? itemCount,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.m),
    double crossAxisSpacing = AppSpacing.m,
    double mainAxisSpacing = AppSpacing.m,
    double childAspectRatio = 0.58,
    Color? baseColor,
    Color? highlightColor,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final device = AppBreakpoints.getDeviceType(width);

    final crossAxisCount = switch (device) {
      DeviceScreenType.compact => width < 360 ? 2 : 2,
      DeviceScreenType.medium => 4,
      DeviceScreenType.expanded => 6,
    };

    final count = itemCount ?? (crossAxisCount * 2);

    return grid(
      key: key,
      itemCount: count,
      padding: padding,
      baseColor: baseColor,
      highlightColor: highlightColor,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (ctx, _) => CustomerShimmer.novelCard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-tailored base and highlight colors
    final effectiveBaseColor = baseColor ??
        (isDark
            ? const Color(0xFF2D2520)
            : AppColors.surfaceMuted);

    final effectiveHighlightColor = highlightColor ??
        (isDark
            ? const Color(0xFF453C35)
            : AppColors.surfaceHighlight);

    if (gradient != null) {
      return Shimmer(
        gradient: gradient!,
        direction: direction,
        period: period,
        loop: loop,
        enabled: enabled,
        child: child,
      );
    }

    return Shimmer.fromColors(
      baseColor: effectiveBaseColor,
      highlightColor: effectiveHighlightColor,
      direction: direction,
      period: period,
      loop: loop,
      enabled: enabled,
      child: child,
    );
  }
}

/// A responsive solid building block for constructing complex custom skeleton layouts
/// inside a [CustomerShimmer].
class CustomerShimmerBox extends StatelessWidget {
  final double? width;
  final double? widthFactor;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final BoxShape shape;
  final Color color;

  const CustomerShimmerBox({
    super.key,
    this.width,
    this.widthFactor,
    this.height,
    this.borderRadius = AppRadii.s,
    this.margin,
    this.shape = BoxShape.rectangle,
    this.color = Colors.white,
  });

  /// Circular shape constructor
  const CustomerShimmerBox.circle({
    super.key,
    required double size,
    this.margin,
    this.color = Colors.white,
  })  : width = size,
        widthFactor = null,
        height = size,
        borderRadius = 0,
        shape = BoxShape.circle;

  /// Responsive text line constructor
  const CustomerShimmerBox.line({
    super.key,
    this.width,
    this.widthFactor = 1.0,
    this.height = 14.0,
    this.borderRadius = AppRadii.xs,
    this.margin,
    this.color = Colors.white,
  })  : shape = BoxShape.rectangle;

  @override
  Widget build(BuildContext context) {
    Widget box = Container(
      width: widthFactor != null ? null : width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
      ),
    );

    if (widthFactor != null) {
      return FractionallySizedBox(
        widthFactor: widthFactor!.clamp(0.0, 1.0),
        alignment: Alignment.centerLeft,
        child: box,
      );
    }

    return box;
  }
}

/// Convenience alias for [CustomerShimmer].
typedef CustomShimmer = CustomerShimmer;

/// Convenience alias for [CustomerShimmerBox].
typedef CustomShimmerBox = CustomerShimmerBox;
