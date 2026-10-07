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

class _ReaderInlineBannerAdState extends State<ReaderInlineBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _failed = false;

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
    final ad = AdService().createBannerAd(
      onAdLoaded: () {
        if (!mounted) return;
        setState(() => _isLoaded = true);
      },
      onAdFailedToLoad: (_) {
        if (!mounted) return;
        setState(() {
          _failed = true;
          _isLoaded = false;
        });
      },
    );

    if (ad == null) {
      _failed = true;
      return;
    }

    _bannerAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService().shouldShowAdsFor(role: widget.userRole)) {
      return const SizedBox.shrink();
    }

    final ad = _bannerAd;

    if (_isLoaded && ad != null) {
      return Container(
        key: ValueKey(widget.slotKey),
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.l),
        alignment: Alignment.center,
        height: ad.size.height.toDouble(),
        width: ad.size.width.toDouble(),
        child: AdWidget(ad: ad),
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
