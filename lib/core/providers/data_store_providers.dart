// C0: 중앙 데이터 스토어 Provider (Single Source of Truth)
// 각 데이터 타입별 버전 카운터 + 전체 목록 Provider를 정의한다.
// 모든 파생 Provider는 이 파일의 allXxxRawProvider를 watch하여 데이터를 읽는다.
// CRUD 후 해당 버전 카운터를 증가시키면 의존 Provider가 자동 갱신된다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import 'global_providers.dart';

// ─── 버전 카운터 Provider ──────────────────────────────────────────────────
// CRUD 후 해당 카운터를 1 증가시키면 의존 Provider가 자동 재평가된다

/// 투두 데이터 버전 카운터
final todoDataVersionProvider = StateProvider<int>((ref) => 0);

/// 이벤트 데이터 버전 카운터
final eventDataVersionProvider = StateProvider<int>((ref) => 0);

/// 습관 데이터 버전 카운터
final habitDataVersionProvider = StateProvider<int>((ref) => 0);

/// 습관 로그 데이터 버전 카운터
final habitLogDataVersionProvider = StateProvider<int>((ref) => 0);

/// 루틴 데이터 버전 카운터
final routineDataVersionProvider = StateProvider<int>((ref) => 0);

/// 루틴 로그 데이터 버전 카운터
final routineLogDataVersionProvider = StateProvider<int>((ref) => 0);

/// 태그 데이터 버전 카운터
final tagDataVersionProvider = StateProvider<int>((ref) => 0);

/// 타이머 로그 데이터 버전 카운터
final timerLogDataVersionProvider = StateProvider<int>((ref) => 0);

/// 업적 데이터 버전 카운터
final achievementDataVersionProvider = StateProvider<int>((ref) => 0);

/// 목표 데이터 버전 카운터
final goalDataVersionProvider = StateProvider<int>((ref) => 0);

/// 하위 목표 데이터 버전 카운터
final subGoalDataVersionProvider = StateProvider<int>((ref) => 0);

/// 실천 할일 데이터 버전 카운터
final goalTaskDataVersionProvider = StateProvider<int>((ref) => 0);

// ─── 전체 데이터 Provider (Single Source of Truth) ───────────────────────
// 각 Provider는 해당 버전 카운터를 watch하여 CRUD 시 자동 재로드된다
// Hive는 동기 API이므로 Provider(동기)로 정의한다

/// 전체 투두 목록 (Map 형태) — Single Source of Truth
final allTodosRawProvider = Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(todoDataVersionProvider); // 버전 변경 시 재평가
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.getAll(AppConstants.todosBox);
});

/// 전체 이벤트 목록 (Map 형태) — Single Source of Truth
final allEventsRawProvider = Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(eventDataVersionProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.getAll(AppConstants.eventsBox);
});

/// 전체 습관 목록 (Map 형태) — Single Source of Truth
final allHabitsRawProvider = Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(habitDataVersionProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.getAll(AppConstants.habitsBox);
});

/// 전체 습관 로그 목록 (Map 형태) — Single Source of Truth
final allHabitLogsRawProvider = Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(habitLogDataVersionProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.getAll(AppConstants.habitLogsBox);
});

/// 전체 루틴 목록 (Map 형태) — Single Source of Truth
final allRoutinesRawProvider = Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(routineDataVersionProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.getAll(AppConstants.routinesBox);
});

/// 전체 루틴 로그 목록 (Map 형태) — Single Source of Truth
final allRoutineLogsRawProvider = Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(routineLogDataVersionProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.getAll(AppConstants.routineLogsBox);
});

/// 전체 태그 목록 (Map 형태) — Single Source of Truth
final allTagsRawProvider = Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(tagDataVersionProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.getAll(AppConstants.tagsBox);
});

/// 전체 타이머 로그 목록 (Map 형태) — Single Source of Truth
final allTimerLogsRawProvider = Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(timerLogDataVersionProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.getAll(AppConstants.timerLogsBox);
});

/// 전체 업적 목록 (Map 형태) — Single Source of Truth
final allAchievementsRawProvider = Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(achievementDataVersionProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.getAll(AppConstants.achievementsBox);
});

/// 전체 목표 목록 (Map 형태) — Single Source of Truth
final allGoalsRawProvider = Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(goalDataVersionProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.getAll(AppConstants.goalsBox);
});

/// 전체 하위 목표 목록 (Map 형태) — Single Source of Truth
final allSubGoalsRawProvider = Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(subGoalDataVersionProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.getAll(AppConstants.subGoalsBox);
});

/// 전체 실천 할일 목록 (Map 형태) — Single Source of Truth
final allGoalTasksRawProvider = Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(goalTaskDataVersionProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.getAll(AppConstants.goalTasksBox);
});

// ─── 버전 일괄 증가 헬퍼 ──────────────────────────────────────────────────

/// 모든 데이터 버전 카운터를 일괄 증가시킨다
/// 백업 복원, Pull-to-refresh 등 전체 데이터가 변경된 경우에 호출한다
/// Ref(Provider 내부)와 WidgetRef(위젯) 모두에서 사용할 수 있도록 dynamic 타입을 받는다
void bumpAllDataVersions(dynamic ref) {
  ref.read(todoDataVersionProvider.notifier).state++;
  ref.read(eventDataVersionProvider.notifier).state++;
  ref.read(habitDataVersionProvider.notifier).state++;
  ref.read(habitLogDataVersionProvider.notifier).state++;
  ref.read(routineDataVersionProvider.notifier).state++;
  ref.read(routineLogDataVersionProvider.notifier).state++;
  ref.read(tagDataVersionProvider.notifier).state++;
  ref.read(timerLogDataVersionProvider.notifier).state++;
  ref.read(achievementDataVersionProvider.notifier).state++;
  ref.read(goalDataVersionProvider.notifier).state++;
  ref.read(subGoalDataVersionProvider.notifier).state++;
  ref.read(goalTaskDataVersionProvider.notifier).state++;
}
