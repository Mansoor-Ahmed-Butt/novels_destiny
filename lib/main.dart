import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/ad_service.dart';
import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  debugPrint('App: Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Initialize Supabase
  debugPrint('App: Initializing Supabase...');
  await SupabaseService.init();

  // 3. Initialize Firebase Cloud Messaging
  debugPrint('App: Initializing FCM Notifications...');
  final notificationService = NotificationService();
  await notificationService.init();

  // 4. Initialize Google Mobile Ads
  debugPrint('App: Initializing Mobile Ads...');
  await AdService().init();

  runApp(const NovelsDestinyApp());

  // Check if app was launched via notification tap
  notificationService.handlePendingLaunchNotification();
}
