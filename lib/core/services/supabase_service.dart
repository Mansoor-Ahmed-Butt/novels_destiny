import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() => _instance;
  SupabaseService._internal();

  /// Returns null if Supabase hasn't been initialized yet (e.g. in unit tests).
  SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
      await Supabase.initialize(
        url: dotenv.get('SUPABASE_URL'),
        // Use publishableKey as anonKey is deprecated in newer SDK
        anonKey: dotenv.get('SUPABASE_ANON_KEY'),
      );
    } catch (e) {
      debugPrint('Supabase init warning: $e');
    }
  }
}
