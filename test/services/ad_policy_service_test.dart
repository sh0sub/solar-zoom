import 'package:flutter_test/flutter_test.dart';
import 'package:senior_magnifier/services/ad_policy_service.dart';

void main() {
  group('AdPolicyService', () {
    final service = AdPolicyService();

    test('returns true only when all constraints are satisfied', () {
      final canShow = service.canShowResultBanner(
        hasLoadedAd: true,
        isProcessing: false,
        isAiLoading: false,
        isResultSheetOpen: false,
        isTtsActive: false,
      );

      expect(canShow, isTrue);
    });

    test('returns false when any blocking condition is active', () {
      final scenarios = <bool>[
        service.canShowResultBanner(
          hasLoadedAd: false,
          isProcessing: false,
          isAiLoading: false,
          isResultSheetOpen: false,
          isTtsActive: false,
        ),
        service.canShowResultBanner(
          hasLoadedAd: true,
          isProcessing: true,
          isAiLoading: false,
          isResultSheetOpen: false,
          isTtsActive: false,
        ),
        service.canShowResultBanner(
          hasLoadedAd: true,
          isProcessing: false,
          isAiLoading: true,
          isResultSheetOpen: false,
          isTtsActive: false,
        ),
        service.canShowResultBanner(
          hasLoadedAd: true,
          isProcessing: false,
          isAiLoading: false,
          isResultSheetOpen: true,
          isTtsActive: false,
        ),
        service.canShowResultBanner(
          hasLoadedAd: true,
          isProcessing: false,
          isAiLoading: false,
          isResultSheetOpen: false,
          isTtsActive: true,
        ),
      ];

      expect(scenarios.every((v) => v == false), isTrue);
    });
  });
}
