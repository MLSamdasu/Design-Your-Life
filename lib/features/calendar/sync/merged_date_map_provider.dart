// C0.CalSync: 날짜별 이벤트 유무 맵 Provider
// MonthlyView에서 날짜 셀에 dot을 표시할 때 사용한다.
// 앱 이벤트 + Google 이벤트 + 루틴 + 습관 로그를 병합한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/calendar_provider.dart';
import '../providers/event_provider.dart';
import '../../../shared/models/habit_log.dart';
import '../../../shared/models/routine.dart';
import '../../../core/providers/data_store_providers.dart';
import '../../../core/utils/date_utils.dart';
import 'sync_state_providers.dart';

// ─── 병합된 날짜별 이벤트 유무 맵 Provider ─────────────────────────────────

/// 날짜별 이벤트 유무 맵 (앱 + Google 이벤트 병합)
/// MonthlyView에서 날짜 셀에 dot을 표시할 때 사용한다.
/// 앱 이벤트와 Google 이벤트 모두 dot을 표시한다.
final mergedEventsByDateMapProvider = Provider<Map<String, bool>>((ref) {
  // 앱 이벤트 날짜 맵 (기존 provider 재사용)
  final appMap = ref.watch(eventsByDateMapProvider);
  // Google 이벤트 목록
  final googleEventsAsync = ref.watch(googleCalendarEventsProvider);
  final googleEvents = googleEventsAsync.valueOrNull ?? const [];
  // 활성 루틴 목록 (월간 dot 표시용)
  final allRoutinesRaw = ref.watch(allRoutinesRawProvider);
  final focusedMonth = ref.watch(focusedCalendarMonthProvider);
  // 습관 로그 (완료된 날짜 dot 표시용)
  final allHabitLogsRaw = ref.watch(allHabitLogsRawProvider);

  // 앱 이벤트 맵을 기반으로 Google 이벤트 날짜를 추가한다
  final merged = Map<String, bool>.from(appMap);
  _addGoogleEventDates(merged, googleEvents);
  _addRoutineDates(merged, allRoutinesRaw, focusedMonth);
  _addHabitLogDates(merged, allHabitLogsRaw, focusedMonth);

  return merged;
});

// ─── 내부 헬퍼 함수 ─────────────────────────────────────────────────────────

/// Google 이벤트 날짜를 맵에 추가한다 (다중일 이벤트 중간 날짜 포함)
void _addGoogleEventDates(
  Map<String, bool> merged,
  List<CalendarEvent> googleEvents,
) {
  for (final event in googleEvents) {
    final startDay = DateTime(
      event.startDate.year, event.startDate.month, event.startDate.day,
    );
    merged[AppDateUtils.toDateString(startDay)] = true;
    if (event.endDate != null) {
      final endDay = DateTime(
        event.endDate!.year, event.endDate!.month, event.endDate!.day,
      );
      var cursor = startDay.add(const Duration(days: 1));
      while (!cursor.isAfter(endDay)) {
        merged[AppDateUtils.toDateString(cursor)] = true;
        cursor = cursor.add(const Duration(days: 1));
      }
    }
  }
}

/// 활성 루틴의 해당 월 날짜를 맵에 추가한다
void _addRoutineDates(
  Map<String, bool> merged,
  List<Map<String, dynamic>> allRoutinesRaw,
  DateTime focusedMonth,
) {
  final activeRoutines = allRoutinesRaw
      .map((map) => Routine.fromMap(map))
      .where((r) => r.isActive)
      .toList();

  if (activeRoutines.isEmpty) return;

  // 포커스된 월의 모든 날짜를 순회하며 루틴 요일과 매칭한다
  final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
  final lastDay = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);

  for (var day = firstDay;
      !day.isAfter(lastDay);
      day = day.add(const Duration(days: 1))) {
    final weekday = day.weekday;
    final hasRoutine =
        activeRoutines.any((r) => r.repeatDays.contains(weekday));
    if (hasRoutine) {
      merged[AppDateUtils.toDateString(day)] = true;
    }
  }
}

/// 습관 로그(완료된 날짜)를 맵에 추가한다
void _addHabitLogDates(
  Map<String, bool> merged,
  List<Map<String, dynamic>> allHabitLogsRaw,
  DateTime focusedMonth,
) {
  for (final logMap in allHabitLogsRaw) {
    final log = HabitLog.fromMap(logMap);
    if (log.isCompleted &&
        log.date.year == focusedMonth.year &&
        log.date.month == focusedMonth.month) {
      merged[AppDateUtils.toDateString(log.date)] = true;
    }
  }
}
