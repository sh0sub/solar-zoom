class AdPolicyService {
  bool canShowResultBanner({
    required bool hasLoadedAd,
    required bool isProcessing,
    required bool isAiLoading,
    required bool isResultSheetOpen,
    required bool isTtsActive,
  }) {
    if (!hasLoadedAd) return false;
    if (isProcessing) return false;
    if (isAiLoading) return false;
    if (isResultSheetOpen) return false;
    if (isTtsActive) return false;
    return true;
  }
}
