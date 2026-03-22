// F2: 이벤트 데이터 Provider (Single Source of Truth 아키텍처)
// allEventsRawProvider + allTodosRawProvider에서 파생하여 자동 동기화된다.
// eventsForMonthProvider: 선택된 월의 이벤트 목록 (동기 Provider)
// eventsForDayProvider: 선택된 날짜의 이벤트 목록
// routinesForDayProvider: 해당 날짜에 활성화된 루틴 목록
import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../shared/models/event.dart';
import '../../../shared/models/habit.dart';
import '../../../shared/models/habit_log.dart';
import '../../../shared/models/routine.dart';
import '../../../shared/models/todo.dart';
import '../../timer/models/timer_log.dart';
import '../services/event_repository.dart';
import '../../habit/providers/routine_provider.dart';
import 'calendar_provider.dart';

// ─── Repository Provider ─────────────────────────────────────────────────────

/// EventRepository Provider (로컬 퍼스트)
/// HiveCacheService를 주입받아 로컬 Hive 저장소에 접근한다
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  // HiveCacheService를 주입한다 (로컬 퍼스트 아키텍처)
  final cache = ref.watch(hiveCacheServiceProvider);
  return EventRepository(cache: cache);
});

// ─── CRUD 액션 Provider ──────────────────────────────────────────────────────

/// 이벤트 생성 액션 Provider
/// 로컬 Hive에 즉시 저장하고 월별 이벤트 목록을 다시 로드한다
final createEventProvider =
    Provider<Future<void> Function(Event)>((ref) {
  final repository = ref.watch(eventRepositoryProvider);

  return (Event event) async {
    try {
      await repository.createEvent(event);
      // 버전 카운터 증가 → allEventsRawProvider 재평가 → 캘린더/홈/타임라인 모두 자동 갱신
      ref.read(eventDataVersionProvider.notifier).state++;
    } catch (e) {
      rethrow;
    }
  };
});

/// 이벤트 수정 액션 Provider
final updateEventProvider =
    Provider<Future<void> Function(Event)>((ref) {
  final repository = ref.watch(eventRepositoryProvider);

  return (Event event) async {
    try {
      await repository.updateEvent(event.id, event);
      // 버전 카운터 증가 → 모든 파생 Provider 자동 갱신
      ref.read(eventDataVersionProvider.notifier).state++;
    } catch (e) {
      rethrow;
    }
  };
});

/// 이벤트 삭제 액션 Provider
final deleteEventProvider =
    Provider<Future<void> Function(String)>((ref) {
  final repository = ref.watch(eventRepositoryProvider);

  return (String eventId) async {
    try {
      await repository.deleteEvent(eventId);
      // 버전 카운터 증가 → 모든 파생 Provider 자동 갱신
      ref.read(eventDataVersionProvider.notifier).state++;
    } catch (e) {
      rethrow;
    }
  };
});

/// 새 이벤트 ID 생성 헬퍼 Provider
/// 로컬 퍼스트 아키텍처에서는 EventRepository 내부에서 UUID를 생성하므로
/// 이 Provider는 하위 호환성을 위해 유지한다
final generateEventIdProvider = Provider<String Function()>((ref) {
  return () {
    return const Uuid().v4();
  };
});

/// 캘린더에 표시할 이벤트 데이터 모델 (뷰용)
class CalendarEvent {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime? endDate;
  final int? startHour;
  final int? startMinute;
  final int? endHour;
  final int? endMinute;
  final int colorIndex;
  final String type; // normal, range, recurring, todo
  final String? rangeTag;
  final String? memo;
  final String? location;

  /// 종일 이벤트 여부 (true이면 시간 없이 종일 표시)
  final bool isAllDay;

