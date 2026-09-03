import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  
  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
    
    await Supabase.initialize(
      url: dotenv.get('SUPABASE_URL'),
      anonKey: dotenv.get('SUPABASE_ANON_KEY'),
    );
  }
}
