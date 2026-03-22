// F4: 습관 Riverpod Provider (Single Source of Truth 아키텍처)
// allHabitsRawProvider, allHabitLogsRawProvider에서 파생하여 자동 동기화된다.
// CRUD 후 버전 카운터를 증가시키면 홈/습관 탭 모두 자동 갱신된다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/habit.dart';
import '../../../shared/models/habit_log.dart';
import '../../achievement/providers/achievement_provider.dart';
import '../services/habit_repository.dart';
import '../services/habit_log_repository.dart';
import '../services/streak_calculator.dart';
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

/// 활성 습관 목록 Provider (동기 Provider)
/// allHabitsRawProvider(Single Source of Truth)에서 파생하여 CRUD 시 자동 갱신된다
/// Hive는 동기 API이므로 FutureProvider가 불필요하다 — AsyncValue 로딩 깜빡임을 제거한다
final activeHabitsProvider = Provider<List<Habit>>((ref) {
  // Single Source of Truth: allHabitsRawProvider에서 파생한다
  final allHabits = ref.watch(allHabitsRawProvider);
  return allHabits
      .where((h) => h['is_active'] == true)
      .map((h) => Habit.fromMap(h))
      .toList();
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

/// 선택된 날짜의 습관 로그 Provider (동기 Provider)
/// allHabitLogsRawProvider(Single Source of Truth)에서 파생하여 체크/CRUD 시 자동 갱신된다
/// Hive는 동기 API이므로 FutureProvider가 불필요하다 — AsyncValue 로딩 깜빡임을 제거한다
final habitLogsForDateProvider = Provider<List<HabitLog>>((ref) {
  final date = ref.watch(habitSelectedDateProvider);
  // Single Source of Truth: allHabitLogsRawProvider에서 파생한다
  final allLogs = ref.watch(allHabitLogsRawProvider);
  final dateStr = AppDateUtils.toDateString(date);

  return allLogs
      .where((d) => d['log_date'] == dateStr)
      .map((d) => HabitLog.fromMap(d))
      .toList();
});

/// 현재 표시 월의 습관 로그 Provider (동기 Provider, 캘린더용)
/// allHabitLogsRawProvider(Single Source of Truth)에서 파생한다
/// Hive는 동기 API이므로 FutureProvider가 불필요하다 — AsyncValue 로딩 깜빡임을 제거한다
final habitLogsForMonthProvider = Provider<List<HabitLog>>((ref) {
  final month = ref.watch(habitFocusedMonthProvider);
  // Single Source of Truth: allHabitLogsRawProvider에서 파생한다
  final allLogs = ref.watch(allHabitLogsRawProvider);
  final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}';

  return allLogs
      .where((d) {
        final logDate = d['log_date'] as String?;
        return logDate != null && logDate.startsWith(monthStr);
      })
      .map((d) => HabitLog.fromMap(d))
      .toList();
});

// ─── 스트릭 Provider ─────────────────────────────────────────────────────────

/// 특정 습관의 현재 스트릭을 계산하는 Family Provider
/// habitLogDataVersionProvider를 감시하여 로그 변경 시 자동으로 재계산한다
/// 빈도(frequency, repeatDays)를 반영하여 예정 요일 기준으로 스트릭을 계산한다
final streakForHabitProvider = Provider.family<int, String>((ref, habitId) {
  // 로그가 변경될 때 스트릭도 재계산되도록 버전 카운터 하나만 감시한다
  // habitLogsForDateProvider + habitLogsForMonthProvider 이중 감시를 제거하여 삼중 평가를 방지한다
  ref.watch(habitLogDataVersionProvider);

  final logRepo = ref.watch(habitLogRepositoryProvider);
  final checkedDates = logRepo.getCheckedDates(habitId);
  if (checkedDates.isEmpty) return 0;

  // 해당 습관의 빈도 정보를 조회한다
  final habits = ref.watch(activeHabitsProvider);
  final habit = habits.where((h) => h.id == habitId).firstOrNull;

  // 체크된 날짜 목록으로 HabitLog 리스트를 구성하여 StreakCalculator에 전달한다
  final logs = checkedDates
      .map((date) => HabitLog(
            id: '',
            habitId: habitId,
            date: date,
            isCompleted: true,
            checkedAt: date,
          ))
      .toList();

  final result = StreakCalculator.calculate(
    logs,
    DateTime.now(),
    frequency: habit?.frequency ?? HabitFrequency.daily,
    repeatDays: habit?.repeatDays ?? const [],
  );
  return result.currentStreak;
});

// ─── 달성률 Provider ────────────────────────────────────────────────────────

/// 오늘 예정된 활성 습관 목록 파생 Provider (빈도 기반 필터링)
final todayScheduledHabitsProvider = Provider<List<Habit>>((ref) {
  final habits = ref.watch(activeHabitsProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  // 오늘 요일에 예정된 습관만 반환한다
  return habits.where((h) => h.isScheduledFor(today)).toList();
});

/// 오늘 습관 달성률 파생 Provider
/// habitSelectedDateProvider와 독립적으로 항상 오늘 날짜 기준 로그를 사용한다
final todayHabitCompletionRateProvider = Provider<double>((ref) {
  final todayHabits = ref.watch(todayScheduledHabitsProvider);
  // habitLogsForDateProvider 대신 allHabitLogsRawProvider에서 오늘 로그만 직접 필터링한다
  // 캘린더에서 다른 날짜를 선택해도 홈의 오늘 달성률에 영향을 주지 않는다
  final allLogs = ref.watch(allHabitLogsRawProvider);
  final now = DateTime.now();
  final todayStr = AppDateUtils.toDateString(DateTime(now.year, now.month, now.day));
  final logs = allLogs
      .where((d) => d['log_date'] == todayStr)
      .map((d) => HabitLog.fromMap(d))
      .toList();

  if (todayHabits.isEmpty) return 0.0;
  // 오늘 예정된 습관 중 완료된 로그만 카운트한다
  final todayHabitIds = todayHabits.map((h) => h.id).toSet();
  final completedCount =
      logs.where((l) => l.isCompleted && todayHabitIds.contains(l.habitId)).length;
  return (completedCount / todayHabits.length * 100).clamp(0.0, 100.0);
});

/// 습관 캘린더 월별 날짜->달성률 맵 파생 Provider
/// 제한사항: 현재 활성 습관 수를 기준으로 과거 날짜의 달성률을 계산한다.
/// 과거에 활성이었다가 비활성/삭제된 습관의 이력은 추적하지 않으므로,
/// 과거 날짜의 달성률이 실제와 다를 수 있다.
final habitCalendarDataProvider = Provider<Map<DateTime, double>>((ref) {
  final habits = ref.watch(activeHabitsProvider);
  final logs = ref.watch(habitLogsForMonthProvider);

  // 활성 습관이 없으면 빈 맵을 반환한다 (0으로 나누기 방지)
  if (habits.isEmpty) return {};

  // 날짜별 완료 로그 그룹화
  final Map<DateTime, List<HabitLog>> logsByDate = {};
  for (final log in logs) {
    final dateKey = DateTime(log.date.year, log.date.month, log.date.day);
    logsByDate.putIfAbsent(dateKey, () => []).add(log);
  }

  // 날짜별 달성률 계산 (빈도 기반: 해당 날짜에 예정된 습관 수 기준)
  final Map<DateTime, double> result = {};
  for (final entry in logsByDate.entries) {
    // 해당 날짜에 예정된 습관 수를 계산한다
    final scheduledCount =
        habits.where((h) => h.isScheduledFor(entry.key)).length;
    if (scheduledCount == 0) continue;
    final completedCount = entry.value.where((l) => l.isCompleted).length;
    result[entry.key] =
        (completedCount / scheduledCount * 100).clamp(0.0, 100.0);
  }
  return result;
});

// ─── 습관 체크 Provider ─────────────────────────────────────────────────────

/// 습관 체크 토글 액션
/// 시간 잠금 검증 후 로컬 Hive에서 체크/체크 해제를 수행한다
/// 시간 잠금으로 거부된 경우 TimeLockResult를 반환하여 UI에서 사유를 표시할 수 있다
final toggleHabitProvider =
    Provider<Future<TimeLockResult?> Function(String, DateTime, bool)>((ref) {
  final repository = ref.watch(habitLogRepositoryProvider);

  return (String habitId, DateTime date, bool isCompleted) async {

    // F4.4 시간 잠금 검증 (과거 날짜 편집 방지)
    final lockResult = TimeLockValidator.validate(date, DateTime.now());
    if (!lockResult.isEditable) return lockResult; // 잠금 사유를 반환한다

    // isCompleted가 true면 체크 생성, false면 체크 해제 (로그 삭제)
    if (isCompleted) {
      await repository.checkHabit(habitId, date: date);
    } else {
      await repository.uncheckHabit(habitId, date);
    }
    // 로그 변경 버전 카운터 증가 → 홈/습관 탭 로그 관련 UI 자동 갱신
    ref.read(habitLogDataVersionProvider.notifier).state++;

    // 스트릭을 재계산하여 Hive에 영구 저장한다
    // AchievementStatsCollector가 longest_streak를 Hive에서 읽으므로
    // 여기서 영구화하지 않으면 스트릭 기반 업적이 달성 불가능하다
    try {
      final habitRepo = ref.read(habitRepositoryProvider);
      final logRepo = ref.read(habitLogRepositoryProvider);
      final checkedDates = logRepo.getCheckedDates(habitId);
      final habits = habitRepo.getActiveHabits();
      final habit = habits.where((h) => h.id == habitId).firstOrNull;
      final logs = checkedDates
          .map((d) => HabitLog(
              id: '', habitId: habitId, date: d,
              isCompleted: true, checkedAt: d))
          .toList();
      final result = StreakCalculator.calculate(
        logs, DateTime.now(),
        frequency: habit?.frequency ?? HabitFrequency.daily,
        repeatDays: habit?.repeatDays ?? const [],
      );
      await habitRepo.updateStreak(habitId, result.currentStreak, result.longestStreak);
      // 스트릭 영구화 성공 시에만 습관 데이터 버전을 범프한다
      // (습관 자체의 streak 필드가 변경되었으므로)
      ref.read(habitDataVersionProvider.notifier).state++;
    } catch (e, stack) {
      // 스트릭 영구화 실패는 주 기능을 차단하지 않지만 에러를 기록한다
      ErrorHandler.logServiceError('HabitProvider:StreakPersistence', e, stack);
    }

    // 체크 완료 시 업적 달성 조건을 확인한다
    if (isCompleted) {
      await checkAchievementsAndNotify(ref);
    }

    // 성공 시 null 반환 (시간 잠금 거부 없음)
    return null;
  };
});

/// 새 습관 생성 액션
final createHabitProvider = Provider<Future<void> Function(Habit)>((ref) {
  final repository = ref.watch(habitRepositoryProvider);

  return (Habit habit) async {
    try {
      await repository.createHabit(habit);
      // 버전 카운터 증가 → 홈/습관 탭 모두 자동 갱신
      ref.read(habitDataVersionProvider.notifier).state++;
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  };
});

/// 습관 수정 액션
final updateHabitProvider = Provider<Future<void> Function(String, Habit)>((ref) {
  final repository = ref.watch(habitRepositoryProvider);

  return (String habitId, Habit habit) async {
    try {
      await repository.updateHabit(habitId, habit);
      // 버전 카운터 증가 → 홈/습관 탭 모두 자동 갱신
      ref.read(habitDataVersionProvider.notifier).state++;
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  };
});

/// 습관 삭제 액션
/// 삭제 시 HabitLogRepository를 통해 해당 습관의 고아 로그도 함께 정리한다
final deleteHabitProvider = Provider<Future<void> Function(String)>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  final logRepository = ref.watch(habitLogRepositoryProvider);

  return (String habitId) async {
    try {
      // V3-011: 고아 습관 로그 정리를 HabitLogRepository에 위임한다
      await logRepository.deleteLogsByHabitId(habitId);
      await repository.deleteHabit(habitId);
      // 버전 카운터 증가 → 홈/습관 탭 모두 자동 갱신
      ref.read(habitDataVersionProvider.notifier).state++;
      ref.read(habitLogDataVersionProvider.notifier).state++;
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  };
});

/// 새 습관 ID 생성 헬퍼
/// 로컬 퍼스트에서 클라이언트가 UUID v4로 고유 ID를 생성한다
/// HabitRepository.createHabit()가 내부에서 UUID를 재생성하므로 이 ID는 임시이다
final generateHabitIdProvider = Provider<String Function()>((ref) {
  return () {
    return const Uuid().v4();
  };
});
