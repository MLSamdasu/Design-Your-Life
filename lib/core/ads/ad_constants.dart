// C0: AdMob 광고 단위 ID 상수 정의
// 개발 환경에서는 Google 공식 테스트 광고 ID를 사용한다.
// 프로덕션 배포 시 실제 광고 단위 ID로 교체해야 한다.
// 플랫폼별(Android/iOS) 광고 ID를 분리하여 관리한다.

import 'dart:io';

import 'package:flutter/foundation.dart';

/// AdMob 광고 상수 (C0)
/// 테스트 광고 ID와 프로덕션 광고 ID를 플랫폼별로 관리한다
/// iOS/Android에서만 광고를 표시하고, 데스크톱(macOS/Windows)에서는 광고를 비활성화한다
abstract final class AdConstants {
  /// 광고 지원 플랫폼 여부 (iOS/Android만 true)
  /// 데스크톱(macOS/Windows)에서는 광고를 표시하지 않는다
  static bool get isAdSupported => Platform.isAndroid || Platform.isIOS;
  // ─── Google 공식 테스트 광고 단위 ID ────────────────────────────────────────
  // 참고: https://developers.google.com/admob/android/test-ads
  // 참고: https://developers.google.com/admob/ios/test-ads

  /// Android 테스트 전면 광고 ID (Google 공식)
  static const _androidTestInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';

  /// Android 테스트 리워드 광고 ID (Google 공식)
  static const _androidTestRewardedId =
      'ca-app-pub-3940256099942544/5224354917';

  /// iOS 테스트 전면 광고 ID (Google 공식)
  static const _iosTestInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';

  /// iOS 테스트 리워드 광고 ID (Google 공식)
  static const _iosTestRewardedId =
      'ca-app-pub-3940256099942544/1712485313';

  // ─── 프로덕션 광고 단위 ID (배포 전 교체 필수) ──────────────────────────────
  // TODO: AdMob 콘솔에서 발급받은 실제 광고 단위 ID로 교체한다

  /// Android 프로덕션 전면 광고 ID
  static const _androidProdInterstitialId =
      'ca-app-pub-1188822284077857/8698871458';

  /// Android 프로덕션 리워드 광고 ID
  static const _androidProdRewardedId =
      'ca-app-pub-1188822284077857/7118399730';

  /// iOS 프로덕션 전면 광고 ID
  static const _iosProdInterstitialId =
      'YOUR_IOS_INTERSTITIAL_AD_UNIT_ID';

  /// iOS 프로덕션 리워드 광고 ID
  static const _iosProdRewardedId =
      'YOUR_IOS_REWARDED_AD_UNIT_ID';

  // ─── 개발 모드 플래그 ─────────────────────────────────────────────────────

  /// 테스트 광고 사용 여부
  /// 릴리스 빌드에서는 자동으로 프로덕션 광고 ID를 사용한다
  /// 수동 토글이 필요 없어 배포 시 실수를 방지한다
  static bool get useTestAds => kDebugMode;

  // ─── 플랫폼별 광고 단위 ID 접근자 ──────────────────────────────────────────

  /// 현재 플랫폼의 전면 광고 단위 ID를 반환한다
  /// 데스크톱(macOS/Windows)에서는 AdMob을 지원하지 않으므로 빈 문자열을 반환한다
  static String get interstitialAdUnitId {
    if (!isAdSupported) return '';
    if (useTestAds) {
      return Platform.isAndroid
          ? _androidTestInterstitialId
          : _iosTestInterstitialId;
    }
    return Platform.isAndroid
        ? _androidProdInterstitialId
        : _iosProdInterstitialId;
  }

  /// 현재 플랫폼의 리워드 광고 단위 ID를 반환한다
  /// 데스크톱(macOS/Windows)에서는 AdMob을 지원하지 않으므로 빈 문자열을 반환한다
  static String get rewardedAdUnitId {
    if (!isAdSupported) return '';
    if (useTestAds) {
      return Platform.isAndroid
          ? _androidTestRewardedId
          : _iosTestRewardedId;
    }
    return Platform.isAndroid
        ? _androidProdRewardedId
        : _iosProdRewardedId;
  }

  // ─── 광고 표시 쿨다운 설정 ─────────────────────────────────────────────────
  // 사용자 경험을 위해 광고 표시 간격을 제한한다

  /// 전면 광고 최소 표시 간격 (초)
  /// 동일 세션에서 너무 자주 전면 광고가 표시되지 않도록 제한한다
  static const int interstitialCooldownSeconds = 180;

  /// 미완료 작업 광고 트리거를 위한 최소 미완료 비율 (%)
  /// 이 비율 이상 미완료 시 광고를 표시한다
  static const double incompleteThresholdPercent = 50.0;
}