  /// 이벤트 출처 (F17: Google Calendar 연동)
  /// 'app': 앱에서 생성한 이벤트 (기본값, 기존 동작 유지)
  /// 'google': Google Calendar에서 가져온 이벤트
  final String source;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startDate,
    this.endDate,
    this.startHour,
    this.startMinute,
    this.endHour,
    this.endMinute,
    required this.colorIndex,
    required this.type,
    this.rangeTag,
    this.memo,
    this.location,
    this.isAllDay = false,
    this.source = 'app', // 기본값: 앱 이벤트 (하위 호환 보장)
  });

  /// Google Calendar에서 가져온 이벤트인지 여부
  bool get isGoogleEvent => source == 'google';

  /// todosBox에서 변환된 투두 이벤트인지 여부
  bool get isTodoEvent => source == 'todo' || source == 'todo_completed';

  /// 투두가 완료 상태인지 여부
  bool get isTodoCompleted => source == 'todo_completed';

  /// 이벤트 색상 (colorIndex 기준)
  Color get color => ColorTokens.eventColor(colorIndex);
}

/// 루틴 캘린더 표시용 데이터 모델
class RoutineEntry {
  final String id;
  final String name;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final int colorIndex;

  const RoutineEntry({
    required this.id,
    required this.name,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.colorIndex,
  });
}

/// 선택된 월의 이벤트 Provider (동기 Provider)
/// allEventsRawProvider + allTodosRawProvider(Single Source of Truth)에서 파생한다.
/// 이벤트/투두 CRUD 시 버전 카운터 증가 → 이 Provider 자동 갱신
/// Hive 조회는 모두 동기 연산이므로 FutureProvider가 불필요하다.
final eventsForMonthProvider = Provider<List<CalendarEvent>>((ref) {
  final focusedMonth = ref.watch(focusedCalendarMonthProvider);
  final repository = ref.watch(eventRepositoryProvider);
  // Single Source of Truth: allEventsRawProvider에서 파생한다
  final allEventsRaw = ref.watch(allEventsRawProvider);
  // 투두 변경도 캘린더에 반영하기 위해 allTodosRawProvider도 watch한다
  final allTodosRaw = ref.watch(allTodosRawProvider);

  // ─── 1. eventsBox에서 해당 월의 이벤트를 조회한다 ─────────────────────────
  final events = repository.getEventsForMonth(
    focusedMonth.year,
    focusedMonth.month,
  );

  // ─── 1-b. 반복 이벤트는 start_date가 이전 월일 수 있으므로 전체에서 추가 조회한다 ───
  final allRecurringEvents = allEventsRaw
      .where((map) => (map['event_type'] ?? map['eventType'] ?? map['type'])?.toString() == 'recurring')
      .map((m) => Event.fromMap(m))
      .toList();

  // 이미 events에 포함된 반복 이벤트 ID를 중복 방지용으로 수집한다
  final existingIds = events.map((e) => e.id).toSet();
  final extraRecurring = allRecurringEvents
      .where((e) => !existingIds.contains(e.id))
      .toList();
  final allEvents = <Event>[...events, ...extraRecurring];

  // 해당 월의 시작일과 종료일 (반복 이벤트 확장 범위 + 범위 이벤트 필터링에 사용)
  final monthStart = DateTime(focusedMonth.year, focusedMonth.month, 1);
  final monthEnd = DateTime(focusedMonth.year, focusedMonth.month + 1, 0, 23, 59, 59);

  // ─── 1-c. 범위 이벤트(range)도 start_date가 이전 월이지만 end_date가 이번 달에 걸치는 경우를 처리한다 ───
  final monthStartStr = AppDateUtils.toDateString(monthStart);
  // 기존 이벤트 + 추가된 반복 이벤트의 ID를 모두 포함하여 중복을 방지한다
  final allExistingIds = allEvents.map((e) => e.id).toSet();
  final extraRangeEvents = allEventsRaw
      .where((map) {
        final type = (map['event_type'] ?? map['eventType'] ?? map['type'])?.toString();
        if (type != 'range') return false;
        final endDateRaw = (map['end_date'] ?? map['endDate'])?.toString();
        if (endDateRaw == null) return false;
        final endDatePart = endDateRaw.length >= 10 ? endDateRaw.substring(0, 10) : endDateRaw;
        // end_date가 이번 달 시작일 이상이면 이번 달에 걸치는 범위 이벤트이다
        return endDatePart.compareTo(monthStartStr) >= 0;
      })
      .map((m) => Event.fromMap(m))
      .where((e) => !allExistingIds.contains(e.id))
      .toList();
  allEvents.addAll(extraRangeEvents);

  // Event 모델 → CalendarEvent 뷰 모델 변환 (반복 이벤트는 확장한다)
  final calendarEvents = <CalendarEvent>[];
  for (final event in allEvents) {
    final hasTime = !event.allDay;
    if (event.recurrenceRule != null && event.recurrenceRule!.isNotEmpty) {
      // 반복 이벤트: RRULE을 파싱하여 해당 월 내 모든 발생일을 생성한다
      final occurrences = _expandRecurringEvent(event, monthStart, monthEnd);
      for (final date in occurrences) {
        calendarEvents.add(CalendarEvent(
          id: '${event.id}_${AppDateUtils.toDateString(date).replaceAll('-', '')}',
          title: event.title,
          startDate: date,
          endDate: null,
          startHour: hasTime ? event.startDate.hour : null,
          startMinute: hasTime ? event.startDate.minute : null,
          endHour: hasTime && event.endDate != null ? event.endDate!.hour : null,
          endMinute: hasTime && event.endDate != null ? event.endDate!.minute : null,
          colorIndex: event.colorIndex,
          type: event.eventType.name,
          rangeTag: event.rangeTag?.name,
          memo: event.memo,
          location: event.location,
          isAllDay: event.allDay,
        ));
      }
    } else {
      // 비반복 이벤트: 기존 로직 그대로 변환한다
      calendarEvents.add(CalendarEvent(
        id: event.id,
        title: event.title,
        startDate: event.startDate,
        endDate: event.endDate,
        startHour: hasTime ? event.startDate.hour : null,
        startMinute: hasTime ? event.startDate.minute : null,
        endHour: hasTime && event.endDate != null ? event.endDate!.hour : null,
        endMinute:
            hasTime && event.endDate != null ? event.endDate!.minute : null,
        colorIndex: event.colorIndex,
        type: event.eventType.name,
        rangeTag: event.rangeTag?.name,
        memo: event.memo,
        location: event.location,
        isAllDay: event.allDay,
      ));
    }
  }

  // ─── 2. todosBox에서 해당 월의 투두를 조회하여 CalendarEvent로 변환한다 ────
  final todoCalendarEvents = _getTodosAsCalendarEvents(allTodosRaw, focusedMonth);

  // ─── 3. 이벤트 + 투두를 병합하여 반환한다 ─────────────────────────────────
  return [...calendarEvents, ...todoCalendarEvents];
});

