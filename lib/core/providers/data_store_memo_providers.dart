// C0: 메모/리추얼/데일리쓰리 데이터 스토어 Provider
// data_store_providers.dart에서 분리된 메모 관련 SSOT Provider를 정의한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import 'global_providers.dart';

// ─── 버전 카운터 Provider ──────────────────────────────────────────────────

/// 데일리 리추얼 데이터 버전 카운터
final ritualDataVersionProvider = StateProvider<int>((ref) => 0);

/// 데일리 쓰리 데이터 버전 카운터
final dailyThreeDataVersionProvider = StateProvider<int>((ref) => 0);

/// 메모 데이터 버전 카운터
final memoDataVersionProvider = StateProvider<int>((ref) => 0);

// ─── 전체 데이터 Provider (Single Source of Truth) ───────────────────────

/// 전체 데일리 리추얼 목록 (Map 형태) — Single Source of Truth
final allDailyRitualsRawProvider =
    Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(ritualDataVersionProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.getAll(AppConstants.dailyRitualBox);
});

/// 전체 데일리 쓰리 목록 (Map 형태) — Single Source of Truth
final allDailyThreesRawProvider =
    Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(dailyThreeDataVersionProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.getAll(AppConstants.dailyThreeBox);
});

/// 전체 메모 목록 (Map 형태) — Single Source of Truth
final allMemosRawProvider = Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(memoDataVersionProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.getAll(AppConstants.memosBox);
});
