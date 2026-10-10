import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../domain/entities/user_entity.dart';
import '../constants/ad_constants.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  DateTime? _lastInterstitialShownAt;
  DateTime? get lastInterstitialShownAt => _lastInterstitialShownAt;

  String? _lastInterstitialEpisodeId;
  String? get lastInterstitialEpisodeId => _lastInterstitialEpisodeId;

  bool get _adsEnabledFromEnv {
    if (!dotenv.isInitialized) return true;
    final flag = dotenv.env[AdConstants.envAdsEnabled]?.trim().toLowerCase();
    if (flag == null || flag.isEmpty) return true;
    return flag != 'false' && flag != '0' && flag != 'off';
  }

  static String get bannerAdUnitId => _resolveUnitId(
        androidEnvKey: AdConstants.envAndroidBanner,
        iosEnvKey: AdConstants.envIosBanner,
        testAndroid: AdConstants.testAndroidBanner,
        testIos: AdConstants.testIosBanner,
      );

  static String get interstitialAdUnitId => _resolveUnitId(
        androidEnvKey: AdConstants.envAndroidInterstitial,
        iosEnvKey: AdConstants.envIosInterstitial,
        testAndroid: AdConstants.testAndroidInterstitial,
        testIos: AdConstants.testIosInterstitial,
      );

  static String _resolveUnitId({
    required String androidEnvKey,
    required String iosEnvKey,
    required String testAndroid,
    required String testIos,
  }) {
    if (kIsWeb) return '';
    if (kDebugMode) {
      return Platform.isAndroid ? testAndroid : testIos;
    }
    if (dotenv.isInitialized) {
      final fromEnv = Platform.isAndroid
          ? dotenv.env[androidEnvKey]?.trim()
          : dotenv.env[iosEnvKey]?.trim();
      if (fromEnv != null &&
          fromEnv.isNotEmpty &&
          !fromEnv.contains('xxxxxxxx')) {
        return fromEnv;
      }
    }
    return Platform.isAndroid ? testAndroid : testIos;
  }

  /// Readers, guests, and admins can view ads (consistent monetization & QA verification).
  bool shouldShowAdsFor({UserRole? role}) {
    if (!_isInitialized || !_adsEnabledFromEnv) return false;
    return true;
  }

  Future<void> init() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint('AdService: Mobile ads not supported on this platform.');
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdService: Google Mobile Ads initialized.');
      preloadInterstitial();
    } catch (e) {
      debugPrint('AdService: Initialization error: $e');
    }
  }

  BannerAd? createBannerAd({
    required Function() onAdLoaded,
    required Function(LoadAdError) onAdFailedToLoad,
    AdSize size = AdSize.banner,
  }) {
    if (!_isInitialized || bannerAdUnitId.isEmpty) return null;

    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('AdService: Banner loaded.');
          onAdLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdService: Banner failed to load: $error');
          ad.dispose();
          onAdFailedToLoad(error);
        },
      ),
    );
  }

  void preloadInterstitial() {
    if (!_isInitialized ||
        !_adsEnabledFromEnv ||
        _isInterstitialLoading ||
        _interstitialAd != null ||
        interstitialAdUnitId.isEmpty) {
      return;
    }

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          debugPrint('AdService: Interstitial preloaded.');

          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              preloadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AdService: Interstitial failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              preloadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          _interstitialAd = null;
          debugPrint('AdService: Interstitial failed to load: $error');
        },
      ),
    );
  }

  /// Interstitial ad shown when opening an episode or clicking next episode.
  Future<void> showInterstitialForEpisode(
    String episodeId, {
    UserRole? role,
    bool isNextEpisode = false,
  }) async {
    if (!shouldShowAdsFor(role: role)) return;

    _lastInterstitialEpisodeId = episodeId;
    _lastInterstitialShownAt = DateTime.now();

    // If already preloaded, show immediately
    if (_interstitialAd != null) {
      await showInterstitialAsync();
      return;
    }

    // If interstitial is loading, wait up to 3 seconds for it to finish and show
    final completer = Completer<void>();
    preloadInterstitial();

    final stopwatch = Stopwatch()..start();
    Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (_interstitialAd != null) {
        timer.cancel();
        showInterstitial(onDismiss: () {
          if (!completer.isCompleted) completer.complete();
        });
      } else if (!_isInterstitialLoading || stopwatch.elapsedMilliseconds >= 3000) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    });

    await completer.future;
  }

  Future<void> showInterstitialAsync() {
    final completer = Completer<void>();
    showInterstitial(onDismiss: () {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  void showInterstitial({required VoidCallback onDismiss}) {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          preloadInterstitial();
          onDismiss();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          preloadInterstitial();
          onDismiss();
        },
      );
      _interstitialAd!.show();
    } else {
      onDismiss();
      preloadInterstitial();
    }
  }
}