/// 반복 이벤트의 RRULE을 파싱하여 해당 월 범위 내 발생 날짜 목록을 반환한다
/// 지원 패턴: FREQ=DAILY, FREQ=WEEKLY;BYDAY=MO,WE,FR, FREQ=MONTHLY;BYMONTHDAY=15,
/// FREQ=YEARLY (P1-8: 매년 시작일과 동일한 월/일에 반복)
List<DateTime> _expandRecurringEvent(
  Event event,
  DateTime monthStart,
  DateTime monthEnd,
) {
  final rule = event.recurrenceRule;
  if (rule == null || rule.isEmpty) return [];

  // RRULE 파싱: 세미콜론으로 분리한 key=value 맵을 만든다
  final parts = rule.replaceFirst('RRULE:', '').split(';');
  final ruleMap = <String, String>{};
  for (final part in parts) {
    final kv = part.split('=');
    if (kv.length == 2) {
      ruleMap[kv[0].toUpperCase()] = kv[1].toUpperCase();
    }
  }

  final freq = ruleMap['FREQ'];
  if (freq == null) return [];

  // 이벤트 시작일 이전 날짜에는 인스턴스를 생성하지 않는다
  final eventStart = DateTime(
    event.startDate.year,
    event.startDate.month,
    event.startDate.day,
  );
  // 탐색 범위의 시작일은 이벤트 시작일과 월 시작일 중 늦은 날짜를 사용한다
  final rangeStart = eventStart.isAfter(monthStart) ? eventStart : monthStart;

  final occurrences = <DateTime>[];

  switch (freq) {
    case 'DAILY':
      // 매일 반복: 범위 내 모든 날짜를 추가한다
      var current = rangeStart;
      while (!current.isAfter(monthEnd)) {
        occurrences.add(current);
        current = current.add(const Duration(days: 1));
      }
      break;

    case 'WEEKLY':
      // 주간 반복: BYDAY에 지정된 요일만 추가한다
      final byDay = ruleMap['BYDAY'];
      if (byDay == null) break;

      // RRULE 요일 약어를 Dart weekday (1=월 ~ 7=일)로 변환한다
      const dayMap = {
        'MO': 1, 'TU': 2, 'WE': 3, 'TH': 4,
        'FR': 5, 'SA': 6, 'SU': 7,
      };
      final targetDays = byDay
          .split(',')
          .map((d) => dayMap[d.trim()])
          .whereType<int>()
          .toSet();

      if (targetDays.isEmpty) break;

      var current = rangeStart;
      while (!current.isAfter(monthEnd)) {
        if (targetDays.contains(current.weekday)) {
          occurrences.add(current);
        }
        current = current.add(const Duration(days: 1));
      }
      break;

    case 'MONTHLY':
      // 월간 반복: BYMONTHDAY에 지정된 날짜를 추가한다
      final byMonthDay = ruleMap['BYMONTHDAY'];
      if (byMonthDay == null) {
        // BYMONTHDAY가 없으면 이벤트 시작일의 day를 사용한다
        final day = event.startDate.day;
        final lastDayOfMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
        if (day <= lastDayOfMonth) {
          final candidate = DateTime(monthStart.year, monthStart.month, day);
          if (!candidate.isBefore(eventStart) && !candidate.isAfter(monthEnd)) {
            occurrences.add(candidate);
          }
        }
      } else {
        // BYMONTHDAY 파싱 (쉼표로 여러 날짜 지정 가능)
        final days = byMonthDay
            .split(',')
            .map((d) => int.tryParse(d.trim()))
            .whereType<int>();
        final lastDayOfMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
        for (final day in days) {
          if (day >= 1 && day <= lastDayOfMonth) {
            final candidate = DateTime(monthStart.year, monthStart.month, day);
            if (!candidate.isBefore(eventStart) && !candidate.isAfter(monthEnd)) {
              occurrences.add(candidate);
            }
          }
        }
      }
      break;

    case 'YEARLY':
      // P1-8: 연간 반복 — 매년 시작일과 동일한 월/일에 발생한다
      // BYMONTH/BYMONTHDAY가 지정되어 있으면 해당 값을 사용한다
      final byMonth = ruleMap['BYMONTH'];
      final byMonthDayY = ruleMap['BYMONTHDAY'];
      final targetMonth = byMonth != null
          ? int.tryParse(byMonth) ?? event.startDate.month
          : event.startDate.month;
      final targetDay = byMonthDayY != null
          ? int.tryParse(byMonthDayY) ?? event.startDate.day
          : event.startDate.day;

      // 현재 표시 중인 월이 대상 월과 일치하는지 확인한다
      if (monthStart.month == targetMonth) {
        final lastDayOfMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
        if (targetDay >= 1 && targetDay <= lastDayOfMonth) {
          final candidate = DateTime(monthStart.year, targetMonth, targetDay);
          if (!candidate.isBefore(eventStart) && !candidate.isAfter(monthEnd)) {
            occurrences.add(candidate);
          }
        }
      }
      break;
  }

  return occurrences;
}

