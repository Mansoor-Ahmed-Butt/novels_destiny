import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'bindings/initial_binding.dart';
import '../core/constants/app_constants.dart';

class NovelsDestinyApp extends StatelessWidget {
  const NovelsDestinyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}
