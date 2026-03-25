// C0: AdMob 광고 서비스 (오케스트레이터)
// 전면 광고와 리워드 광고 서비스를 조합하여 통합 인터페이스를 제공한다.
// 싱글톤으로 동작하며, 앱 시작 시 초기화하고 광고를 미리 로드한다.

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_constants.dart';
import 'interstitial_ad_service.dart';
import 'rewarded_ad_service.dart';

// 배럴 re-export: 분리된 광고 서비스를 이 파일에서 함께 노출한다
export 'interstitial_ad_service.dart';
export 'rewarded_ad_service.dart';

/// 광고 서비스 초기화 및 관리 (C0 오케스트레이터)
/// 전면 광고: 할일/습관/루틴 미완료 시 표시
/// 리워드 광고: 백업 실행 전 표시 (보상 확인 후 백업 진행)
class AdService {
  /// 전면 광고 서비스
  final InterstitialAdService _interstitial = InterstitialAdService();

  /// 리워드 광고 서비스
  final RewardedAdService _rewarded = RewardedAdService();

  /// AdMob SDK 초기화 여부
  bool _isInitialized = false;

  // ─── 초기화 ──────────────────────────────────────────────────────────────

  /// AdMob SDK를 초기화한다
  /// 앱 시작 시 한 번만 호출해야 한다
  /// 데스크톱(macOS/Windows)에서는 AdMob을 사용하지 않으므로 초기화를 건너뛴다
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (!AdConstants.isAdSupported) return;
    await MobileAds.instance.initialize();
    _isInitialized = true;
  }

  // ─── 광고 미리 로드 ─────────────────────────────────────────────────────────

  /// 전면 광고와 리워드 광고를 동시에 미리 로드한다
  /// 초기화 후 호출하여 광고 표시 지연을 최소화한다
  /// 데스크톱에서는 광고를 사용하지 않으므로 로드를 건너뛴다
  Future<void> preloadAds() async {
    if (!AdConstants.isAdSupported) return;
    if (!_isInitialized) return;
    await Future.wait([
      _interstitial.load(),
      _rewarded.load(),
    ]);
  }

  // ─── 전면 광고 위임 ────────────────────────────────────────────────────────

  /// 전면 광고를 표시한다 (할일/습관/루틴 미완료 시)
  /// 쿨다운 기간 내이거나 광고가 로드되지 않았으면 무시한다
  bool showInterstitialAd() => _interstitial.show();

  // ─── 리워드 광고 위임 ──────────────────────────────────────────────────────

  /// 리워드 광고를 표시하고, 보상 확인 후 콜백을 실행한다
  bool showRewardedAd({
    required void Function() onRewarded,
    void Function()? onDismissed,
  }) =>
      _rewarded.show(onRewarded: onRewarded, onDismissed: onDismissed);

  // ─── 상태 접근자 ─────────────────────────────────────────────────────────────

  /// 전면 광고가 표시 가능한 상태인지 확인한다
  bool get isInterstitialReady => _interstitial.isReady;

  /// 리워드 광고가 표시 가능한 상태인지 확인한다
  bool get isRewardedReady => _rewarded.isReady;

  // ─── 리소스 해제 ─────────────────────────────────────────────────────────────

  /// 모든 광고 리소스를 해제한다
  /// 앱 종료 시 호출한다
  void dispose() {
    _interstitial.dispose();
    _rewarded.dispose();
  }
}
