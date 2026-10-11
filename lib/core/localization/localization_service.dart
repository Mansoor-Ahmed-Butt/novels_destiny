import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends GetxService {
  static const String _prefKeyLocale = 'app_user_locale_code';

  static const Locale englishLocale = Locale('en', 'US');
  static const Locale urduLocale = Locale('ur', 'PK');

  static const List<Locale> supportedLocales = [
    englishLocale,
    urduLocale,
  ];

  static const Locale fallbackLocale = englishLocale;

  static LocalizationService get to => Get.find<LocalizationService>();

  final Rx<Locale> rxLocale = englishLocale.obs;

  Locale get currentLocale => rxLocale.value;

  bool get isUrdu => rxLocale.value.languageCode == 'ur';

  String get currentLanguageCode => rxLocale.value.languageCode;

  String get currentLanguageDisplayName => isUrdu ? 'اردو' : 'English';

  /// Initial loader for SharedPreferences
  static Future<LocalizationService> init() async {
    final service = LocalizationService();
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKeyLocale);

      if (savedCode != null && savedCode == 'ur') {
        service.rxLocale.value = urduLocale;
      } else {
        service.rxLocale.value = englishLocale;
      }
    } catch (e) {
      debugPrint('LocalizationService init error: $e');
      service.rxLocale.value = englishLocale;
    }

    return service;
  }

  /// Change to a specific Locale
  Future<void> changeLocale(Locale newLocale) async {
    if (rxLocale.value.languageCode == newLocale.languageCode) return;

    rxLocale.value = newLocale;
    await Get.updateLocale(newLocale);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyLocale, newLocale.languageCode);
    } catch (e) {
      debugPrint('LocalizationService save error: $e');
    }
  }

  /// Explicitly switch to Urdu
  Future<void> switchToUrdu() async {
    await changeLocale(urduLocale);
  }

  /// Explicitly switch to English (Default)
  Future<void> switchToEnglish() async {
    await changeLocale(englishLocale);
  }

  /// Toggle between English and Urdu
  Future<void> toggleLocale() async {
    if (isUrdu) {
      await switchToEnglish();
    } else {
      await switchToUrdu();
    }
  }
}
