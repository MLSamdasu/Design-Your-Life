// F6: 타이머 통계 Provider
// allTimerLogsRawProvider(Single Source of Truth)에서 파생하여
// 월별/주별 집중 통계를 계산한다.
// 캘린더 히트맵, 주간 바 차트, 월간 통계 카드에서 소비된다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../models/timer_log.dart';
import '../models/timer_stats.dart';

// ─── 서브탭 상태 Provider ─────────────────────────────────────────────────

/// 타이머 화면 서브탭 인덱스 (0: 타이머, 1: 통계)
final timerSubTabProvider = StateProvider<int>((ref) => 0);

/// 통계 화면 선택 월 Provider (캘린더 히트맵 + 월간 통계용)
final statsSelectedMonthProvider = StateProvider<DateTime>(
  (ref) => DateTime(DateTime.now().year, DateTime.now().month),
);

// ─── 내부 헬퍼: 전체 로그에서 focus 타입만 파싱 ─────────────────────────────

/// 전체 raw 로그를 TimerLog로 파싱하고 focus 타입만 필터링한다
List<TimerLog> _parseFocusLogs(List<Map<String, dynamic>> rawLogs) {
  final result = <TimerLog>[];
  for (final map in rawLogs) {
    try {
      final log = TimerLog.fromMap(map);
      if (log.type == TimerSessionType.focus) {
        result.add(log);
      }
    } catch (_) {
      // 파싱 실패 로그는 건너뛴다
      continue;
    }
  }
  return result;
}

// ─── 월별 일별 집중 시간 맵 ──────────────────────────────────────────────

/// 특정 월의 일별 집중 시간 맵 (day → minutes)
/// 캘린더 히트맵에서 각 날짜 셀의 색상 강도를 결정하는 데 사용된다
final monthlyFocusMapProvider =
    Provider.family<Map<int, int>, DateTime>((ref, month) {
  final allLogs = ref.watch(allTimerLogsRawProvider);
  final focusLogs = _parseFocusLogs(allLogs);

  // 해당 월의 로그만 필터링한다
  final filtered = focusLogs.where((log) =>
      log.startTime.year == month.year &&
      log.startTime.month == month.month);

  // 일자별로 그룹화하여 집중 시간(분)을 합산한다
  final dayMap = <int, int>{};
  for (final log in filtered) {
    final day = log.startTime.day;
    dayMap[day] = (dayMap[day] ?? 0) + (log.durationSeconds ~/ 60);
  }
  return dayMap;
});

// ─── 월별 일별 세션 수 맵 ──────────────────────────────────────────────

/// 특정 월의 일별 세션 수 맵 (day → count)
/// 캘린더 히트맵 툴팁에서 세션 수를 표시하는 데 사용된다
final monthlySessionMapProvider =
    Provider.family<Map<int, int>, DateTime>((ref, month) {
  final allLogs = ref.watch(allTimerLogsRawProvider);
  final focusLogs = _parseFocusLogs(allLogs);

  final filtered = focusLogs.where((log) =>
      log.startTime.year == month.year &&
      log.startTime.month == month.month);

  final sessionMap = <int, int>{};
  for (final log in filtered) {
    final day = log.startTime.day;
    sessionMap[day] = (sessionMap[day] ?? 0) + 1;
  }
  return sessionMap;
});

// ─── 주간 일별 집중 시간 리스트 ──────────────────────────────────────────

/// 특정 주의 일별 집중 시간 리스트 (7개 요소, 월=0 ~ 일=6)
/// weekStart는 해당 주의 월요일 자정이어야 한다
final weeklyFocusListProvider =
    Provider.family<List<int>, DateTime>((ref, weekStart) {
  final allLogs = ref.watch(allTimerLogsRawProvider);
  final focusLogs = _parseFocusLogs(allLogs);

  // 주 끝: 일요일 23:59:59
  final weekEnd = weekStart.add(const Duration(days: 7));

  final filtered = focusLogs.where(
      (log) => !log.startTime.isBefore(weekStart) &&
          log.startTime.isBefore(weekEnd));

  // 요일별 집중 시간(분) 집계 (월=0 ~ 일=6)
  final dayMinutes = List.filled(7, 0);
  for (final log in filtered) {
    // DateTime.weekday: 1(월) ~ 7(일) → index: 0 ~ 6
    final dayIndex = log.startTime.weekday - 1;
    dayMinutes[dayIndex] += log.durationSeconds ~/ 60;
  }
  return dayMinutes;
});

// ─── 주간 통계 요약 ──────────────────────────────────────────────────────

/// 특정 주의 통계 요약
/// weekStart는 해당 주의 월요일 자정이어야 한다
final weeklyStatsProvider =
    Provider.family<TimerWeeklyStats, DateTime>((ref, weekStart) {
  final dayMinutes = ref.watch(weeklyFocusListProvider(weekStart));
  final allLogs = ref.watch(allTimerLogsRawProvider);
  final focusLogs = _parseFocusLogs(allLogs);

  final weekEnd = weekStart.add(const Duration(days: 7));
  final sessionCount = focusLogs
      .where((log) => !log.startTime.isBefore(weekStart) &&
          log.startTime.isBefore(weekEnd))
      .length;

  final totalMinutes = dayMinutes.fold<int>(0, (sum, m) => sum + m);
  final activeDays = dayMinutes.where((m) => m > 0).length;

  return TimerWeeklyStats(
    totalFocusMinutes: totalMinutes,
    totalSessions: sessionCount,
    activeDays: activeDays,
    dailyAverage: totalMinutes / 7.0,
  );
});

// ─── 월간 통계 요약 ──────────────────────────────────────────────────────

/// 특정 월의 통계 요약
final monthlyStatsProvider =
    Provider.family<TimerMonthlyStats, DateTime>((ref, month) {
  final dayMap = ref.watch(monthlyFocusMapProvider(month));
  final sessionMap = ref.watch(monthlySessionMapProvider(month));

  // 해당 월의 총 일수
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

  final totalMinutes = dayMap.values.fold<int>(0, (sum, m) => sum + m);
  final totalSessions = sessionMap.values.fold<int>(0, (sum, c) => sum + c);
  final activeDays = dayMap.keys.where((d) => (dayMap[d] ?? 0) > 0).length;

  // 최장 연속 집중 일수(스트릭) 계산
  final longestStreak = _calcLongestStreak(dayMap, daysInMonth);

  return TimerMonthlyStats(
    totalFocusMinutes: totalMinutes,
    totalSessions: totalSessions,
    activeDays: activeDays,
    dailyAverage: daysInMonth > 0 ? totalMinutes / daysInMonth : 0,
    longestStreak: longestStreak,
  );
});

/// 월 내 최장 연속 집중 일수를 계산한다
int _calcLongestStreak(Map<int, int> dayMap, int daysInMonth) {
  int longest = 0;
  int current = 0;
  for (int d = 1; d <= daysInMonth; d++) {
    if ((dayMap[d] ?? 0) > 0) {
      current++;
      if (current > longest) longest = current;
    } else {
      current = 0;
    }
  }
  return longest;
}

// ─── 현재 주 월요일 계산 헬퍼 ─────────────────────────────────────────────

/// 주어진 날짜가 속한 주의 월요일 자정을 반환한다
DateTime mondayOfWeek(DateTime date) {
  // DateTime.weekday: 1(월) ~ 7(일)
  final diff = date.weekday - 1;
  return DateTime(date.year, date.month, date.day - diff);
}
