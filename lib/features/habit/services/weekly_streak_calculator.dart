// F4: WeeklyStreakCalculator - weekly/custom 빈도 습관 스트릭 계산
// 예정된 요일(repeatDays) 기준으로 연속 완료 일수를 산출한다.
import '../../../core/utils/date_utils.dart';
import 'streak_result.dart';

/// weekly/custom 습관 전용 스트릭 계산기 (순수 함수)
abstract class WeeklyStreakCalculator {
  /// weekly/custom 습관의 스트릭을 계산한다 (예정 요일 기준)
  /// 예: 월/수/금 습관이면 화/목은 건너뛰고 월→수→금 연속 체크가 스트릭이 된다
  static StreakResult calculate(
    Set<DateTime> completedDates,
    DateTime today,
    List<int> repeatDays,
  ) {
    if (repeatDays.isEmpty) return StreakResult.zero;

    final todayStart = AppDateUtils.startOfDay(today);

    // 현재 스트릭 계산: 가장 최근 예정일부터 역방향으로 연속 체크 카운트
    final latestScheduled = _findPrevScheduled(todayStart, repeatDays);
    if (latestScheduled == null) return StreakResult.zero;

    // 가장 최근 예정일에 체크했는지 확인
    if (!completedDates.contains(latestScheduled)) {
      // 가장 최근 예정일에 체크하지 않았으면, 그 이전 예정일도 확인
      final beforeLatest =
          _findPrevScheduledBefore(latestScheduled, repeatDays);
      if (beforeLatest == null || !completedDates.contains(beforeLatest)) {
        return StreakResult(
          currentStreak: 0,
          longestStreak: calculateLongest(completedDates, repeatDays),
        );
      }
      // 이전 예정일에는 체크했으면 그 기점부터 카운트
      int currentStreak = 0;
      DateTime? checkDate = beforeLatest;
      while (checkDate != null && completedDates.contains(checkDate)) {
        currentStreak++;
        checkDate = _findPrevScheduledBefore(checkDate, repeatDays);
      }
      return StreakResult(
        currentStreak: currentStreak,
        longestStreak: calculateLongest(completedDates, repeatDays),
      );
    }

    // 가장 최근 예정일부터 역방향으로 연속 카운트
    int currentStreak = 0;
    DateTime? checkDate = latestScheduled;
    while (checkDate != null && completedDates.contains(checkDate)) {
      currentStreak++;
      checkDate = _findPrevScheduledBefore(checkDate, repeatDays);
    }

    return StreakResult(
      currentStreak: currentStreak,
      longestStreak: calculateLongest(completedDates, repeatDays),
    );
  }

  /// weekly/custom 습관의 최장 스트릭을 계산한다
  /// 예정 요일에만 체크된 날짜를 순서대로 보며, 다음 예정일에도 체크했으면 연속으로 카운트
  static int calculateLongest(
    Set<DateTime> dates,
    List<int> repeatDays,
  ) {
    if (dates.isEmpty || repeatDays.isEmpty) return 0;

    // 예정 요일에 해당하는 완료 날짜만 필터링
    final scheduledDates = dates
        .where((d) => repeatDays.contains(d.weekday))
        .toList()
      ..sort();

    if (scheduledDates.isEmpty) return 0;

    int longest = 1;
    int current = 1;

    for (int i = 1; i < scheduledDates.length; i++) {
      // 이전 예정일의 다음 예정일이 현재 날짜인지 확인
      final nextExpected =
          _findNextScheduledAfter(scheduledDates[i - 1], repeatDays);
      if (nextExpected != null &&
          nextExpected.isAtSameMomentAs(scheduledDates[i])) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  /// 가장 최근 예정일을 찾는다 (오늘 포함, 과거 방향)
  static DateTime? _findPrevScheduled(DateTime from, List<int> repeatDays) {
    var d = from;
    // 최대 7일 뒤로 탐색하면 반드시 예정 요일을 찾는다
    for (int i = 0; i < 7; i++) {
      if (repeatDays.contains(d.weekday)) return d;
      d = d.subtract(const Duration(days: 1));
    }
    return null;
  }

  /// 주어진 날짜 바로 이전의 예정일을 찾는다 (해당 날짜 제외)
  static DateTime? _findPrevScheduledBefore(
    DateTime date,
    List<int> repeatDays,
  ) {
    var d = date.subtract(const Duration(days: 1));
    for (int i = 0; i < 7; i++) {
      if (repeatDays.contains(d.weekday)) return d;
      d = d.subtract(const Duration(days: 1));
    }
    return null;
  }

  /// 주어진 날짜 다음의 예정일을 찾는다 (해당 날짜 제외)
  static DateTime? _findNextScheduledAfter(
    DateTime date,
    List<int> repeatDays,
  ) {
    var d = date.add(const Duration(days: 1));
    for (int i = 0; i < 7; i++) {
      if (repeatDays.contains(d.weekday)) return d;
      d = d.add(const Duration(days: 1));
    }
    return null;
  }
}
