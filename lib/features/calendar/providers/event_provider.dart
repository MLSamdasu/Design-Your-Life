// F2: 이벤트 데이터 Provider (로컬 퍼스트 아키텍처)
// eventsForMonthProvider: 선택된 월의 이벤트 목록 (FutureProvider)
// eventsForDayProvider: 선택된 날짜의 이벤트 목록
// routinesForDayProvider: 해당 날짜에 활성화된 루틴 목록
// HiveCacheService를 직접 주입한다.
import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/global_providers.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../shared/models/event.dart';
import '../services/event_repository.dart';
import '../../habit/services/routine_repository.dart';
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
      repository.createEvent(event);
      // 생성 후 월별 이벤트를 다시 로드한다
      ref.invalidate(eventsForMonthProvider);
    } catch (e) {
      // 호출부에서 에러를 처리할 수 있도록 다시 던진다
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
      repository.updateEvent(event.id, event);
      // 수정 후 월별 이벤트를 다시 로드한다
      ref.invalidate(eventsForMonthProvider);
    } catch (e) {
      // 호출부에서 에러를 처리할 수 있도록 다시 던진다
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
      repository.deleteEvent(eventId);
      // 삭제 후 월별 이벤트를 다시 로드한다
      ref.invalidate(eventsForMonthProvider);
    } catch (e) {
      // 호출부에서 에러를 처리할 수 있도록 다시 던진다
      rethrow;
    }
  };
});

/// 새 이벤트 ID 생성 헬퍼 Provider
/// 로컬 퍼스트 아키텍처에서는 EventRepository 내부에서 UUID를 생성하므로
/// 이 Provider는 하위 호환성을 위해 유지한다
final generateEventIdProvider = Provider<String Function()>((ref) {
  return () {
    // 로컬 UUID 생성은 EventRepository.createEvent 내부에서 처리한다
    return DateTime.now().millisecondsSinceEpoch.toString();
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
    this.source = 'app', // 기본값: 앱 이벤트 (하위 호환 보장)
  });

  /// Google Calendar에서 가져온 이벤트인지 여부
  bool get isGoogleEvent => source == 'google';

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

/// 선택된 월의 이벤트 Provider (FutureProvider)
/// focusedCalendarMonthProvider를 watch하여 월 변경 시 자동 재로드한다
/// 로컬 퍼스트: 인증 상태와 무관하게 항상 로컬 Hive에서 조회한다
final eventsForMonthProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final focusedMonth = ref.watch(focusedCalendarMonthProvider);
  final repository = ref.watch(eventRepositoryProvider);

  // 로컬 Hive에서 해당 월의 이벤트를 조회한다
  final events = repository.getEventsForMonth(
    focusedMonth.year,
    focusedMonth.month,
  );

  // Event 모델 → CalendarEvent 뷰 모델 변환
  return events.map((event) {
    final hasTime = !event.allDay;
    return CalendarEvent(
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
    );
  }).toList();
});

/// 선택된 날짜의 이벤트 Provider (파생)
final eventsForDayProvider = Provider<List<CalendarEvent>>((ref) {
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final eventsAsync = ref.watch(eventsForMonthProvider);

  return eventsAsync.whenData((events) {
    return events.where((e) {
      final sameDay = e.startDate.year == selectedDate.year &&
          e.startDate.month == selectedDate.month &&
          e.startDate.day == selectedDate.day;
      // 범위 일정은 해당 날짜가 범위 내에 있으면 표시
      if (e.endDate != null) {
        return !selectedDate.isBefore(e.startDate) &&
            !selectedDate.isAfter(e.endDate!);
      }
      return sameDay;
    }).toList()
      ..sort((a, b) {
        final aTime = (a.startHour ?? 24) * 60 + (a.startMinute ?? 0);
        final bTime = (b.startHour ?? 24) * 60 + (b.startMinute ?? 0);
        return aTime.compareTo(bTime);
      });
  }).valueOrNull ??
      const [];
});

/// 날짜별 이벤트 맵 (월간 뷰의 dot 표시용)
final eventsByDateMapProvider = Provider<Map<String, bool>>((ref) {
  final eventsAsync = ref.watch(eventsForMonthProvider);
  return eventsAsync.whenData((events) {
    final map = <String, bool>{};
    for (final event in events) {
      final key =
          '${event.startDate.year}-${event.startDate.month}-${event.startDate.day}';
      map[key] = true;
    }
    return map;
  }).valueOrNull ??
      const {};
});

/// 선택된 날짜의 루틴 Provider (FutureProvider)
/// RoutineRepository는 이미 Hive 기반이므로 HiveCacheService를 주입한다.
/// 로컬 퍼스트: 인증 상태와 무관하게 항상 로컬 Hive에서 조회한다.
final routinesForDayProvider = FutureProvider<List<RoutineEntry>>((ref) async {
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  // weekday: 1=월 ~ 7=일
  final weekday = selectedDate.weekday;

  // RoutineRepository는 이미 Hive 기반이므로 HiveCacheService를 주입한다
  final cache = ref.watch(hiveCacheServiceProvider);
  final routineRepo = RoutineRepository(cache: cache);

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
