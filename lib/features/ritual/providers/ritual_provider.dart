// F-Ritual: 리추얼 Provider
// Repository 초기화, 현재 기간 리추얼 조회, 오늘의 DailyThree 조회,
// 저장 액션, Todo 생성 연동을 담당한다.
// CRUD 후 ritualDataVersionProvider / dailyThreeDataVersionProvider를
// 증가시켜 전체 파생 체인이 자동 갱신된다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../models/daily_ritual.dart';
import '../models/daily_three.dart';
import '../services/ritual_repository.dart';

// ─── Repository Provider ────────────────────────────────────────────────────

/// RitualRepository Provider (로컬 퍼스트)
/// HiveCacheService를 주입받아 Hive 저장소에 접근한다
final ritualRepositoryProvider = Provider<RitualRepository>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return RitualRepository(cache: cache);
});

// ─── 리추얼 조회 Provider ──────────────────────────────────────────────────

/// 현재 기간의 DailyRitual을 조회한다
/// periodType과 periodKey를 파라미터로 받는 family Provider
final currentRitualProvider = Provider.family<DailyRitual?,
    ({String periodType, String periodKey})>((ref, params) {
  // 버전 변경 시 재평가된다
  ref.watch(ritualDataVersionProvider);
  final repository = ref.watch(ritualRepositoryProvider);
  return repository.getRitualForPeriod(params.periodType, params.periodKey);
});

/// 오늘의 DailyThree를 조회한다
/// todayDateProvider에서 오늘 날짜를 가져와 자동으로 조회한다
final todayDailyThreeProvider = Provider<DailyThree?>((ref) {
  ref.watch(dailyThreeDataVersionProvider);
  final repository = ref.watch(ritualRepositoryProvider);
  final today = ref.watch(todayDateProvider);
  final dateStr = AppDateUtils.toDateString(today);
  return repository.getDailyThreeForDate(dateStr);
});

/// 오늘 리추얼(DailyThree)이 완료되었는지 확인한다
final hasCompletedTodayProvider = Provider<bool>((ref) {
  ref.watch(dailyThreeDataVersionProvider);
  final repository = ref.watch(ritualRepositoryProvider);
  final today = ref.watch(todayDateProvider);
  final dateStr = AppDateUtils.toDateString(today);
  return repository.hasCompletedRitualToday(dateStr);
});

// ─── 리추얼 저장 액션 Provider ────────────────────────────────────────────

/// DailyRitual 저장 액션
/// 로컬 Hive에 즉시 저장하고 버전 카운터를 증가시킨다
final saveRitualProvider =
    Provider<Future<void> Function(DailyRitual)>((ref) {
  final repository = ref.watch(ritualRepositoryProvider);
  return (DailyRitual ritual) async {
    await repository.saveRitual(ritual);
    ref.read(ritualDataVersionProvider.notifier).state++;
  };
});

/// DailyThree 저장 액션 (Todo 생성 없이 단순 저장)
/// Todo 연동이 필요하면 saveDailyThreeWithTodosProvider를 사용한다
final saveDailyThreeProvider =
    Provider<Future<void> Function(DailyThree)>((ref) {
  final repository = ref.watch(ritualRepositoryProvider);
  return (DailyThree dailyThree) async {
    await repository.saveDailyThree(dailyThree);
    ref.read(dailyThreeDataVersionProvider.notifier).state++;
  };
});
