import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_magnifier/services/ad_service.dart';

void main() {
  group('AdService', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('resolveBannerUnitId returns null when ads are disabled', () {
      final service = AdService(adsEnabled: false);
      expect(service.resolveBannerUnitId(), isNull);
    });

    test(
      'resolveBannerUnitId returns test ad unit when test mode is enabled',
      () {
        final service = AdService(useTestUnitIds: true, adsEnabled: true);
        expect(
          service.resolveBannerUnitId(),
          'ca-app-pub-3940256099942544/6300978111',
        );
      },
    );

    test('resolveBannerUnitId uses configured id in production mode', () {
      final service = AdService(
        useTestUnitIds: false,
        adsEnabled: true,
        androidBannerUnitId: 'android-banner-id',
      );
      expect(service.resolveBannerUnitId(), 'android-banner-id');
    });
  });
}
