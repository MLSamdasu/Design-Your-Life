// C0: 전면 광고(Interstitial) 관리 서비스
// 전면 광고의 로드, 표시, 쿨다운 메커니즘을 담당한다.
// AdService에서 사용되며, 직접 인스턴스화하지 않는다.

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_constants.dart';

/// 전면 광고 관리 서비스
/// 할일/습관/루틴 미완료 시 표시되는 전면 광고를 관리한다
class InterstitialAdService {
  /// 전면 광고 인스턴스 (로드 완료 시 non-null)
  InterstitialAd? _interstitialAd;

  /// 전면 광고 로드 완료 여부
  bool _isLoaded = false;

  /// 마지막 전면 광고 표시 시각 (쿨다운 계산용)
  DateTime? _lastShownAt;

  /// 전면 광고가 표시 가능한 상태인지 확인한다
  bool get isReady => _isLoaded;

  /// 전면 광고를 로드한다
  /// 이미 로드된 광고가 있으면 중복 로드하지 않는다
  Future<void> load() async {
    if (_isLoaded) return;

    await InterstitialAd.load(
      adUnitId: AdConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoaded = true;

          // 광고가 닫힌 후 다음 광고를 미리 로드한다
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isLoaded = false;
              load();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _isLoaded = false;
              load();
            },
          );
        },
        onAdFailedToLoad: (error) {
          // 로드 실패 시 상태만 초기화한다 (재시도는 다음 preloadAds 호출 시)
          _isLoaded = false;
        },
      ),
    );
  }

  /// 전면 광고를 표시한다 (할일/습관/루틴 미완료 시)
  /// 쿨다운 기간 내이거나 광고가 로드되지 않았으면 무시한다
  /// 데스크톱에서는 광고를 표시하지 않는다
  /// 반환값: 광고가 실제로 표시되었는지 여부
  bool show() {
    // 데스크톱에서는 광고를 지원하지 않으므로 즉시 반환한다
    if (!AdConstants.isAdSupported) return false;

    // 쿨다운 검사: 마지막 표시로부터 일정 시간이 지나지 않았으면 표시하지 않는다
    if (_lastShownAt != null) {
      final elapsed =
          DateTime.now().difference(_lastShownAt!).inSeconds;
      if (elapsed < AdConstants.interstitialCooldownSeconds) {
        return false;
      }
    }

    // 로컬 변수에 캡처하여 콜백에 의한 null 할당 경쟁 조건을 방지한다
    final ad = _interstitialAd;
    if (!_isLoaded || ad == null) {
      // 광고가 아직 로드되지 않았으면 백그라운드에서 로드를 시도한다
      load();
      return false;
    }

    ad.show();
    _lastShownAt = DateTime.now();
    return true;
  }

  /// 전면 광고 리소스를 해제한다
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoaded = false;
  }
}
