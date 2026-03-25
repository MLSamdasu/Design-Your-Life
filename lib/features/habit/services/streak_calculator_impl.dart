// F4: StreakCalculator (F4.3) - 순수 함수
// habitId, allLogs: List<HabitLog>, today: DateTime을 받아
// currentStreak(현재 연속 일수)와 longestStreak(최장 연속 일수)를 반환한다.
// 빈도 기반: daily 습관은 매일 연속, weekly/custom은 WeeklyStreakCalculator에 위임한다.
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/habit.dart';
import '../../../shared/models/habit_log.dart';
import 'streak_result.dart';
import 'weekly_streak_calculator.dart';

/// 스트릭 계산기 (F4.3 순수 함수)
/// 외부 상태에 의존하지 않는 순수 계산 모듈
abstract class StreakCalculator {
  /// 현재 스트릭과 최장 스트릭을 계산한다
  /// allLogs: 특정 습관의 전체 로그 (날짜 내림차순 권장)
  /// today: 기준 오늘 날짜 (시간 무시)
  /// frequency: 습관 빈도 유형 (기본값: daily, 하위 호환)
  /// repeatDays: weekly/custom인 경우 실행 요일 목록 (기본값: 빈 리스트)
  static StreakResult calculate(
    List<HabitLog> allLogs,
    DateTime today, {
    HabitFrequency frequency = HabitFrequency.daily,
    List<int> repeatDays = const [],
  }) {
    if (allLogs.isEmpty) return StreakResult.zero;

    // 완료된 로그만 날짜 집합으로 변환
    final completedDates = allLogs
        .where((log) => log.isCompleted)
        .map((log) => AppDateUtils.startOfDay(log.date))
        .toSet();

    if (completedDates.isEmpty) return StreakResult.zero;

    // daily 습관: 매일 연속 로직 사용
    if (frequency == HabitFrequency.daily) {
      return _calculateDaily(completedDates, today);
    }

    // weekly/custom 습관: 전용 계산기에 위임
    return WeeklyStreakCalculator.calculate(
      completedDates,
      today,
      repeatDays,
    );
  }

  /// daily 습관의 스트릭을 계산한다 (매일 연속 체크 기준)
  static StreakResult _calculateDaily(
    Set<DateTime> completedDates,
    DateTime today,
  ) {
    final todayStart = AppDateUtils.startOfDay(today);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    // 오늘 또는 어제에 체크했을 때만 스트릭 유지
    int currentStreak = 0;
    DateTime checkDate;
    if (completedDates.contains(todayStart)) {
      checkDate = todayStart;
    } else if (completedDates.contains(yesterdayStart)) {
      checkDate = yesterdayStart;
    } else {
      // 오늘도 어제도 체크 없으면 스트릭 0
      return StreakResult(
        currentStreak: 0,
        longestStreak: _calculateLongestDaily(completedDates),
      );
    }

    // checkDate부터 과거로 연속된 날짜 카운트
    while (completedDates.contains(checkDate)) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return StreakResult(
      currentStreak: currentStreak,
      longestStreak: _calculateLongestDaily(completedDates),
    );
  }

  /// daily 습관의 최장 스트릭을 계산한다
  static int _calculateLongestDaily(Set<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final sortedDates = dates.toList()..sort();

    int longest = 1;
    int current = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }
}