/// allTodosRawProvider에서 해당 월의 투두를 필터링하여 CalendarEvent 리스트로 변환한다
/// Single Source of Truth에서 파생하므로 투두 CRUD 시 자동 갱신된다
List<CalendarEvent> _getTodosAsCalendarEvents(
  List<Map<String, dynamic>> allTodosRaw,
  DateTime focusedMonth,
) {
  // 해당 월의 시작/종료 날짜 문자열을 생성한다
  final startStr = AppDateUtils.toDateString(DateTime(focusedMonth.year, focusedMonth.month, 1));
  final lastDay = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
  final endStr = AppDateUtils.toDateString(lastDay);

  // allTodosRawProvider에서 해당 월의 투두만 필터링한다
  final todoMaps = allTodosRaw.where((map) {
    final raw = map['scheduled_date'] as String?;
    if (raw == null) return false;
    final datePart = raw.length >= 10 ? raw.substring(0, 10) : raw;
    return datePart.compareTo(startStr) >= 0 &&
        datePart.compareTo(endStr) <= 0;
  }).toList();

  // Todo 모델로 파싱 후 CalendarEvent로 변환한다
  return todoMaps.map((map) {
    final todo = Todo.fromMap(map);
    return _todoToCalendarEvent(todo);
  }).toList();
}

