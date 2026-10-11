import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum DictationLanguage {
  english(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    defaultLocale: 'en_US',
  ),
  urdu(
    code: 'ur',
    name: 'Urdu',
    nativeName: 'اردو',
    defaultLocale: 'ur_PK',
  );

  final String code;
  final String name;
  final String nativeName;
  final String defaultLocale;

  const DictationLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.defaultLocale,
  });
}

class SpeechRecognitionService {
  static final SpeechRecognitionService _instance = SpeechRecognitionService._internal();
  factory SpeechRecognitionService() => _instance;
  SpeechRecognitionService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isAvailable = false;
  ValueChanged<String>? _statusListener;

  bool get isListening => _speech.isListening;
  bool get isAvailable => _isAvailable;

  void setStatusListener(ValueChanged<String>? listener) {
    _statusListener = listener;
  }

  Future<bool> initialize() async {
    if (_isInitialized) return _isAvailable;
    try {
      _isAvailable = await _speech.initialize(
        onError: (err) {
          debugPrint('SpeechRecognition error: ${err.errorMsg} (permanent: ${err.permanent})');
        },
        onStatus: (status) {
          debugPrint('SpeechRecognition status: $status');
          _statusListener?.call(status);
        },
      );
      _isInitialized = true;
      return _isAvailable;
    } catch (e) {
      debugPrint('SpeechRecognition init error: $e');
      _isInitialized = true;
      _isAvailable = false;
      return false;
    }
  }

  Future<String> resolveLocaleId(DictationLanguage language) async {
    try {
      final available = await initialize();
      if (!available) return language.defaultLocale;
      final locales = await _speech.locales();
      if (locales.isEmpty) return language.defaultLocale;

      // Look for exact code match (e.g. 'ur_PK', 'ur-PK', or 'en_US', 'en-US')
      for (final l in locales) {
        final id = l.localeId.toLowerCase().replaceAll('-', '_');
        final target = language.defaultLocale.toLowerCase().replaceAll('-', '_');
        if (id == target) {
          return l.localeId;
        }
      }

      // Look for language prefix match (e.g. 'ur', 'en')
      for (final l in locales) {
        final id = l.localeId.toLowerCase();
        if (id.startsWith(language.code)) {
          return l.localeId;
        }
      }

      return language.defaultLocale;
    } catch (_) {
      return language.defaultLocale;
    }
  }

  Future<bool> startListening({
    required Function(String recognizedWords, bool isFinal) onResult,
    DictationLanguage language = DictationLanguage.english,
    VoidCallback? onListeningStopped,
  }) async {
    try {
      final available = await initialize();
      if (!available) {
        return false;
      }

      final resolvedLocale = await resolveLocaleId(language);
      debugPrint('SpeechRecognition startListening with locale: $resolvedLocale for ${language.name}');

      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: resolvedLocale,
          listenFor: const Duration(minutes: 15),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('SpeechRecognition startListening error: $e');
      return false;
    }
  }

  Future<void> stopListening() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      debugPrint('SpeechRecognition stop error: $e');
    }
  }
}
