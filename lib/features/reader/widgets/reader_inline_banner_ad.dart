import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/ad_service.dart';
import '../../../domain/entities/user_entity.dart';
import '../states/episode_reader_state.dart';

/// Self-contained inline banner — each slot loads and disposes its own [BannerAd].
class ReaderInlineBannerAd extends StatefulWidget {
  final ReaderColorTheme theme;
  final String slotKey;
  final UserRole? userRole;

  const ReaderInlineBannerAd({
    super.key,
    required this.theme,
    required this.slotKey,
    this.userRole,
  });

  @override
  State<ReaderInlineBannerAd> createState() => _ReaderInlineBannerAdState();
}

class _ReaderInlineBannerAdState extends State<ReaderInlineBannerAd>
    with AutomaticKeepAliveClientMixin {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _failed = false;
  bool _isDisposed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (AdService().shouldShowAdsFor(role: widget.userRole)) {
      _loadAd();
    } else {
      _failed = true;
    }
  }

  void _loadAd() {
    if (_isDisposed) return;
    final ad = AdService().createBannerAd(
      onAdLoaded: () {
        if (!mounted || _isDisposed) return;
        setState(() => _isLoaded = true);
      },
      onAdFailedToLoad: (err) {
        debugPrint('ReaderInlineBannerAd: Failed to load banner ad for ${widget.slotKey}: $err');
        if (!mounted || _isDisposed) return;
        setState(() {
          _failed = true;
          _isLoaded = false;
        });
      },
    );

    if (ad == null) {
      if (!_isDisposed && mounted) {
        setState(() => _failed = true);
      }
      return;
    }

    _bannerAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!AdService().shouldShowAdsFor(role: widget.userRole)) {
      return const SizedBox.shrink();
    }

    final ad = _bannerAd;

    if (_isLoaded && ad != null) {
      return RepaintBoundary(
        child: Container(
          key: ValueKey(widget.slotKey),
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.l),
          alignment: Alignment.center,
          height: ad.size.height.toDouble(),
          width: ad.size.width.toDouble(),
          child: AdWidget(ad: ad),
        ),
      );
    }

    // In debug mode on non-mobile platforms (e.g. Windows desktop), show visual test banner slot
    if (kDebugMode && (kIsWeb || (!Platform.isAndroid && !Platform.isIOS))) {
      return Container(
        key: ValueKey(widget.slotKey),
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.l),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.theme.textColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadii.m),
          border: Border.all(
            color: widget.theme.textColor.withValues(alpha: 0.15),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
                child: const Text(
                  'Ad',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Google AdMob Inline Banner (Test Unit)',
                style: AppTextStyles.labelSmall.copyWith(
                  color: widget.theme.textColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_failed) {
      return const SizedBox.shrink();
    }

    return Container(
      key: ValueKey('${widget.slotKey}_placeholder'),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.l),
      height: 50,
      alignment: Alignment.center,
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: widget.theme.textColor.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