/// 단일 Todo를 CalendarEvent로 변환한다
/// Todo의 startTime/endTime을 CalendarEvent의 시간 필드에 매핑한다
CalendarEvent _todoToCalendarEvent(Todo todo) {
  return CalendarEvent(
    id: 'todo_${todo.id}', // 이벤트 ID와 충돌 방지를 위해 접두사를 붙인다
    title: todo.title,
    startDate: todo.date,
    endDate: null,
    startHour: todo.startTime?.hour,
    startMinute: todo.startTime?.minute,
    endHour: todo.endTime?.hour,
    endMinute: todo.endTime?.minute,
    colorIndex: todo.colorIndex,
    type: EventType.todo.name, // 'todo' 타입으로 구분한다
    memo: todo.memo,
    // 시작 시간이 없으면 종일 이벤트로 간주한다
    isAllDay: todo.startTime == null,
    source: todo.isCompleted ? 'todo_completed' : 'todo', // 완료 상태를 source로 전달한다
  );
}

/// 선택된 날짜의 이벤트 Provider (파생)
/// eventsForMonthProvider가 동기 Provider이므로 직접 데이터를 사용한다
final eventsForDayProvider = Provider<List<CalendarEvent>>((ref) {
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final events = ref.watch(eventsForMonthProvider);

  return events.where((e) {
    // P2-3: 날짜 비교 시 시간 컴포넌트를 제외하여 정확한 날짜 매칭을 수행한다
    final eventDay = DateTime(e.startDate.year, e.startDate.month, e.startDate.day);
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final sameDay = eventDay == selected;
    // 범위 일정은 해당 날짜가 범위 내에 있으면 표시
    if (e.endDate != null) {
      final endDay = DateTime(e.endDate!.year, e.endDate!.month, e.endDate!.day);
      return !selected.isBefore(eventDay) && !selected.isAfter(endDay);
    }
    return sameDay;
  }).toList()
    ..sort((a, b) {
      final aTime = (a.startHour ?? 24) * 60 + (a.startMinute ?? 0);
      final bTime = (b.startHour ?? 24) * 60 + (b.startMinute ?? 0);
      return aTime.compareTo(bTime);
    });
});

/// 날짜별 이벤트 맵 (월간 뷰의 dot 표시용)
/// P1-9: 다중일 이벤트의 중간 날짜에도 dot을 표시한다
/// eventsForMonthProvider가 동기 Provider이므로 직접 데이터를 사용한다
final eventsByDateMapProvider = Provider<Map<String, bool>>((ref) {
  final events = ref.watch(eventsForMonthProvider);
  final map = <String, bool>{};
  for (final event in events) {
    final startDay = DateTime(
      event.startDate.year, event.startDate.month, event.startDate.day,
    );
    map[AppDateUtils.toDateString(startDay)] = true;

    // P1-9: 종료일이 있는 다중일 이벤트의 경우 시작일~종료일 사이 모든 날짜에 dot을 표시한다
    if (event.endDate != null) {
      final endDay = DateTime(
        event.endDate!.year, event.endDate!.month, event.endDate!.day,
      );
      var cursor = startDay.add(const Duration(days: 1));
      while (!cursor.isAfter(endDay)) {
        map[AppDateUtils.toDateString(cursor)] = true;
        cursor = cursor.add(const Duration(days: 1));
      }
    }
  }
  return map;
});

