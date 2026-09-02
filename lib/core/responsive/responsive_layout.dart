import 'package:flutter/material.dart';
import 'breakpoints.dart';

typedef ResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  DeviceScreenType screenType,
  BoxConstraints constraints,
);

class ResponsiveBuilder extends StatelessWidget {
  final ResponsiveWidgetBuilder builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenType = AppBreakpoints.getDeviceType(constraints.maxWidth);
        return builder(context, screenType, constraints);
      },
    );
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget compact;
  final Widget? medium;
  final Widget? expanded;

  const ResponsiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, constraints) {
        switch (screenType) {
          case DeviceScreenType.expanded:
            return expanded ?? medium ?? compact;
          case DeviceScreenType.medium:
            return medium ?? compact;
          case DeviceScreenType.compact:
            return compact;
        }
      },
    );
  }
}
