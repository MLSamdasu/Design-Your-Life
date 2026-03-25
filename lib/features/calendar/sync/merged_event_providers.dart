// C0.CalSync: 앱 이벤트 + Google Calendar 이벤트 병합 Provider (일별/월별)
// DailyView와 WeeklyView에서 사용하는 이벤트 목록 병합 Provider를 제공한다.
// 날짜별 dot 표시용 맵 Provider는 merged_date_map_provider.dart에 분리되어 있다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/calendar_provider.dart';
import '../providers/event_provider.dart';
import '../../../shared/models/event.dart' show EventType;
import '../../timer/models/timer_log.dart';
import '../../../core/providers/data_store_providers.dart';
import 'sync_state_providers.dart';

// ─── 병합된 이벤트 Provider (일별) ──────────────────────────────────────────

/// 앱 이벤트 + Google Calendar 이벤트를 병합한 일별 Provider
/// DailyView에서 이 Provider를 watch하여 선택된 날짜의 모든 이벤트를 표시한다.
/// 시간순으로 정렬되며, 시간 없는 이벤트는 맨 뒤에 위치한다.
final mergedEventsForDayProvider = Provider<List<CalendarEvent>>((ref) {
  final appEvents = ref.watch(eventsForDayProvider);
  final googleEventsAsync = ref.watch(googleCalendarEventsProvider);
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  // 타이머 세션을 타임라인에 표시하기 위해 추가한다
  final timerEvents = ref.watch(timerLogsForCalendarDayProvider);

  // Google 이벤트 로딩 실패 또는 비활성화 시 빈 목록 사용
  final googleEvents = googleEventsAsync.valueOrNull ?? const [];

  // 선택된 날짜에 해당하는 Google 이벤트만 필터링한다
  final filteredGoogleEvents = googleEvents.where((e) {
    final sameDay = e.startDate.year == selectedDate.year &&
        e.startDate.month == selectedDate.month &&
        e.startDate.day == selectedDate.day;
    // 범위 이벤트: 선택된 날짜가 시작~종료 범위 내에 있으면 포함한다
    if (e.endDate != null) {
      return !selectedDate.isBefore(e.startDate) &&
          !selectedDate.isAfter(e.endDate!);
    }
    return sameDay;
  }).toList();

  // 앱 이벤트 + Google 이벤트 + 타이머 세션을 병합하여 시간순으로 정렬한다
  final merged = [...appEvents, ...filteredGoogleEvents, ...timerEvents];
  sortEventsByTime(merged);

  return merged;
});

// ─── 병합된 이벤트 Provider (월별) ──────────────────────────────────────────

/// 앱 이벤트 + Google Calendar 이벤트 + 타이머 세션을 병합한 월별 Provider
/// WeeklyView에서 주 단위로 이벤트를 필터링할 때 사용한다.
/// eventsForMonthProvider(앱+투두) + googleCalendarEventsProvider(Google)
/// + 타이머 세션(allTimerLogsRawProvider)을 합친다.
final mergedEventsForMonthProvider = Provider<List<CalendarEvent>>((ref) {
  // eventsForMonthProvider는 동기 Provider이므로 직접 사용한다
  final appEvents = ref.watch(eventsForMonthProvider);
  final googleEventsAsync = ref.watch(googleCalendarEventsProvider);
  final focusedMonth = ref.watch(focusedCalendarMonthProvider);
  final allTimerLogsRaw = ref.watch(allTimerLogsRawProvider);
  // Google 이벤트 (비활성화 또는 로딩 실패 시 빈 목록)
  final googleEvents = googleEventsAsync.valueOrNull ?? const [];

  // 타이머 세션을 CalendarEvent로 변환한다 (해당 월 + 집중 세션만)
  final timerEvents = _buildTimerEventsForMonth(allTimerLogsRaw, focusedMonth);

  // 병합하여 시간순으로 정렬한다
  final merged = [...appEvents, ...googleEvents, ...timerEvents];
  sortEventsByTime(merged);

  return merged;
});

// ─── 공유 헬퍼 함수 ─────────────────────────────────────────────────────────

/// 이벤트를 시간순으로 정렬한다 (시간 없는 종일 이벤트는 맨 뒤)
/// merged_date_map_provider.dart에서도 사용할 수 있도록 패키지 레벨로 공개한다
void sortEventsByTime(List<CalendarEvent> events) {
  events.sort((a, b) {
    final aTime = (a.startHour ?? 24) * 60 + (a.startMinute ?? 0);
    final bTime = (b.startHour ?? 24) * 60 + (b.startMinute ?? 0);
    return aTime.compareTo(bTime);
  });
}

// ─── 내부 헬퍼 함수 ─────────────────────────────────────────────────────────

/// 타이머 로그를 해당 월의 CalendarEvent 목록으로 변환한다
List<CalendarEvent> _buildTimerEventsForMonth(
  List<Map<String, dynamic>> allTimerLogsRaw,
  DateTime focusedMonth,
) {
  final monthStr =
      '${focusedMonth.year}-${focusedMonth.month.toString().padLeft(2, '0')}';
  final timerEvents = <CalendarEvent>[];

  for (final logMap in allTimerLogsRaw) {
    final log = TimerLog.fromMap(logMap);
    // 집중 세션만 표시한다 (휴식은 제외)
    if (log.type != TimerSessionType.focus) continue;
    // 해당 월의 로그만 필터링한다
    final logDateStr = log.startTime.toIso8601String();
    if (!logDateStr.startsWith(monthStr)) continue;

    final durationMinutes = log.durationSeconds ~/ 60;
    final endTotalMinutes =
        log.startTime.hour * 60 + log.startTime.minute + durationMinutes;
    final endHour = (endTotalMinutes ~/ 60).clamp(0, 23);
    final endMinute = endTotalMinutes % 60;

    timerEvents.add(CalendarEvent(
      id: 'timer_${log.id}',
      title: log.todoTitle ?? '집중 세션',
      startDate: DateTime(
        log.startTime.year,
        log.startTime.month,
        log.startTime.day,
      ),
      startHour: log.startTime.hour,
      startMinute: log.startTime.minute,
      endHour: endHour,
      endMinute: endMinute,
      colorIndex: 3, // 운동/건강 초록 계열 — 타이머 세션에 적합
      type: EventType.normal.name,
      source: 'timer',
    ));
  }

  return timerEvents;
}
