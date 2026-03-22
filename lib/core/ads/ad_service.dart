// C0: AdMob 광고 서비스
// 전면 광고(interstitial)와 리워드 광고(rewarded)의 로드, 표시, 생명주기를 관리한다.
// 싱글톤으로 동작하며, 앱 시작 시 초기화하고 광고를 미리 로드한다.
// 쿨다운 메커니즘으로 사용자 경험을 보호한다.

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_constants.dart';

/// 광고 서비스 초기화 및 관리 (C0)
/// 전면 광고: 할일/습관/루틴 미완료 시 표시
/// 리워드 광고: 백업 실행 전 표시 (보상 확인 후 백업 진행)
class AdService {
  /// 전면 광고 인스턴스 (로드 완료 시 non-null)
  InterstitialAd? _interstitialAd;

  /// 리워드 광고 인스턴스 (로드 완료 시 non-null)
  RewardedAd? _rewardedAd;

  /// 전면 광고 로드 완료 여부
  bool _isInterstitialLoaded = false;

  /// 리워드 광고 로드 완료 여부
  bool _isRewardedLoaded = false;

  /// 마지막 전면 광고 표시 시각 (쿨다운 계산용)
  DateTime? _lastInterstitialShownAt;

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
      _loadInterstitialAd(),
      _loadRewardedAd(),
    ]);
  }

  // ─── 전면 광고 ──────────────────────────────────────────────────────────────

  /// 전면 광고를 로드한다
  /// 이미 로드된 광고가 있으면 중복 로드하지 않는다
  Future<void> _loadInterstitialAd() async {
    if (_isInterstitialLoaded) return;

    await InterstitialAd.load(
      adUnitId: AdConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;

          // 광고가 닫힌 후 다음 광고를 미리 로드한다
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialLoaded = false;
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialLoaded = false;
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          // 로드 실패 시 상태만 초기화한다 (재시도는 다음 preloadAds 호출 시)
          _isInterstitialLoaded = false;
        },
      ),
    );
  }

  /// 전면 광고를 표시한다 (할일/습관/루틴 미완료 시)
  /// 쿨다운 기간 내이거나 광고가 로드되지 않았으면 무시한다
  /// 데스크톱에서는 광고를 표시하지 않는다
  /// 반환값: 광고가 실제로 표시되었는지 여부
  bool showInterstitialAd() {
    // 데스크톱에서는 광고를 지원하지 않으므로 즉시 반환한다
    if (!AdConstants.isAdSupported) return false;

    // 쿨다운 검사: 마지막 표시로부터 일정 시간이 지나지 않았으면 표시하지 않는다
    if (_lastInterstitialShownAt != null) {
      final elapsed =
          DateTime.now().difference(_lastInterstitialShownAt!).inSeconds;
      if (elapsed < AdConstants.interstitialCooldownSeconds) {
        return false;
      }
    }

    // 로컬 변수에 캡처하여 콜백에 의한 null 할당 경쟁 조건을 방지한다
    final ad = _interstitialAd;
    if (!_isInterstitialLoaded || ad == null) {
      // 광고가 아직 로드되지 않았으면 백그라운드에서 로드를 시도한다
      _loadInterstitialAd();
      return false;
    }

    ad.show();
    _lastInterstitialShownAt = DateTime.now();
    return true;
  }

  // ─── 리워드 광고 ────────────────────────────────────────────────────────────

  /// 리워드 광고를 로드한다
  /// 이미 로드된 광고가 있으면 중복 로드하지 않는다
  Future<void> _loadRewardedAd() async {
    if (_isRewardedLoaded) return;

    await RewardedAd.load(
      adUnitId: AdConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoaded = true;

          // 광고가 닫힌 후 다음 광고를 미리 로드한다
          _rewardedAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedLoaded = false;
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedLoaded = false;
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          // 로드 실패 시 상태만 초기화한다
          _isRewardedLoaded = false;
        },
      ),
    );
  }

  /// 리워드 광고를 표시하고, 보상 확인 후 콜백을 실행한다 (백업 전)
  /// [onRewarded]: 사용자가 광고를 끝까지 시청한 후 실행할 콜백
  /// 데스크톱에서는 광고 없이 즉시 보상 콜백을 실행한다 (백업 차단 방지)
  /// 반환값: 광고가 실제로 표시되었는지 여부
  bool showRewardedAd({
    required void Function() onRewarded,
    void Function()? onDismissed,
  }) {
    // 데스크톱에서는 광고 없이 즉시 보상 콜백을 실행한다
    if (!AdConstants.isAdSupported) {
      onRewarded();
      return false;
    }

    // 로컬 변수에 캡처하여 콜백에 의한 null 할당 경쟁 조건을 방지한다
    final ad = _rewardedAd;
    if (!_isRewardedLoaded || ad == null) {
      // 광고가 로드되지 않았으면 콜백을 즉시 실행한다 (광고 없이 진행)
      onRewarded();
      _loadRewardedAd();
      return false;
    }

    // 광고 닫힘 콜백을 재설정하여 onDismissed를 호출한다
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        onDismissed?.call();
        ad.dispose();
        _rewardedAd = null;
        _isRewardedLoaded = false;
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        onDismissed?.call();
        ad.dispose();
        _rewardedAd = null;
        _isRewardedLoaded = false;
        _loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        // 사용자가 보상을 획득한 후 콜백을 실행한다
        onRewarded();
      },
    );
    return true;
  }

  // ─── 상태 접근자 ─────────────────────────────────────────────────────────────

  /// 전면 광고가 표시 가능한 상태인지 확인한다
  bool get isInterstitialReady => _isInterstitialLoaded;

  /// 리워드 광고가 표시 가능한 상태인지 확인한다
  bool get isRewardedReady => _isRewardedLoaded;

  // ─── 리소스 해제 ─────────────────────────────────────────────────────────────

  /// 모든 광고 리소스를 해제한다
  /// 앱 종료 시 호출한다
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
    _isInterstitialLoaded = false;
    _isRewardedLoaded = false;
  }
}
