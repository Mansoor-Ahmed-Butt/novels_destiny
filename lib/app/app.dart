import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'bindings/initial_binding.dart';
import '../core/constants/app_constants.dart';
import '../core/localization/app_translations.dart';
import '../core/localization/localization_service.dart';

class NovelsDestinyApp extends StatelessWidget {
  const NovelsDestinyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = Get.isRegistered<LocalizationService>()
        ? LocalizationService.to.currentLocale
        : LocalizationService.englishLocale;

    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      translations: AppTranslations(),
      locale: currentLocale,
      fallbackLocale: LocalizationService.fallbackLocale,
      supportedLocales: LocalizationService.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}
