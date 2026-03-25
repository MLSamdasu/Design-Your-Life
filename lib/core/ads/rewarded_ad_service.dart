// C0: 리워드 광고(Rewarded) 관리 서비스
// 리워드 광고의 로드, 표시, 보상 콜백 처리를 담당한다.
// AdService에서 사용되며, 직접 인스턴스화하지 않는다.

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_constants.dart';

/// 리워드 광고 관리 서비스
/// 백업 실행 전 표시되는 보상형 광고를 관리한다
class RewardedAdService {
  /// 리워드 광고 인스턴스 (로드 완료 시 non-null)
  RewardedAd? _rewardedAd;

  /// 리워드 광고 로드 완료 여부
  bool _isLoaded = false;

  /// 리워드 광고가 표시 가능한 상태인지 확인한다
  bool get isReady => _isLoaded;

  /// 리워드 광고를 로드한다
  /// 이미 로드된 광고가 있으면 중복 로드하지 않는다
  Future<void> load() async {
    if (_isLoaded) return;

    await RewardedAd.load(
      adUnitId: AdConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoaded = true;

          // 광고가 닫힌 후 다음 광고를 미리 로드한다
          _rewardedAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _isLoaded = false;
              load();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _isLoaded = false;
              load();
            },
          );
        },
        onAdFailedToLoad: (error) {
          // 로드 실패 시 상태만 초기화한다
          _isLoaded = false;
        },
      ),
    );
  }

  /// 리워드 광고를 표시하고, 보상 확인 후 콜백을 실행한다 (백업 전)
  /// [onRewarded]: 사용자가 광고를 끝까지 시청한 후 실행할 콜백
  /// 데스크톱에서는 광고 없이 즉시 보상 콜백을 실행한다 (백업 차단 방지)
  /// 반환값: 광고가 실제로 표시되었는지 여부
  bool show({
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
    if (!_isLoaded || ad == null) {
      // 광고가 로드되지 않았으면 콜백을 즉시 실행한다 (광고 없이 진행)
      onRewarded();
      load();
      return false;
    }

    // 광고 닫힘 콜백을 재설정하여 onDismissed를 호출한다
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        onDismissed?.call();
        ad.dispose();
        _rewardedAd = null;
        _isLoaded = false;
        load();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        onDismissed?.call();
        ad.dispose();
        _rewardedAd = null;
        _isLoaded = false;
        load();
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

  /// 리워드 광고 리소스를 해제한다
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isLoaded = false;
  }
}
