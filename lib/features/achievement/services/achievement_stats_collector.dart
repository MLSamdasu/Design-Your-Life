// F8: 업적 통계 수집기
// 업적 달성 조건 평가에 필요한 통계 파라미터를 Hive에서 집계한다.
// 각 Feature Provider에서 checkAndUnlockAchievements 호출 전에 사용한다.
// DI 원칙: HiveCacheService를 파라미터로 주입받아 Hive 직접 접근을 금지한다.

import '../../../core/cache/hive_cache_service.dart';
import '../../../core/constants/app_constants.dart';

/// 업적 달성 조건 평가에 필요한 통계 데이터
class AchievementStats {
  final int totalCompletedTodos;
  final int longestHabitStreak;
  final int totalHabitsCreated;
  final int totalGoalsCreated;
  final int completedMandalarts;
  final bool allHabitsCompletedToday;
  final bool isEarlyBird;

  const AchievementStats({
    required this.totalCompletedTodos,
    required this.longestHabitStreak,
    required this.totalHabitsCreated,
    required this.totalGoalsCreated,
    required this.completedMandalarts,
    required this.allHabitsCompletedToday,
    required this.isEarlyBird,
  });
}

/// 업적 통계 수집기 (F8 AchievementStatsCollector)
/// HiveCacheService를 주입받아 통계를 집계하여 AchievementStats를 반환한다
abstract class AchievementStatsCollector {
  /// HiveCacheService를 통해 업적 평가에 필요한 모든 통계를 집계한다
  static AchievementStats collect(HiveCacheService cache) {
    return AchievementStats(
      totalCompletedTodos: _countCompletedTodos(cache),
      longestHabitStreak: _calcLongestHabitStreak(cache),
      totalHabitsCreated: _countHabits(cache),
      totalGoalsCreated: _countGoals(cache),
      completedMandalarts: _countCompletedMandalarts(cache),
      allHabitsCompletedToday: _checkAllHabitsCompletedToday(cache),
      isEarlyBird: DateTime.now().hour < 6,
    );
  }

  /// todosBox에서 is_completed == true인 항목 수를 세다
  static int _countCompletedTodos(HiveCacheService cache) {
    final allTodos = cache.getAll(AppConstants.todosBox);
    return allTodos.where((d) => d['is_completed'] == true).length;
  }

  /// 모든 습관의 최장 스트릭을 반환한다
  /// habitsBox에 저장된 longest_streak 필드를 활용한다 (StreakCalculator가 계산)
  /// 빈도(frequency, repeatDays) 기반 계산은 StreakCalculator가 담당하므로
  /// 여기서는 저장된 값의 최대를 취하여 정확성을 보장한다
  static int _calcLongestHabitStreak(HiveCacheService cache) {
    final allHabits = cache.getAll(AppConstants.habitsBox);
    int maxStreak = 0;
    for (final data in allHabits) {
      final streak = (data['longest_streak'] as num?)?.toInt() ?? 0;
      if (streak > maxStreak) maxStreak = streak;
    }
    return maxStreak;
  }

  /// habitsBox의 전체 습관 수를 세다
  static int _countHabits(HiveCacheService cache) {
    return cache.getAll(AppConstants.habitsBox).length;
  }

  /// goalsBox의 전체 목표 수를 세다
  static int _countGoals(HiveCacheService cache) {
    return cache.getAll(AppConstants.goalsBox).length;
  }

  /// 완료된 만다라트 수를 세다
  /// 만다라트 = subGoalsBox에 하위 목표가 존재하는 목표
  /// 해당 목표가 is_completed == true이면 완성된 만다라트로 카운트한다
  static int _countCompletedMandalarts(HiveCacheService cache) {
    final allGoals = cache.getAll(AppConstants.goalsBox);
    final allSubGoals = cache.getAll(AppConstants.subGoalsBox);

    // 하위 목표가 있는 목표 ID 집합을 구성한다
    final goalIdsWithSubGoals = allSubGoals
        .map((d) => d['goal_id']?.toString())
        .whereType<String>()
        .toSet();

    // 완료된 목표 중 하위 목표가 있는 것만 카운트한다
    return allGoals
        .where((d) =>
            d['is_completed'] == true &&
            goalIdsWithSubGoals.contains(d['id']?.toString()))
        .length;
  }

  /// 오늘 예정된 모든 습관을 달성했는지 확인한다
  static bool _checkAllHabitsCompletedToday(HiveCacheService cache) {
    final allHabits = cache.getAll(AppConstants.habitsBox);
    final allLogs = cache.getAll(AppConstants.habitLogsBox);

    final now = DateTime.now();
    final todayWeekday = now.weekday;
    final todayStr = _formatDate(now);

    // 오늘 예정된 활성 습관 ID를 수집한다
    final scheduledHabitIds = <String>{};
    for (final data in allHabits) {
      if (data['is_active'] != true) continue;
      final id = data['id']?.toString();
      if (id == null) continue;

      final frequency = data['frequency']?.toString() ?? 'daily';
      if (frequency == 'daily') {
        // daily 습관은 매일 예정됨
        scheduledHabitIds.add(id);
      } else {
        // weekly/custom 습관: repeat_days에 오늘 요일이 포함되는지 확인
        final repeatDays = data['repeat_days'];
        if (repeatDays is List) {
          // Hive가 num 타입으로 저장할 수 있으므로 int로 안전하게 변환한다
          final days = repeatDays.map((e) => (e as num?)?.toInt()).whereType<int>().toList();
          if (days.contains(todayWeekday)) {
            scheduledHabitIds.add(id);
          }
        }
      }
    }

    // 예정된 습관이 없으면 '모든 습관 달성'이 아니다
    if (scheduledHabitIds.isEmpty) return false;

    // 오늘 완료된 습관 ID를 수집한다
    final completedHabitIds = allLogs
        .where((d) => d['is_completed'] == true && d['log_date'] == todayStr)
        .map((d) => d['habit_id']?.toString())
        .whereType<String>()
        .toSet();

    // 예정된 모든 습관이 완료됐는지 확인한다
    return scheduledHabitIds.every((id) => completedHabitIds.contains(id));
  }

  /// DateTime을 'YYYY-MM-DD' 형식 문자열로 변환한다
  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
