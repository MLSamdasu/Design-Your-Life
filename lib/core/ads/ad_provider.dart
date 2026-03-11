// C0: AdMob 광고 Riverpod Provider
// AdService 싱글톤, 백업 광고 연동, 미완료 작업 광고 트리거를 제공한다.
// 백업 시나리오: 리워드 광고 시청 → 보상 확인 → 백업 실행
// 미완료 시나리오: 전면 광고 표시 (쿨다운 적용)

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backup/backup_provider.dart';
import '../backup/backup_service.dart';
import 'ad_service.dart';

// ─── AdService 싱글톤 Provider ──────────────────────────────────────────────
/// AdService 싱글톤 Provider
/// 앱 전체에서 하나의 AdService 인스턴스를 공유한다
final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService();
  // Provider 소멸 시 광고 리소스를 해제한다
  ref.onDispose(() => service.dispose());
  return service;
});

// ─── 광고 초기화 Provider ───────────────────────────────────────────────────
/// AdMob 초기화 + 광고 미리 로드를 수행하는 FutureProvider
/// main.dart 또는 앱 시작 시 한 번 호출한다
final adInitProvider = FutureProvider<void>((ref) async {
  final adService = ref.watch(adServiceProvider);
  await adService.initialize();
  await adService.preloadAds();
});

// ─── 백업 + 리워드 광고 통합 Provider ────────────────────────────────────────
/// 리워드 광고를 표시한 후 백업을 실행하는 함수 Provider
/// 광고가 로드되지 않았으면 광고 없이 바로 백업을 진행한다
/// Completer 패턴으로 광고 콜백의 비동기 흐름을 안전하게 처리한다
/// 반환값: BackupResult (성공/실패/미인증)
final showBackupAdProvider =
    Provider<Future<BackupResult> Function({
      void Function(double progress)? onProgress,
    })>((ref) {
  final adService = ref.watch(adServiceProvider);
  final backupService = ref.watch(backupServiceProvider);

  return ({
    void Function(double progress)? onProgress,
  }) async {
    // Completer로 리워드 광고의 비동기 콜백을 Future로 변환한다
    final rewardCompleter = Completer<bool>();

    final adShown = adService.showRewardedAd(
      onRewarded: () {
        // 사용자가 광고를 끝까지 시청하여 보상을 획득한 경우
        if (!rewardCompleter.isCompleted) {
          rewardCompleter.complete(true);
        }
      },
    );

    if (!adShown) {
      // 광고가 로드되지 않았으면 바로 백업을 진행한다
      // (showRewardedAd 내부에서 onRewarded가 즉시 호출되어 Completer가 이미 완료됨)
    }

    // 보상 확인을 대기한 후 백업을 실행한다
    await rewardCompleter.future;
    return backupService.backupAll(onProgress: onProgress);
  };
});

// ─── 미완료 작업 전면 광고 Provider ──────────────────────────────────────────
/// 미완료 작업(습관/루틴/할일) 시 전면 광고를 표시하는 함수 Provider
/// 쿨다운과 로드 상태를 내부적으로 관리한다
final showIncompleteTaskAdProvider = Provider<bool Function()>((ref) {
  final adService = ref.watch(adServiceProvider);

  return () {
    return adService.showInterstitialAd();
  };
});

// ─── 광고 로드 상태 Provider ─────────────────────────────────────────────────
/// 전면 광고 준비 완료 여부 Provider
final isInterstitialReadyProvider = Provider<bool>((ref) {
  final adService = ref.watch(adServiceProvider);
  return adService.isInterstitialReady;
});

/// 리워드 광고 준비 완료 여부 Provider
final isRewardedReadyProvider = Provider<bool>((ref) {
  final adService = ref.watch(adServiceProvider);
  return adService.isRewardedReady;
});
