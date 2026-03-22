// F4: StreakCalculator (F4.3) - 순수 함수
// habitId, allLogs: List<HabitLog>, today: DateTime을 받아
// currentStreak(현재 연속 일수)와 longestStreak(최장 연속 일수)를 반환한다.
// 빈도 기반: daily 습관은 매일 연속, weekly/custom은 예정된 요일 기준으로 연속 판단한다.
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/habit.dart';
import '../../../shared/models/habit_log.dart';

/// 스트릭 계산 결과
class StreakResult {
  final int currentStreak;
  final int longestStreak;

  const StreakResult({
    required this.currentStreak,
    required this.longestStreak,
  });

  static const zero = StreakResult(currentStreak: 0, longestStreak: 0);
}

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

    // daily 습관: 기존 매일 연속 로직 사용
    if (frequency == HabitFrequency.daily) {
      return _calculateDaily(completedDates, today);
    }

    // weekly/custom 습관: 예정된 요일 기준으로 연속 판단
    return _calculateWeekly(completedDates, today, repeatDays);
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

  /// weekly/custom 습관의 스트릭을 계산한다 (예정 요일 기준)
  /// 예: 월/수/금 습관이면 화/목은 건너뛰고 월→수→금 연속 체크가 스트릭이 된다
  static StreakResult _calculateWeekly(
    Set<DateTime> completedDates,
    DateTime today,
    List<int> repeatDays,
  ) {
    if (repeatDays.isEmpty) return StreakResult.zero;

    final todayStart = AppDateUtils.startOfDay(today);

    // 가장 최근 예정일을 찾는다 (오늘 포함, 과거 방향)
    DateTime? findPrevScheduled(DateTime from) {
      var d = from;
      // 최대 7일 뒤로 탐색하면 반드시 예정 요일을 찾는다
      for (int i = 0; i < 7; i++) {
        if (repeatDays.contains(d.weekday)) return d;
        d = d.subtract(const Duration(days: 1));
      }
      return null;
    }

    // 주어진 날짜 바로 이전의 예정일을 찾는다 (해당 날짜 제외)
    DateTime? findPrevScheduledBefore(DateTime date) {
      var d = date.subtract(const Duration(days: 1));
      for (int i = 0; i < 7; i++) {
        if (repeatDays.contains(d.weekday)) return d;
        d = d.subtract(const Duration(days: 1));
      }
      return null;
    }

    // 현재 스트릭 계산: 가장 최근 예정일부터 역방향으로 연속 체크 카운트
    final latestScheduled = findPrevScheduled(todayStart);
    if (latestScheduled == null) return StreakResult.zero;

    // 가장 최근 예정일에 체크했는지 확인
    if (!completedDates.contains(latestScheduled)) {
      // 가장 최근 예정일에 체크하지 않았으면, 그 이전 예정일도 확인
      final beforeLatest = findPrevScheduledBefore(latestScheduled);
      if (beforeLatest == null || !completedDates.contains(beforeLatest)) {
        return StreakResult(
          currentStreak: 0,
          longestStreak: _calculateLongestWeekly(completedDates, repeatDays),
        );
      }
      // 이전 예정일에는 체크했으면 그 기점부터 카운트
      int currentStreak = 0;
      DateTime? checkDate = beforeLatest;
      while (checkDate != null && completedDates.contains(checkDate)) {
        currentStreak++;
        checkDate = findPrevScheduledBefore(checkDate);
      }
      return StreakResult(
        currentStreak: currentStreak,
        longestStreak: _calculateLongestWeekly(completedDates, repeatDays),
      );
    }

    // 가장 최근 예정일부터 역방향으로 연속 카운트
    int currentStreak = 0;
    DateTime? checkDate = latestScheduled;
    while (checkDate != null && completedDates.contains(checkDate)) {
      currentStreak++;
      checkDate = findPrevScheduledBefore(checkDate);
    }

    return StreakResult(
      currentStreak: currentStreak,
      longestStreak: _calculateLongestWeekly(completedDates, repeatDays),
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

  /// weekly/custom 습관의 최장 스트릭을 계산한다
  /// 예정 요일에만 체크된 날짜를 순서대로 보며, 다음 예정일에도 체크했으면 연속으로 카운트
  static int _calculateLongestWeekly(
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
