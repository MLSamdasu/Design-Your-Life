// 일간 캘린더 파생 Providers
// 선택된 날짜의 이벤트, 루틴, 습관, 타이머 세션을 제공한다
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/data_store_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/event.dart';
import '../../../shared/models/habit.dart';
import '../../../shared/models/habit_log.dart';
import '../../timer/models/timer_log.dart';
import '../../habit/providers/routine_provider.dart';
import 'event_models.dart';
import 'event_month_provider.dart';
import 'calendar_provider.dart';

/// 선택된 날짜의 이벤트 Provider (파생)
final eventsForDayProvider = Provider<List<CalendarEvent>>((ref) {
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final events = ref.watch(eventsForMonthProvider);

  return events.where((e) {
    final eventDay = DateTime(
        e.startDate.year, e.startDate.month, e.startDate.day);
    final selected = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day);
    final sameDay = eventDay == selected;
    // 범위 일정은 해당 날짜가 범위 내에 있으면 표시
    if (e.endDate != null) {
      final endDay = DateTime(
          e.endDate!.year, e.endDate!.month, e.endDate!.day);
      return !selected.isBefore(eventDay) &&
          !selected.isAfter(endDay);
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
final eventsByDateMapProvider = Provider<Map<String, bool>>((ref) {
  final events = ref.watch(eventsForMonthProvider);
  final map = <String, bool>{};
  for (final event in events) {
    final startDay = DateTime(
      event.startDate.year,
      event.startDate.month,
      event.startDate.day,
    );
    map[AppDateUtils.toDateString(startDay)] = true;

    if (event.endDate != null) {
      final endDay = DateTime(
        event.endDate!.year,
        event.endDate!.month,
        event.endDate!.day,
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

/// 선택된 날짜의 루틴 Provider (동기)
final routinesForDayProvider = Provider<List<RoutineEntry>>((ref) {
  ref.watch(allRoutinesRawProvider);
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final weekday = selectedDate.weekday;
  final routineRepo = ref.watch(routineRepositoryProvider);
  final routines = routineRepo.getActiveRoutines();

  final filtered = routines
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
      .toList();

  filtered.sort((a, b) {
    final aTime = a.startHour * 60 + a.startMinute;
    final bTime = b.startHour * 60 + b.startMinute;
    return aTime.compareTo(bTime);
  });

  return filtered;
});

/// 일간 뷰용 습관 데이터: 선택된 날짜에 예정된 습관과 완료 상태
final habitsForDayProvider =
    Provider<List<({Habit habit, bool isCompleted})>>((ref) {
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final allHabitsRaw = ref.watch(allHabitsRawProvider);
  final allHabitLogsRaw = ref.watch(allHabitLogsRawProvider);

  final activeHabits = allHabitsRaw
      .map((m) => Habit.fromMap(m))
      .where((h) => h.isActive && h.isScheduledFor(selectedDate))
      .toList();

  if (activeHabits.isEmpty) return const [];

  final dateStr = AppDateUtils.toDateString(selectedDate);
  final completedHabitIds = <String>{};
  for (final logMap in allHabitLogsRaw) {
    final log = HabitLog.fromMap(logMap);
    if (log.isCompleted &&
        AppDateUtils.toDateString(log.date) == dateStr) {
      completedHabitIds.add(log.habitId);
    }
  }

  return activeHabits
      .map((h) =>
          (habit: h, isCompleted: completedHabitIds.contains(h.id)))
      .toList();
});

/// 일간 뷰 타임라인용 타이머 세션 Provider
/// focus 타입의 TimerLog를 CalendarEvent으로 변환한다
final timerLogsForCalendarDayProvider =
    Provider<List<CalendarEvent>>((ref) {
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final allTimerLogsRaw = ref.watch(allTimerLogsRawProvider);

  final dateStr = AppDateUtils.toDateString(selectedDate);
  final events = <CalendarEvent>[];

  for (final logMap in allTimerLogsRaw) {
    final log = TimerLog.fromMap(logMap);
    if (log.type != TimerSessionType.focus) continue;
    if (AppDateUtils.toDateString(log.startTime) != dateStr) continue;

    final durationMinutes = log.durationSeconds ~/ 60;
    final endTotalMinutes =
        log.startTime.hour * 60 + log.startTime.minute + durationMinutes;
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
      colorIndex: 3,
      type: EventType.normal.name,
      source: 'timer',
    ));
  }

  events.sort((a, b) {
    final aMin = (a.startHour ?? 0) * 60 + (a.startMinute ?? 0);
    final bMin = (b.startHour ?? 0) * 60 + (b.startMinute ?? 0);
    return aMin.compareTo(bMin);
  });

  return events;
});
