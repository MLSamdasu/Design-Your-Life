// F4-Query: 습관 조회/파생 Provider
// 로그 필터링, 스트릭 계산, 달성률, 캘린더 데이터 등
// habit_state_providers.dart의 기반 Provider에서 파생되는 읽기 전용 Provider를 정의한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/data_store_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/habit.dart';
import '../../../shared/models/habit_log.dart';
import '../services/streak_calculator.dart';
import 'habit_state_providers.dart';

// ─── 습관 로그 Provider ─────────────────────────────────────────────────────

/// 선택된 날짜의 습관 로그 Provider (동기 Provider)
/// allHabitLogsRawProvider(Single Source of Truth)에서 파생하여 체크/CRUD 시 자동 갱신된다
/// Hive는 동기 API이므로 FutureProvider가 불필요하다 — AsyncValue 로딩 깜빡임을 제거한다
final habitLogsForDateProvider = Provider<List<HabitLog>>((ref) {
  final date = ref.watch(habitSelectedDateProvider);
  // 단일 진실 원천(SSOT): allHabitLogsRawProvider에서 파생한다
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
  // 단일 진실 원천(SSOT): allHabitLogsRawProvider에서 파생한다
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
  final todayStr =
      AppDateUtils.toDateString(DateTime(now.year, now.month, now.day));
  final logs = allLogs
      .where((d) => d['log_date'] == todayStr)
      .map((d) => HabitLog.fromMap(d))
      .toList();

  if (todayHabits.isEmpty) return 0.0;
  // 오늘 예정된 습관 중 완료된 로그만 카운트한다
  final todayHabitIds = todayHabits.map((h) => h.id).toSet();
  final completedCount = logs
      .where((l) => l.isCompleted && todayHabitIds.contains(l.habitId))
      .length;
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