/// 선택된 날짜의 루틴 Provider (동기 Provider)
/// routineRepositoryProvider를 통해 DI된 RoutineRepository를 사용한다.
/// 로컬 퍼스트: 인증 상태와 무관하게 항상 로컬 Hive에서 조회한다.
/// Hive 조회는 모두 동기 연산이므로 FutureProvider가 불필요하다.
final routinesForDayProvider = Provider<List<RoutineEntry>>((ref) {
  // 루틴 CRUD 후 반응적 갱신을 위해 allRoutinesRawProvider를 구독한다
  ref.watch(allRoutinesRawProvider);

  final selectedDate = ref.watch(selectedCalendarDateProvider);
  // weekday: 1=월 ~ 7=일
  final weekday = selectedDate.weekday;

  // DI된 RoutineRepository를 사용한다 (인라인 생성 대신)
  final routineRepo = ref.watch(routineRepositoryProvider);

  // 활성 루틴을 로컬 Hive에서 동기로 조회하여 해당 요일만 필터링한다
  final routines = routineRepo.getActiveRoutines();

  final filtered = routines
      .where((r) => r.repeatDays.contains(weekday))
      .map((r) {
    return RoutineEntry(
      id: r.id,
      name: r.name,
      startHour: r.startTime.hour,
      startMinute: r.startTime.minute,
      endHour: r.endTime.hour,
      endMinute: r.endTime.minute,
      colorIndex: r.colorIndex,
    );
  }).toList();

  filtered.sort((a, b) {
    final aTime = a.startHour * 60 + a.startMinute;
    final bTime = b.startHour * 60 + b.startMinute;
    return aTime.compareTo(bTime);
  });

  return filtered;
});

// ─── 주간 뷰용 루틴 Provider ────────────────────────────────────────────────

/// 주간 뷰용 루틴 데이터: 주의 각 날짜에 해당하는 RoutineEntry 목록을 반환한다
/// 키: DateTime(해당 날짜), 값: RoutineEntry 리스트(해당 요일의 활성 루틴)
/// selectedCalendarDateProvider의 주 기준으로 7일간 데이터를 생성한다
final routinesForWeekProvider =
    Provider<Map<DateTime, List<RoutineEntry>>>((ref) {
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final allRoutinesRaw = ref.watch(allRoutinesRawProvider);

  // 주 시작일(월요일) 계산
  final weekStart =
      selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

  // 활성 루틴만 파싱한다
  final activeRoutines = allRoutinesRaw
      .map((map) => Routine.fromMap(map))
      .where((r) => r.isActive)
      .toList();

  final result = <DateTime, List<RoutineEntry>>{};

  for (var i = 0; i < 7; i++) {
    final day = weekStart.add(Duration(days: i));
    // ISO 8601 weekday: 1=월 ~ 7=일
    final weekday = day.weekday;

    final dayRoutines = activeRoutines
        .where((r) => r.repeatDays.contains(weekday))
        .map((r) => RoutineEntry(
              id: r.id,
              name: r.name,
              startHour: r.startTime.hour,
              startMinute: r.startTime.minute,
              endHour: r.endTime.hour,
              endMinute: r.endTime.minute,
              colorIndex: r.colorIndex,
            ))
        .toList()
      ..sort((a, b) {
        final aMin = a.startHour * 60 + a.startMinute;
        final bMin = b.startHour * 60 + b.startMinute;
        return aMin.compareTo(bMin);
      });

    result[DateTime(day.year, day.month, day.day)] = dayRoutines;
  }

  return result;
});

// ─── 일간 뷰용 습관 Provider ────────────────────────────────────────────────

/// 일간 뷰용 습관 데이터: 선택된 날짜에 예정된 습관 목록과 완료 상태를 반환한다
/// 반환 타입: List<({Habit habit, bool isCompleted})>
final habitsForDayProvider =
    Provider<List<({Habit habit, bool isCompleted})>>((ref) {
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final allHabitsRaw = ref.watch(allHabitsRawProvider);
  final allHabitLogsRaw = ref.watch(allHabitLogsRawProvider);

  // 활성 습관 중 해당 날짜에 예정된 것만 필터링한다
  final activeHabits = allHabitsRaw
      .map((m) => Habit.fromMap(m))
      .where((h) => h.isActive && h.isScheduledFor(selectedDate))
      .toList();

  if (activeHabits.isEmpty) return const [];

  // 해당 날짜의 완료된 습관 ID 집합을 구한다
  final dateStr = AppDateUtils.toDateString(selectedDate);
  final completedHabitIds = <String>{};
  for (final logMap in allHabitLogsRaw) {
    final log = HabitLog.fromMap(logMap);
    if (log.isCompleted && AppDateUtils.toDateString(log.date) == dateStr) {
      completedHabitIds.add(log.habitId);
    }
  }

  return activeHabits
      .map((h) => (habit: h, isCompleted: completedHabitIds.contains(h.id)))
      .toList();
});

