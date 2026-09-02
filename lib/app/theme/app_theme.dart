import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFFF8F4EC); // Soft ivory cream
  static const Color backgroundLight = Color(0xFFFCFAF7);
  static const Color surface = Color(0xFFEFEAE0); // Warm light beige panel
  static const Color surfaceMuted = Color(0xFFE7DFD2); // Darker beige container
  static const Color surfaceHighlight = Color(0xFFF3EFE6);
  static const Color card = Color(0xFFF5F1E8);
  static const Color cardBorder = Color(0xFFE5DDD0);

  // Brand & Actions
  static const Color primary = Color(0xFF342217); // Deep warm espresso brown
  static const Color primaryDark = Color(0xFF23160F);
  static const Color primaryLight = Color(0xFF533B2E);
  static const Color accent = Color(0xFFC47B49); // Warm terracotta amber
  static const Color accentLight = Color(0xFFE8DFC8); // Soft badge caramel

  // Text colors
  static const Color textPrimary = Color(0xFF2C2018); // Deep warm charcoal
  static const Color textSecondary = Color(0xFF75675A); // Muted brown-gray
  static const Color textTertiary = Color(0xFF9E9184); // Light brown-gray
  static const Color textInverse = Color(0xFFFAF7F2); // Off-white cream

  // Status & Feedback
  static const Color success = Color(0xFF3E7B54); // Editorial Forest Sage
  static const Color successLight = Color(0xFFE4EFE7);
  static const Color warning = Color(0xFFC78426); // Warm Ochre
  static const Color warningLight = Color(0xFFFBF2DE);
  static const Color error = Color(0xFFB33A3A); // Deep Crimson
  static const Color errorLight = Color(0xFFF9E7E7);
  static const Color info = Color(0xFF436E8B); // Slate Teal
  static const Color infoLight = Color(0xFFE5EFF5);

  // Reader Themes
  static const Color readerCreamBg = Color(0xFFF9F5EC);
  static const Color readerCreamText = Color(0xFF2C2219);

  static const Color readerParchmentBg = Color(0xFFECE4D0);
  static const Color readerParchmentText = Color(0xFF34261B);

  static const Color readerDarkBg = Color(0xFF1E1A17);
  static const Color readerDarkText = Color(0xFFE2DAD1);

  static const Color readerWhiteBg = Color(0xFFFFFFFF);
  static const Color readerWhiteText = Color(0xFF1F1D1B);
}

class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double sm = 12.0;
  static const double m = 16.0;
  static const double l = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}

class AppRadii {
  AppRadii._();

  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 12.0;
  static const double card = 16.0;
  static const double l = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double pill = 999.0;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF2C2018).withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardHover => [
        BoxShadow(
          color: const Color(0xFF2C2018).withOpacity(0.08),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get floating => [
        BoxShadow(
          color: const Color(0xFF2C2018).withOpacity(0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: const Color(0xFF2C2018).withOpacity(0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
}

class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

class AppTextStyles {
  AppTextStyles._();

  // Display & Titles (UI Sans)
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleSmall => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // Body text
  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.45,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
      );

  // Label & Badges
  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      );

  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
      );

  // Reader body (Serif)
  static TextStyle readerBody({
    double fontSize = 17.0,
    double height = 1.7,
    Color color = AppColors.readerCreamText,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.merriweather(
      fontSize: fontSize,
      height: height,
      color: color,
      fontWeight: fontWeight,
    );
  }

  // Reader Heading (Serif)
  static TextStyle readerHeading({
    double fontSize = 24.0,
    Color color = AppColors.readerCreamText,
  }) {
    return GoogleFonts.merriweather(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.3,
    );
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textInverse,
        secondary: AppColors.accent,
        onSecondary: AppColors.textInverse,
        surface: AppColors.card,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
