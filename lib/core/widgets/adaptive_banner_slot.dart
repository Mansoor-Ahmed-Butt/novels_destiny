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
      onAdFailedToLoad: (_) {
        if (!mounted) return;
        setState(() => _isLoaded = false);
      },
    );

    if (ad == null || !mounted) return;

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

    if (ad == null) return const SizedBox.shrink();

    return SizedBox(
      key: ValueKey('${widget.placementKey}_loading'),
      height: 50,
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
