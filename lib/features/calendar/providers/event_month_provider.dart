// 월별 이벤트 Provider
// eventsForMonthProvider: 선택된 월의 이벤트+투두를 CalendarEvent로 변환한다
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/data_store_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/event.dart';
import '../../../shared/models/todo.dart';
import 'event_provider.dart';
import 'rrule_parser.dart';
import 'calendar_provider.dart';

/// 선택된 월의 이벤트 Provider (동기 Provider)
/// allEventsRawProvider + allTodosRawProvider(Single Source of Truth)에서 파생한다.
final eventsForMonthProvider = Provider<List<CalendarEvent>>((ref) {
  final focusedMonth = ref.watch(focusedCalendarMonthProvider);
  final repository = ref.watch(eventRepositoryProvider);
  final allEventsRaw = ref.watch(allEventsRawProvider);
  final allTodosRaw = ref.watch(allTodosRawProvider);

  // ─── 1. eventsBox에서 해당 월의 이벤트를 조회한다 ─────────────────────────
  final events = repository.getEventsForMonth(
    focusedMonth.year,
    focusedMonth.month,
  );

  // ─── 1-b. 반복 이벤트는 start_date가 이전 월일 수 있으므로 전체에서 추가 조회한다 ───
  final allRecurringEvents = allEventsRaw
      .where((map) =>
          (map['event_type'] ?? map['eventType'] ?? map['type'])
              ?.toString() ==
          'recurring')
      .map((m) => Event.fromMap(m))
      .toList();

  final existingIds = events.map((e) => e.id).toSet();
  final extraRecurring = allRecurringEvents
      .where((e) => !existingIds.contains(e.id))
      .toList();
  final allEvents = <Event>[...events, ...extraRecurring];

  final monthStart =
      DateTime(focusedMonth.year, focusedMonth.month, 1);
  final monthEnd = DateTime(
      focusedMonth.year, focusedMonth.month + 1, 0, 23, 59, 59);

  // ─── 1-c. 범위 이벤트도 이전 월 시작이지만 이번 달에 걸치는 경우를 처리한다 ───
  final monthStartStr = AppDateUtils.toDateString(monthStart);
  final allExistingIds = allEvents.map((e) => e.id).toSet();
  final extraRangeEvents = allEventsRaw
      .where((map) {
        final type = (map['event_type'] ?? map['eventType'] ?? map['type'])
            ?.toString();
        if (type != 'range') return false;
        final endDateRaw =
            (map['end_date'] ?? map['endDate'])?.toString();
        if (endDateRaw == null) return false;
        final endDatePart = endDateRaw.length >= 10
            ? endDateRaw.substring(0, 10)
            : endDateRaw;
        return endDatePart.compareTo(monthStartStr) >= 0;
      })
      .map((m) => Event.fromMap(m))
      .where((e) => !allExistingIds.contains(e.id))
      .toList();
  allEvents.addAll(extraRangeEvents);

  // Event → CalendarEvent 변환 (반복 이벤트는 확장)
  final calendarEvents = <CalendarEvent>[];
  for (final event in allEvents) {
    final hasTime = !event.allDay;
    if (event.recurrenceRule != null &&
        event.recurrenceRule!.isNotEmpty) {
      final occurrences =
          expandRecurringEvent(event, monthStart, monthEnd);
      for (final date in occurrences) {
        calendarEvents.add(_eventToCalendar(event, date, hasTime));
      }
    } else {
      calendarEvents.add(_eventToCalendarDirect(event, hasTime));
    }
  }

  // ─── 2. 투두를 CalendarEvent로 변환한다 ─────────────────────────────────
  final todoCalendarEvents =
      getTodosAsCalendarEvents(allTodosRaw, focusedMonth);

  return [...calendarEvents, ...todoCalendarEvents];
});

/// 반복 이벤트 인스턴스를 CalendarEvent로 변환한다
CalendarEvent _eventToCalendar(
  Event event,
  DateTime date,
  bool hasTime,
) {
  return CalendarEvent(
    id: '${event.id}_${AppDateUtils.toDateString(date).replaceAll('-', '')}',
    title: event.title,
    startDate: date,
    startHour: hasTime ? event.startDate.hour : null,
    startMinute: hasTime ? event.startDate.minute : null,
    endHour: hasTime && event.endDate != null
        ? event.endDate!.hour
        : null,
    endMinute: hasTime && event.endDate != null
        ? event.endDate!.minute
        : null,
    colorIndex: event.colorIndex,
    type: event.eventType.name,
    rangeTag: event.rangeTag?.name,
    memo: event.memo,
    location: event.location,
    isAllDay: event.allDay,
  );
}

/// 비반복 이벤트를 CalendarEvent로 변환한다
CalendarEvent _eventToCalendarDirect(Event event, bool hasTime) {
  return CalendarEvent(
    id: event.id,
    title: event.title,
    startDate: event.startDate,
    endDate: event.endDate,
    startHour: hasTime ? event.startDate.hour : null,
    startMinute: hasTime ? event.startDate.minute : null,
    endHour: hasTime && event.endDate != null
        ? event.endDate!.hour
        : null,
    endMinute: hasTime && event.endDate != null
        ? event.endDate!.minute
        : null,
    colorIndex: event.colorIndex,
    type: event.eventType.name,
    rangeTag: event.rangeTag?.name,
    memo: event.memo,
    location: event.location,
    isAllDay: event.allDay,
  );
}

/// allTodosRawProvider에서 해당 월의 투두를 필터링하여 CalendarEvent로 변환한다
List<CalendarEvent> getTodosAsCalendarEvents(
  List<Map<String, dynamic>> allTodosRaw,
  DateTime focusedMonth,
) {
  final startStr = AppDateUtils.toDateString(
      DateTime(focusedMonth.year, focusedMonth.month, 1));
  final lastDay =
      DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
  final endStr = AppDateUtils.toDateString(lastDay);

  final todoMaps = allTodosRaw.where((map) {
    final raw = map['scheduled_date'] as String?;
    if (raw == null) return false;
    final datePart =
        raw.length >= 10 ? raw.substring(0, 10) : raw;
    return datePart.compareTo(startStr) >= 0 &&
        datePart.compareTo(endStr) <= 0;
  }).toList();

  return todoMaps.map((map) {
    final todo = Todo.fromMap(map);
    return todoToCalendarEvent(todo);
  }).toList();
}

/// 단일 Todo를 CalendarEvent로 변환한다
CalendarEvent todoToCalendarEvent(Todo todo) {
  return CalendarEvent(
    id: 'todo_${todo.id}',
    title: todo.title,
    startDate: todo.date,
    startHour: todo.startTime?.hour,
    startMinute: todo.startTime?.minute,
    endHour: todo.endTime?.hour,
    endMinute: todo.endTime?.minute,
    colorIndex: todo.colorIndex,
    type: EventType.todo.name,
    memo: todo.memo,
    isAllDay: todo.startTime == null,
    source: todo.isCompleted ? 'todo_completed' : 'todo',
  );
}
