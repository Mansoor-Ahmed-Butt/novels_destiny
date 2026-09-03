import 'package:flutter/material.dart';
import 'package:novels_destiny/core/services/supabase_service.dart';
import 'app/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   // Initialize Supabase
  debugPrint('App: Initializing Supabase...');
  await SupabaseService.init();
  runApp(const NovelsDestinyApp());
}
