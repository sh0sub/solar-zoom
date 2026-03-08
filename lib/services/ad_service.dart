import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static const String _androidProductionBannerUnitId =
      'ca-app-pub-7927943774602148/7418335608';
  static const String _androidTestBannerUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  final String _androidBannerUnitId;
  final bool adsEnabled;
  final bool useTestUnitIds;

  AdService({
    String? androidBannerUnitId,
    bool? adsEnabled,
    bool? useTestUnitIds,
  }) : _androidBannerUnitId =
           androidBannerUnitId ??
           const String.fromEnvironment(
             'ADMOB_BANNER_UNIT_ID_ANDROID',
             defaultValue: _androidProductionBannerUnitId,
           ),
       adsEnabled =
           adsEnabled ??
           const bool.fromEnvironment('ADS_ENABLED', defaultValue: true),
       useTestUnitIds =
           useTestUnitIds ??
           (bool.hasEnvironment('ADS_USE_TEST_IDS')
               ? const bool.fromEnvironment('ADS_USE_TEST_IDS')
               : !kReleaseMode);

  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  String? resolveBannerUnitId() {
    if (!adsEnabled || !isSupportedPlatform) {
      return null;
    }

    if (useTestUnitIds) {
      return _androidTestBannerUnitId;
    }

    final String trimmed = _androidBannerUnitId.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  BannerAd? createBannerAd({
    required VoidCallback onLoaded,
    required void Function(LoadAdError error) onFailed,
    AdSize size = AdSize.banner,
  }) {
    final String? adUnitId = resolveBannerUnitId();
    if (adUnitId == null) {
      return null;
    }

    final BannerAd bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) => onLoaded(),
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          onFailed(error);
        },
      ),
    );

    bannerAd.load();
    return bannerAd;
  }
}