// ─── 주간 뷰 헤더용 습관 완료율 Provider ─────────────────────────────────────

/// 주간 뷰 헤더용 습관 완료율: 주의 각 날짜별 (완료수, 전체수) 반환
/// 키: DateTime (날짜), 값: ({int completed, int total})
final habitCompletionForWeekProvider =
    Provider<Map<DateTime, ({int completed, int total})>>((ref) {
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final allHabitsRaw = ref.watch(allHabitsRawProvider);
  final allHabitLogsRaw = ref.watch(allHabitLogsRawProvider);

  final weekStart =
      selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

  final activeHabits = allHabitsRaw
      .map((m) => Habit.fromMap(m))
      .where((h) => h.isActive)
      .toList();

  final result = <DateTime, ({int completed, int total})>{};

  for (var i = 0; i < 7; i++) {
    final day = weekStart.add(Duration(days: i));
    final dayKey = DateTime(day.year, day.month, day.day);
    // 해당 날짜에 예정된 습관만 필터링한다
    final scheduledHabits =
        activeHabits.where((h) => h.isScheduledFor(day)).toList();
    if (scheduledHabits.isEmpty) {
      result[dayKey] = (completed: 0, total: 0);
      continue;
    }

    // 해당 날짜의 완료된 습관 ID 집합
    final dateStr = AppDateUtils.toDateString(day);
    final completedIds = <String>{};
    for (final logMap in allHabitLogsRaw) {
      final log = HabitLog.fromMap(logMap);
      if (log.isCompleted && AppDateUtils.toDateString(log.date) == dateStr) {
        completedIds.add(log.habitId);
      }
    }

    final completedCount =
        scheduledHabits.where((h) => completedIds.contains(h.id)).length;
    result[dayKey] = (completed: completedCount, total: scheduledHabits.length);
  }

  return result;
});

// ─── 일간 뷰 타임라인용 타이머 세션 Provider ─────────────────────────────────

/// 일간 뷰 타임라인용 타이머 세션 데이터
/// focus 타입의 TimerLog를 CalendarEvent으로 변환하여 타임라인에 표시한다
/// 선택된 날짜의 집중 세션만 반환한다
final timerLogsForCalendarDayProvider =
    Provider<List<CalendarEvent>>((ref) {
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final allTimerLogsRaw = ref.watch(allTimerLogsRawProvider);

  final dateStr = AppDateUtils.toDateString(selectedDate);
  final events = <CalendarEvent>[];

  for (final logMap in allTimerLogsRaw) {
    final log = TimerLog.fromMap(logMap);
    // 집중 세션만 표시한다 (휴식은 표시하지 않는다)
    if (log.type != TimerSessionType.focus) continue;
    // 시작 시간 기준으로 해당 날짜인지 확인한다
    if (AppDateUtils.toDateString(log.startTime) != dateStr) continue;

    final durationMinutes = log.durationSeconds ~/ 60;
    final endTotalMinutes = log.startTime.hour * 60 + log.startTime.minute + durationMinutes;
    final endHour = (endTotalMinutes ~/ 60).clamp(0, 23);
    final endMinute = endTotalMinutes % 60;

    events.add(CalendarEvent(
      id: 'timer_${log.id}',
      title: log.todoTitle ?? '집중 세션',
      startDate: selectedDate,
      startHour: log.startTime.hour,
      startMinute: log.startTime.minute,
      endHour: endHour,
      endMinute: endMinute,
      colorIndex: 3, // 운동/건강 초록 계열 — 타이머 세션에 적합
      type: EventType.normal.name,
      source: 'timer',
    ));
  }

  // 시간순 정렬
  events.sort((a, b) {
    final aMin = (a.startHour ?? 0) * 60 + (a.startMinute ?? 0);
    final bMin = (b.startHour ?? 0) * 60 + (b.startMinute ?? 0);
    return aMin.compareTo(bMin);
  });

  return events;
});
