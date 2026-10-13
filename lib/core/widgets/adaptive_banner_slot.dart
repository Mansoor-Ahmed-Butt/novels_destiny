import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../domain/entities/user_entity.dart';
import '../services/ad_service.dart';

/// Anchored adaptive banner for list/detail screens (home, novel page, etc.).
class AdaptiveBannerSlot extends StatefulWidget {
  final String placementKey;
  final UserRole? userRole;
  final EdgeInsetsGeometry margin;

  const AdaptiveBannerSlot({
    super.key,
    required this.placementKey,
    this.userRole,
    this.margin = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  State<AdaptiveBannerSlot> createState() => _AdaptiveBannerSlotState();
}

class _AdaptiveBannerSlotState extends State<AdaptiveBannerSlot> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _loadStarted = false;
  AdSize? _adSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadStarted &&
        _bannerAd == null &&
        AdService().shouldShowAdsFor(role: widget.userRole)) {
      _loadStarted = true;
      _loadAdaptiveBanner();
    }
  }

  Future<void> _loadAdaptiveBanner() async {
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) return;

    final ad = AdService().createBannerAd(
      size: size,
      onAdLoaded: () {
        if (!mounted) return;
        setState(() => _isLoaded = true);
      },
      onAdFailedToLoad: (err) {
        debugPrint('AdaptiveBannerSlot: Failed to load banner [${widget.placementKey}]: $err');
        if (!mounted) return;
        _bannerAd?.dispose();
        setState(() {
          _bannerAd = null;
          _isLoaded = false;
        });
      },
    );

    if (ad == null || !mounted) {
      return;
    }

    setState(() {
      _adSize = size;
      _bannerAd = ad;
    });
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
    final size = _adSize;

    // Only show the container when the ad is fully loaded — hide in all other states
    // (loading, failed, not started). This prevents grey boxes from appearing.
    if (_isLoaded && ad != null && size != null) {
      return Container(
        key: ValueKey(widget.placementKey),
        margin: widget.margin,
        width: size.width.toDouble(),
        height: size.height.toDouble(),
        alignment: Alignment.center,
        child: AdWidget(ad: ad),
      );
    }

    // Hide while loading, failed, or not yet started — no spinner, no grey box
    return const SizedBox.shrink();
  }
}
