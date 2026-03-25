// F3: 캘린더 이벤트 → 타임라인 통합 Provider
// 앱 로컬 이벤트와 Google Calendar 이벤트를 Todo 형태로 변환하여
// 타임라인 레이아웃에 통합 표시한다.
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../shared/models/event.dart' show Event, EventType;
import '../../../shared/models/todo.dart';
import '../../calendar/sync/calendar_sync_provider.dart';
import 'todo_state_providers.dart';

// ─── 캘린더 이벤트 → 타임라인 통합 Provider ─────────────────────────────────

/// 투두 탭의 선택된 날짜에 해당하는 캘린더 이벤트를 Todo 형태로 변환한다
/// 앱 이벤트 + Google Calendar 이벤트를 모두 포함한다
/// 종일 이벤트와 투두 소스('todo' 타입)는 제외하여 중복을 방지한다
/// id 접두사 'cal_'로 캘린더 출처 항목을 구별한다
final calendarEventsForTimelineProvider = Provider<List<Todo>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  // 단일 진실 원천(SSOT): allEventsRawProvider에서 직접 파생하여 Hive 이중 읽기를 제거한다
  final allEventsRaw = ref.watch(allEventsRawProvider);

  final target = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
  );

  // ── 1. 앱 로컬 이벤트 (allEventsRawProvider에서 인메모리 필터링) ─────────
  final events = allEventsRaw.map((m) => Event.fromMap(m)).toList();

  // 선택된 날짜에 해당하는 이벤트만 필터링한다
  final dayEvents = events.where((event) {
    final eventDay = DateTime(
      event.startDate.year,
      event.startDate.month,
      event.startDate.day,
    );

    // 범위 이벤트: 시작~종료 범위 내 날짜 포함
    if (event.endDate != null) {
      final endDay = DateTime(
        event.endDate!.year,
        event.endDate!.month,
        event.endDate!.day,
      );
      return !target.isBefore(eventDay) && !target.isAfter(endDay);
    }
    return eventDay == target;
  }).where((event) {
    if (event.allDay) return false;
    if (event.eventType == EventType.todo) return false;
    final hour = event.startDate.hour;
    final minute = event.startDate.minute;
    if (hour == 0 && minute == 0 && event.endDate == null) return false;
    return true;
  });

  // Event → Todo 변환 (타임라인 레이아웃 호환)
  final appTodos = dayEvents.map((event) {
    return Todo(
      id: 'cal_${event.id}',
      title: event.title,
      date: selectedDate,
      startTime: TimeOfDay(
        hour: event.startDate.hour,
        minute: event.startDate.minute,
      ),
      endTime: event.endDate != null
          ? TimeOfDay(
              hour: event.endDate!.hour,
              minute: event.endDate!.minute,
            )
          : null,
      isCompleted: false,
      color: event.colorIndex.toString(),
      memo: event.memo,
      createdAt: event.createdAt,
    );
  }).toList();

  // ── 2. Google Calendar 이벤트 ─────────────────────────────────────────────
  // googleCalendarEventsProvider를 watch하여 Google 이벤트도 타임라인에 통합한다
  final googleEventsAsync = ref.watch(googleCalendarEventsProvider);
  final googleEvents = googleEventsAsync.valueOrNull ?? const [];

  // 선택된 날짜에 해당하는 Google 이벤트만 필터링한다
  final googleTodos = googleEvents.where((e) {
    final eventDay = DateTime(e.startDate.year, e.startDate.month, e.startDate.day);
    // 범위 이벤트: 선택된 날짜가 시작~종료 범위 내에 있으면 포함한다
    if (e.endDate != null) {
      final endDay = DateTime(e.endDate!.year, e.endDate!.month, e.endDate!.day);
      return !target.isBefore(eventDay) && !target.isAfter(endDay);
    }
    return eventDay == target;
  }).where((e) {
    // 종일 이벤트는 타임라인에 표시하지 않는다
    if (e.isAllDay) return false;
    // 시간이 없는 이벤트도 제외한다
    if (e.startHour == null && e.startMinute == null) return false;
    return true;
  }).map((e) {
    return Todo(
      id: 'gcal_${e.id}',
      title: e.title,
      date: selectedDate,
      startTime: TimeOfDay(
        hour: e.startHour ?? 0,
        minute: e.startMinute ?? 0,
      ),
      endTime: (e.endHour != null)
          ? TimeOfDay(hour: e.endHour!, minute: e.endMinute ?? 0)
          : null,
      isCompleted: false,
      color: e.colorIndex.toString(),
      memo: e.memo,
      createdAt: e.startDate,
    );
  }).toList();

  // 앱 이벤트 + Google 이벤트를 병합하여 반환한다
  return [...appTodos, ...googleTodos];
});
