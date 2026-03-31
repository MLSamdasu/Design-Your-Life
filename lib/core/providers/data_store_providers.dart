// C0: 중앙 데이터 스토어 Provider (SSOT — 버전 카운터 + allXxxRawProvider)
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import 'data_store_memo_providers.dart';
import 'global_providers.dart';

// 하위 호환을 위한 배럴 re-export (메모/리추얼/데일리쓰리)
export 'data_store_memo_providers.dart';

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

/// 도서 데이터 버전 카운터
final bookDataVersionProvider = StateProvider<int>((ref) => 0);

/// 독서 계획 데이터 버전 카운터
final readingPlanDataVersionProvider = StateProvider<int>((ref) => 0);

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
final allAchievementsRawProvider =
    Provider<List<Map<String, dynamic>>>((ref) {
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

/// 전체 도서 목록 (Map 형태) — Single Source of Truth
final allBooksRawProvider = Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(bookDataVersionProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.getAll(AppConstants.booksBox);
});

/// 전체 독서 계획 목록 (Map 형태) — Single Source of Truth
final allReadingPlansRawProvider =
    Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(readingPlanDataVersionProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.getAll(AppConstants.readingPlansBox);
});

// ─── 버전 일괄 증가 헬퍼 ──────────────────────────────────────────────────

/// 모든 데이터 버전 카운터를 일괄 증가시킨다
/// 백업 복원, Pull-to-refresh 등 전체 데이터가 변경된 경우에 호출한다
/// Riverpod의 Ref(Provider 내부)와 WidgetRef(위젯)는 공통 인터페이스가 없으므로
/// 타입 체크로 분기하여 안전하게 처리한다
void bumpAllDataVersions(dynamic ref) {
  // Ref 또는 WidgetRef인지 타입을 검증한 후 버전 카운터를 증가시킨다
  if (ref is Ref) {
    _bumpAll(ref.read);
  } else if (ref is WidgetRef) {
    _bumpAll(ref.read);
  } else {
    throw ArgumentError(
      'bumpAllDataVersions: ref는 Ref 또는 WidgetRef여야 한다. '
      '전달된 타입: ${ref.runtimeType}',
    );
  }
}

/// 내부 헬퍼: read 함수를 받아 모든 버전 카운터를 1씩 증가시킨다
void _bumpAll(T Function<T>(ProviderListenable<T>) read) {
  read(todoDataVersionProvider.notifier).state++;
  read(eventDataVersionProvider.notifier).state++;
  read(habitDataVersionProvider.notifier).state++;
  read(habitLogDataVersionProvider.notifier).state++;
  read(routineDataVersionProvider.notifier).state++;
  read(routineLogDataVersionProvider.notifier).state++;
  read(tagDataVersionProvider.notifier).state++;
  read(timerLogDataVersionProvider.notifier).state++;
  read(achievementDataVersionProvider.notifier).state++;
  read(goalDataVersionProvider.notifier).state++;
  read(subGoalDataVersionProvider.notifier).state++;
  read(goalTaskDataVersionProvider.notifier).state++;
  read(ritualDataVersionProvider.notifier).state++;
  read(dailyThreeDataVersionProvider.notifier).state++;
  read(memoDataVersionProvider.notifier).state++;
  read(bookDataVersionProvider.notifier).state++;
  read(readingPlanDataVersionProvider.notifier).state++;
}
