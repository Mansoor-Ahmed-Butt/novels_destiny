class AppConstants {
  AppConstants._();

  static const String appName = 'Novels Destiny';
  static const String appVersion = '1.0.0';
  static const String appTagline =
      'A haven for passionate writers & avid readers';

  // Limits
  static const int maxNovelSummaryLength = 1000;
  static const int maxChapterContentLength = 50000;
  static const int minPasswordLength = 6;
  static const int searchDebounceMs = 300;
  static const int progressDebounceMs = 2000;

  // Pagination
  static const int defaultPageSize = 20;

  // Reader Settings Defaults
  static const double defaultReaderFontSize = 17.0;
  static const double minReaderFontSize = 12.0;
  static const double maxReaderFontSize = 28.0;
  static const double defaultReaderLineHeight = 1.7;

  // Google Auth Server Client ID (Web Client ID from Firebase / Google Cloud Console)
  static const String defaultGoogleServerClientId =
      '454348386247-acoi211ubonk0pooshljofr6fugh4ac7.apps.googleusercontent.com';

  // Session Storage
  static const String userSessionStorageKey = 'novels_destiny_auth_session';
}
