// F4: 습관 Riverpod Provider
// activeHabitsProvider, habitLogsForDateProvider, habitCalendarDataProvider 등을 정의한다.
// 로컬 퍼스트 아키텍처: Hive 로컬 박스에서 데이터를 조회한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/providers/global_providers.dart';
import '../../../shared/models/habit.dart';
import '../../../shared/models/habit_log.dart';
import '../services/habit_repository.dart';
import '../services/habit_log_repository.dart';
import '../services/time_lock_validator.dart';

// ─── 서브탭 Provider ────────────────────────────────────────────────────────

/// 습관 서브탭 유형
enum HabitSubTab {
  /// 습관 트래커
  tracker,

  /// 내 루틴
  routine,
}

/// 습관 화면 서브탭 Provider
final habitSubTabProvider = StateProvider<HabitSubTab>((ref) {
  return HabitSubTab.tracker;
});

// ─── Repository Provider ────────────────────────────────────────────────────

/// HabitRepository Provider
/// HiveCacheService를 주입하여 로컬 퍼스트로 동작한다
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return HabitRepository(cache: cache);
});

/// HabitLogRepository Provider
/// HiveCacheService를 주입하여 로컬 퍼스트로 동작한다
final habitLogRepositoryProvider = Provider<HabitLogRepository>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return HabitLogRepository(cache: cache);
});

// ─── 습관 목록 Provider ───────────────────────────────────────────────────

/// 활성 습관 목록 Provider (FutureProvider)
/// 로컬 Hive에서 동기적으로 읽되 FutureProvider 인터페이스를 유지한다
final activeHabitsProvider = FutureProvider<List<Habit>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(habitRepositoryProvider);

  if (userId == null) return const [];
  // 로컬 퍼스트: Hive에서 동기 조회한다
  return repository.getActiveHabits();
});

// ─── 선택된 날짜 Provider ───────────────────────────────────────────────────

/// 습관 캘린더에서 선택된 날짜 Provider
final habitSelectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// 습관 캘린더 현재 표시 월 Provider
final habitFocusedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

// ─── 습관 로그 Provider ─────────────────────────────────────────────────────

/// 선택된 날짜의 습관 로그 Provider (FutureProvider)
/// 로컬 Hive에서 날짜별로 직접 필터링하여 조회한다
final habitLogsForDateProvider = FutureProvider<List<HabitLog>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final date = ref.watch(habitSelectedDateProvider);
  final repository = ref.watch(habitLogRepositoryProvider);

  if (userId == null) return const [];
  // 로컬 퍼스트: Hive에서 날짜별로 직접 조회한다
  return repository.getLogsForDate(date);
});

/// 현재 표시 월의 습관 로그 Provider (FutureProvider, 캘린더용)
/// 로컬 Hive에서 월별 필터링하여 조회한다
final habitLogsForMonthProvider = FutureProvider<List<HabitLog>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final month = ref.watch(habitFocusedMonthProvider);
  final repository = ref.watch(habitLogRepositoryProvider);

  if (userId == null) return const [];
  // 로컬 퍼스트: Hive에서 월별로 직접 조회한다
  return repository.getLogsForMonth(month.year, month.month);
});

// ─── 달성률 Provider ────────────────────────────────────────────────────────

/// 오늘 습관 달성률 파생 Provider
final todayHabitCompletionRateProvider = Provider<double>((ref) {
  final habitsAsync = ref.watch(activeHabitsProvider);
  final logsAsync = ref.watch(habitLogsForDateProvider);

  final habits = habitsAsync.valueOrNull ?? [];
  final logs = logsAsync.valueOrNull ?? [];

  if (habits.isEmpty) return 0.0;
  final completedCount = logs.where((l) => l.isCompleted).length;
  return (completedCount / habits.length * 100).clamp(0.0, 100.0);
});

/// 습관 캘린더 월별 날짜->달성률 맵 파생 Provider
final habitCalendarDataProvider = Provider<Map<DateTime, double>>((ref) {
  final habitsAsync = ref.watch(activeHabitsProvider);
  final logsAsync = ref.watch(habitLogsForMonthProvider);

  final habits = habitsAsync.valueOrNull ?? [];
  final logs = logsAsync.valueOrNull ?? [];

  if (habits.isEmpty) return {};

  // 날짜별 완료 로그 그룹화
  final Map<DateTime, List<HabitLog>> logsByDate = {};
  for (final log in logs) {
    final dateKey = DateTime(log.date.year, log.date.month, log.date.day);
    logsByDate.putIfAbsent(dateKey, () => []).add(log);
  }

  // 날짜별 달성률 계산
  final Map<DateTime, double> result = {};
  for (final entry in logsByDate.entries) {
    final completedCount = entry.value.where((l) => l.isCompleted).length;
    result[entry.key] =
        (completedCount / habits.length * 100).clamp(0.0, 100.0);
  }
  return result;
});

// ─── 습관 체크 Provider ─────────────────────────────────────────────────────

/// 습관 체크 토글 액션
/// 시간 잠금 검증 후 로컬 Hive에서 체크/체크 해제를 수행한다
final toggleHabitProvider =
    Provider<Future<void> Function(String, DateTime, bool)>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(habitLogRepositoryProvider);

  return (String habitId, DateTime date, bool isCompleted) async {
    if (userId == null) return;

    // F4.4 시간 잠금 검증 (과거 날짜 편집 방지)
    final lockResult = TimeLockValidator.validate(date, DateTime.now());
    if (!lockResult.isEditable) return; // 잠금된 날짜는 무시

    // isCompleted가 true면 체크 생성, false면 체크 해제 (로그 삭제)
    if (isCompleted) {
      await repository.checkHabit(habitId);
    } else {
      await repository.uncheckHabit(habitId, date);
    }
    // 토글 후 관련 Provider를 무효화하여 UI를 갱신한다
    ref.invalidate(habitLogsForDateProvider);
    ref.invalidate(habitLogsForMonthProvider);
  };
});

/// 새 습관 생성 액션
final createHabitProvider = Provider<Future<void> Function(Habit)>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(habitRepositoryProvider);

  return (Habit habit) async {
    if (userId == null) return;
    await repository.createHabit(habit);
    // 생성 후 습관 목록을 다시 로드한다
    ref.invalidate(activeHabitsProvider);
  };
});

/// 습관 삭제 액션
final deleteHabitProvider = Provider<Future<void> Function(String)>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(habitRepositoryProvider);

  return (String habitId) async {
    if (userId == null) return;
    await repository.deleteHabit(habitId);
    // 삭제 후 습관 목록을 다시 로드한다
    ref.invalidate(activeHabitsProvider);
  };
});

/// 새 습관 ID 생성 헬퍼
/// REST API에서는 서버가 ID를 할당하므로 클라이언트에서 임시 ID를 생성한다
final generateHabitIdProvider = Provider<String Function()>((ref) {
  return () {
    return DateTime.now().millisecondsSinceEpoch.toString();
  };
});
