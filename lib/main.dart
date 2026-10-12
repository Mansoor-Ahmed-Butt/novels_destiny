import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/ad_service.dart';
import 'core/localization/localization_service.dart';
import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  debugPrint('App: Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Set Background Message Handler (Required for closed/background app notifications)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 3. Initialize Supabase
  debugPrint('App: Initializing Supabase...');
  await SupabaseService.init();

  // 4. Initialize Firebase Cloud Messaging & Notifications
  debugPrint('App: Initializing FCM Notifications...');
  final notificationService = NotificationService();
  await notificationService.init();

  // 5. Initialize Google Mobile Ads
  debugPrint('App: Initializing Mobile Ads...');
  await AdService().init();

  // 6. Initialize Localization Service
  debugPrint('App: Initializing Localization...');
  final localizationService = await LocalizationService.init();
  Get.put<LocalizationService>(localizationService, permanent: true);

  runApp(const NovelsDestinyApp());
}
