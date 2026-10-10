class AdConstants {
  AdConstants._();

  /// Google official test units — safe for debug builds.
  static const String testAndroidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String testIosBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const String testAndroidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const String testIosInterstitial = 'ca-app-pub-3940256099942544/4411468910';

  static const String envAdsEnabled = 'ADMOB_ENABLED';
  static const String envAndroidBanner = 'ADMOB_ANDROID_BANNER_ID';
  static const String envIosBanner = 'ADMOB_IOS_BANNER_ID';
  static const String envAndroidInterstitial = 'ADMOB_ANDROID_INTERSTITIAL_ID';
  static const String envIosInterstitial = 'ADMOB_IOS_INTERSTITIAL_ID';

  /// Cooldown between full-screen interstitials (set to zero to show on first and next episodes as requested).
  static const Duration interstitialCooldown = Duration.zero;
}
