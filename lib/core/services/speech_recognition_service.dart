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

class SpeechStartResult {
  final bool success;
  final String? message;
  final String? detailedHelp;

  const SpeechStartResult({
    required this.success,
    this.message,
    this.detailedHelp,
  });
}

class SpeechRecognitionService {
  static final SpeechRecognitionService _instance =
      SpeechRecognitionService._internal();
  factory SpeechRecognitionService() => _instance;
  SpeechRecognitionService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isAvailable = false;
  ValueChanged<String>? _statusListener;

  bool get isListening => _speech.isListening;
  bool get isAvailable => _isAvailable;

  bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  bool isLanguageSupportedOnPlatform(DictationLanguage language) {
    if (isWindows) {
      // Windows SAPI natively supports English (en-US, en-GB).
      // Urdu is not supported by native Windows Speech API.
      return language == DictationLanguage.english;
    }
    // Android and iOS mobile devices support both English and Urdu out of the box.
    return true;
  }

  void setStatusListener(ValueChanged<String>? listener) {
    _statusListener = listener;
  }

  Future<bool> initialize({bool forceRetry = false}) async {
    if (_isInitialized && _isAvailable && !forceRetry) return _isAvailable;

    try {
      _isAvailable = await _speech.initialize(
        debugLogging: kDebugMode,
        onError: (err) {
          debugPrint(
            'SpeechRecognition error: ${err.errorMsg} (permanent: ${err.permanent})',
          );
        },
        onStatus: (status) {
          debugPrint('SpeechRecognition status: $status');
          _statusListener?.call(status);
        },
      );
      _isInitialized = true;
      return _isAvailable;
    } catch (e) {
      debugPrint('SpeechRecognition init exception: $e');
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
        final target =
            language.defaultLocale.toLowerCase().replaceAll('-', '_');
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

  Future<SpeechStartResult> startListeningDetailed({
    required Function(String recognizedWords, bool isFinal) onResult,
    DictationLanguage language = DictationLanguage.english,
    VoidCallback? onListeningStopped,
  }) async {
    // 1. Detect unsupported language on Windows
    if (isWindows && language == DictationLanguage.urdu) {
      return const SpeechStartResult(
        success: false,
        message: 'Urdu voice dictation is not supported on Windows native API.',
        detailedHelp:
            'Windows SAPI speech recognition only supports English. For Urdu speech-to-text, please use our mobile app (Android or iOS). On Windows, you can type directly in Urdu or dictate in English.',
      );
    }

    // 2. Initialize recognition engine
    try {
      final available = await initialize();
      if (!available) {
        if (isWindows) {
          return const SpeechStartResult(
            success: false,
            message: 'Windows Speech Recognition is unavailable.',
            detailedHelp:
                'Please verify:\n1. A microphone is connected and set as default recording device.\n2. Windows Settings > Privacy & security > Microphone: "Let desktop apps access your microphone" is turned ON.\n3. Windows Settings > Time & Language > Speech recognition package is installed.',
          );
        }
        return const SpeechStartResult(
          success: false,
          message:
              'Microphone permission is required or speech recognition service is not available on this device.',
        );
      }

      final resolvedLocale = await resolveLocaleId(language);
      debugPrint(
        'SpeechRecognition startListening with locale: $resolvedLocale for ${language.name}',
      );

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
      return const SpeechStartResult(success: true);
    } catch (e) {
      debugPrint('SpeechRecognition startListening error: $e');
      return SpeechStartResult(
        success: false,
        message: 'Failed to start speech recognition: $e',
      );
    }
  }

  Future<bool> startListening({
    required Function(String recognizedWords, bool isFinal) onResult,
    DictationLanguage language = DictationLanguage.english,
    VoidCallback? onListeningStopped,
  }) async {
    final result = await startListeningDetailed(
      onResult: onResult,
      language: language,
      onListeningStopped: onListeningStopped,
    );
    return result.success;
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
