import 'package:flutter/material.dart';

enum DeviceScreenType { compact, medium, expanded }

class AppBreakpoints {
  AppBreakpoints._();

  static const double compactMax = 599.0;
  static const double mediumMin = 600.0;
  static const double mediumMax = 1023.0;
  static const double expandedMin = 1024.0;

  // Maximum content width for reading to avoid overly wide prose
  static const double maxReaderWidth = 720.0;
  static const double maxFormWidth = 680.0;
  static const double maxCardGridWidth = 1400.0;

  static DeviceScreenType getDeviceType(double width) {
    if (width < mediumMin) return DeviceScreenType.compact;
    if (width <= mediumMax) return DeviceScreenType.medium;
    return DeviceScreenType.expanded;
  }

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mediumMin;

  static bool isMedium(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mediumMin && w <= mediumMax;
  }

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expandedMin;
}
